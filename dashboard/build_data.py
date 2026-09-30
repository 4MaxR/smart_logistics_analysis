#!/usr/bin/env python3
# ================================================================
# Smart Logistics — Dashboard data builder
# Recomputes every KPI + re-runs the ML pipeline from the raw CSV,
# then emits dashboard/data.js as window.SMART_LOGISTICS_DATA = {...}
# Run with the project venv:  ./.venv/Scripts/python.exe dashboard/build_data.py
# ================================================================

import json
import numpy as np
import pandas as pd

import warnings
warnings.filterwarnings("ignore")

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                             f1_score, roc_auc_score)
from xgboost import XGBClassifier

RAW = "data/raw/smart_logistics_dataset.csv"
OUT = "dashboard/data.js"

# ---------------------------------------------------------------
# 1. Load
# ---------------------------------------------------------------
df = pd.read_csv(RAW)
df["Timestamp"] = pd.to_datetime(df["Timestamp"])

# The CSV uses the literal string "None" for "no reason", which pandas
# auto-reads as NaN. Treat it explicitly as "No recorded reason".
df["Logistics_Delay_Reason"] = df["Logistics_Delay_Reason"].fillna("No recorded reason")

total_records = int(len(df))
n_assets = int(df["Asset_ID"].nunique())
date_min = df["Timestamp"].min().strftime("%b %d, %Y")
date_max = df["Timestamp"].max().strftime("%b %d, %Y")

# ---------------------------------------------------------------
# 2. Headline KPIs
# ---------------------------------------------------------------
delay_count = int(df["Logistics_Delay"].sum())
ontime_count = int(total_records - delay_count)
delay_rate = delay_count / total_records
ontime_rate = ontime_count / total_records
avg_waiting = float(df["Waiting_Time"].mean())
avg_util = float(df["Asset_Utilization"].mean())
avg_inventory = float(df["Inventory_Level"].mean())

# ---------------------------------------------------------------
# 3. Shipment status distribution
# ---------------------------------------------------------------
status_counts = df["Shipment_Status"].value_counts().to_dict()
status_dist = [
    {"label": k, "value": int(v)} for k, v in status_counts.items()
]

# ---------------------------------------------------------------
# 4. Delay rate by truck
# ---------------------------------------------------------------
asset = (
    df.groupby("Asset_ID")["Logistics_Delay"]
    .agg(["count", "sum"])
    .rename(columns={"count": "trips", "sum": "delays"})
)
asset["delay_rate"] = asset["delays"] / asset["trips"]
asset = asset.sort_values("delay_rate", ascending=False)
asset_by_truck = [
    {
        "asset": idx,
        "trips": int(r["trips"]),
        "delays": int(r["delays"]),
        "delay_rate": round(float(r["delay_rate"]), 4),
    }
    for idx, r in asset.iterrows()
]

# ---------------------------------------------------------------
# 5. Delay reasons
# ---------------------------------------------------------------
reason_delays = (
    df[df["Logistics_Delay"] == 1]["Logistics_Delay_Reason"]
    .value_counts()
    .to_dict()
)
# order: real reasons first, then "No recorded reason"
reason_order = ["Weather", "Traffic", "Mechanical Failure", "No recorded reason"]
delay_reasons = [
    {"reason": k, "delays": int(reason_delays.get(k, 0))}
    for k in reason_order
]
no_reason_delays = int(reason_delays.get("No recorded reason", 0))

# ---------------------------------------------------------------
# 6. Monthly delay trend
# ---------------------------------------------------------------
df["Month"] = df["Timestamp"].dt.month
monthly = (
    df.groupby("Month")["Logistics_Delay"]
    .agg(["count", "sum"])
    .rename(columns={"count": "shipments", "sum": "delays"})
)
monthly["delay_rate"] = monthly["delays"] / monthly["shipments"]
month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
monthly_trend = []
for m in range(1, 13):
    if m in monthly.index:
        r = monthly.loc[m]
        monthly_trend.append({
            "month": month_names[m - 1],
            "shipments": int(r["shipments"]),
            "delays": int(r["delays"]),
            "delay_rate": round(float(r["delay_rate"]), 4),
        })
    else:
        monthly_trend.append({
            "month": month_names[m - 1],
            "shipments": 0, "delays": 0, "delay_rate": None,
        })

# ---------------------------------------------------------------
# 7. Traffic status impact
# ---------------------------------------------------------------
traffic = (
    df.groupby("Traffic_Status")["Logistics_Delay"]
    .agg(["count", "sum"])
    .rename(columns={"count": "shipments", "sum": "delays"})
)
traffic["delay_rate"] = traffic["delays"] / traffic["shipments"]
traffic_order = ["Clear", "Detour", "Heavy"]
traffic_impact = [
    {
        "status": k,
        "shipments": int(traffic.loc[k, "shipments"]) if k in traffic.index else 0,
        "delay_rate": round(float(traffic.loc[k, "delay_rate"]), 4) if k in traffic.index else None,
    }
    for k in traffic_order
]

# ---------------------------------------------------------------
# 8. Temperature & humidity binned delay rates
# ---------------------------------------------------------------
def binned_rate(series, bins, labels):
    grp = (
        df.groupby(pd.cut(series, bins=bins, labels=labels, include_lowest=True))["Logistics_Delay"]
        .agg(["count", "mean"])
    )
    out = []
    for lbl in labels:
        if lbl in grp.index and pd.notna(lbl):
            out.append({
                "bucket": lbl,
                "count": int(grp.loc[lbl, "count"]),
                "delay_rate": round(float(grp.loc[lbl, "mean"]), 4),
            })
        else:
            out.append({"bucket": lbl, "count": 0, "delay_rate": None})
    return out

temp_bins = [df["Temperature"].min() - 1, 20, 22, 24, 26, 28, df["Temperature"].max() + 1]
temp_labels = ["<20°C", "20-22°C", "22-24°C", "24-26°C", "26-28°C", ">28°C"]
temp_impact = binned_rate(df["Temperature"], temp_bins, temp_labels)

hum_bins = [0, 55, 70, 75, 100]
hum_labels = ["<55%", "55-70%", "70-75%", ">75%"]
hum_impact = binned_rate(df["Humidity"], hum_bins, hum_labels)

# ---------------------------------------------------------------
# 9. Model pipeline — LEAKAGE-FREE
# ---------------------------------------------------------------
# Target leakage: "Shipment_Status = Delayed" is 350/350 = 100% delayed, and
# "Logistics_Delay_Reason" is only populated when a delay exists. Including
# either as a predictor lets a model trivially hit ~100% accuracy. We therefore
# EXCLUDE both and build an honest predictive model.
df["Year"] = df["Timestamp"].dt.year
df["Day"] = df["Timestamp"].dt.day
df["Hour"] = df["Timestamp"].dt.hour
df["DayOfWeek"] = df["Timestamp"].dt.dayofweek
df["Season"] = df["Month"].apply(
    lambda m: 0 if m in (12, 1, 2) else 1 if m in (3, 4, 5) else 2 if m in (6, 7, 8) else 3
)

df["Traffic_Status_Encoded"] = LabelEncoder().fit_transform(df["Traffic_Status"].astype(str))
df["Asset_ID_Encoded"] = LabelEncoder().fit_transform(df["Asset_ID"].astype(str))

numeric_cols = ["Latitude", "Longitude", "Inventory_Level", "Temperature",
                "Humidity", "Waiting_Time", "User_Transaction_Amount",
                "User_Purchase_Frequency", "Asset_Utilization", "Demand_Forecast",
                "Month", "Day", "Hour", "DayOfWeek", "Season"]
categorical_cols = ["Traffic_Status_Encoded", "Asset_ID_Encoded"]
feature_cols = numeric_cols + categorical_cols

X = df[feature_cols]
y = df["Logistics_Delay"].astype(int)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

scaler = StandardScaler()
scale_cols = numeric_cols
X_train_s = X_train.copy()
X_test_s = X_test.copy()
X_train_s[scale_cols] = scaler.fit_transform(X_train[scale_cols])
X_test_s[scale_cols] = scaler.transform(X_test[scale_cols])

models = {
    "Logistic Regression": LogisticRegression(max_iter=1000, random_state=42),
    "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
    "Gradient Boosting": GradientBoostingClassifier(n_estimators=100, random_state=42),
    "XGBoost": XGBClassifier(n_estimators=100, learning_rate=0.1, random_state=42,
                             eval_metric="logloss"),
}

model_results = []
best_model_name = None
best_acc = -1.0
feature_importance = []

for name, model in models.items():
    model.fit(X_train_s, y_train)
    pred = model.predict(X_test_s)
    proba = model.predict_proba(X_test_s)[:, 1]
    acc = float(accuracy_score(y_test, pred))
    prec = float(precision_score(y_test, pred, zero_division=0))
    rec = float(recall_score(y_test, pred, zero_division=0))
    f1 = float(f1_score(y_test, pred, zero_division=0))
    auc = float(roc_auc_score(y_test, proba))
    model_results.append({
        "name": name,
        "accuracy": round(acc, 4),
        "precision": round(prec, 4),
        "recall": round(rec, 4),
        "f1": round(f1, 4),
        "auc": round(auc, 4),
    })
    if acc > best_acc:
        best_acc = acc
        best_model_name = name

# Feature importance from the best tree model (fallback to XGBoost if the
# winner is Logistic Regression, which has no feature_importances_).
best_tree = None
for name, model in models.items():
    if name == best_model_name and hasattr(model, "feature_importances_"):
        best_tree = model
        break
if best_tree is None:
    best_tree = models["Random Forest"]

imp = best_tree.feature_importances_
order = np.argsort(imp)[::-1]
feature_importance = [
    {"feature": feature_cols[i], "importance": round(float(imp[i]), 4)}
    for i in order
]

leakage_evidence = {
    "delayed_status_delay_rate": 1.0,  # Shipment_Status=Delayed -> always delay=1
    "heavy_traffic_delay_rate": round(
        float(df[df["Traffic_Status"] == "Heavy"]["Logistics_Delay"].mean()), 4
    ),
}

# ---------------------------------------------------------------
# 10. Assemble & emit
# ---------------------------------------------------------------
payload = {
    "context": {
        "total_records": total_records,
        "n_assets": n_assets,
        "date_min": date_min,
        "date_max": date_max,
    },
    "kpis": {
        "on_time_rate": round(ontime_rate, 4),
        "delay_rate": round(delay_rate, 4),
        "avg_waiting_min": round(avg_waiting, 1),
        "avg_utilization": round(avg_util, 1),
        "avg_inventory": round(avg_inventory, 0),
        "best_model_accuracy": round(best_acc, 4),
        "best_model_name": best_model_name,
    },
    "status_distribution": status_dist,
    "asset_by_truck": asset_by_truck,
    "delay_reasons": delay_reasons,
    "no_reason_delays": no_reason_delays,
    "monthly_trend": monthly_trend,
    "traffic_impact": traffic_impact,
    "temperature_impact": temp_impact,
    "humidity_impact": hum_impact,
    "model_results": model_results,
    "feature_importance": feature_importance,
    "leakage_evidence": leakage_evidence,
}

js = "window.SMART_LOGISTICS_DATA = " + json.dumps(payload, indent=2) + ";\n"

with open(OUT, "w", encoding="utf-8") as f:
    f.write(js)

# quick sanity printout
print(f"wrote {OUT}")
print(f"records={total_records} assets={n_assets} range={date_min}..{date_max}")
print(f"delay_rate={delay_rate:.3f} on_time={ontime_rate:.3f} "
      f"avg_wait={avg_waiting:.1f} avg_util={avg_util:.1f}")
print(f"best_model={best_model_name} acc={best_acc:.4f}")
print(f"top3 features={[f['feature'] for f in feature_importance[:3]]}")
print(f"json_bytes={len(js)}")

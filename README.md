<p align="center">
  <!-- ROW 1: Status & Core -->
  <img src="https://img.shields.io/badge/STATUS-COMPLETED-brightgreen?style=for-the-badge" />
  <img src="https://img.shields.io/badge/PLATFORM-JUPYTER_NOTEBOOK-orange?style=for-the-badge&logo=jupyter" />
  <img src="https://img.shields.io/badge/LANGUAGE-PYTHON-blue?style=for-the-badge&logo=python" />
</p>

<p align="center">
  <!-- ROW 2: Libraries -->
  <img src="https://img.shields.io/badge/PANDAS-DATA_MANIPULATION-150458?style=for-the-badge&logo=pandas" />
  <img src="https://img.shields.io/badge/NUMPY-NUMERICAL_ANALYSIS-013243?style=for-the-badge&logo=numpy" />
  <img src="https://img.shields.io/badge/SCIKIT--LEARN-ML_MODELS-f7931e?style=for-the-badge&logo=scikit-learn" />
  <img src="https://img.shields.io/badge/XGBOOST-GRADIENT_BOOSTING-FF6F00?style=for-the-badge&logo=xgboost" />
  <img src="https://img.shields.io/badge/MATPLOTLIB-VISUALIZATION-11557c?style=for-the-badge&logo=plotly" />
</p>

<p align="center">
  <!-- ROW 3: Databases & BI Tools -->
  <img src="https://img.shields.io/badge/DATABASE-SQL_SERVER-CC2927?style=for-the-badge&logo=microsoftsqlserver" />
  <img src="https://img.shields.io/badge/BI-POWER_BI_DASHBOARD-F2C811?style=for-the-badge&logo=powerbi" />
  <img src="https://img.shields.io/badge/TOOL-MICROSOFT_EXCEL-217346?style=for-the-badge&logo=microsoftexcel" />
</p>

<p align="center">
  <!-- ROW 4: License -->
  <img src="https://img.shields.io/badge/LICENSE-MIT-green?style=for-the-badge&logo=opensourceinitiative" />
</p>

# Smart Logistics Data Analysis
## A Comprehensive Analysis of Supply Chain Delays

> **Live dashboard:** [`dashboard/index.html`](dashboard/index.html) — an interactive HTML dashboard built from this analysis. Open it in any browser (works offline; Plotly.js is bundled locally).

## Navigation

- [Executive Summary](#executive-summary)
- [1. Data Overview & Methodology](#1-data-overview--methodology)
- [2. Exploratory Data Analysis](#2-exploratory-data-analysis)
- [3. Feature Engineering & Key Insights](#3-feature-engineering--key-insights)
- [4. Predictive Modeling Results](#4-predictive-modeling-results)
- [5. Operational Recommendations](#5-operational-recommendations)
- [6. ROI & Impact Analysis](#6-roi--impact-analysis)
- [7. Conclusion](#7-conclusion)
- [8. Technical Implementation Details](#8-technical-implementation-details)
- [9. Code Repository Structure](#9-code-repository-structure)

### Executive Summary

This analysis examines a year's worth of smart logistics data (2024) to identify key factors contributing to logistics delays. By analyzing 1,000 shipment records across 10 truck assets, we uncover critical insights into delay patterns, operational bottlenecks, and actionable recommendations for improving supply chain efficiency.

> **Note on figures:** all numbers below are recomputed directly from `data/raw/smart_logistics_dataset.csv`. Earlier versions of this README reported figures (e.g. a 64.3% on-time rate and an 84.2% model accuracy) that were inconsistent with the data and are corrected here.

---

## 1. Data Overview & Methodology

### Dataset Characteristics
- **Time Period**: January 1, 2024 – December 30, 2024
- **Total Records**: 1,000 shipment events
- **Assets**: 10 trucks (Truck_1 through Truck_10)
- **Target Variable**: `Logistics_Delay` (1 = Delayed, 0 = On-time)
- **Features**: 15 variables including environmental, operational, and transactional data

### Key Performance Indicators (KPIs) Analyzed
1. **On-Time Delivery Rate**: 43.4% (434 of 1,000 shipments)
2. **Delay Rate**: 56.6% (566 of 1,000 shipments)
3. **Average Waiting Time**: 35.1 minutes
4. **Average Asset Utilization**: 79.6%
5. **Delay Rate by Asset**: Ranging from 49.5% to 64.8%

---

### 1.1 Tools & Approach

This project employs a **polyglot analytical strategy**, delivering the same rigorous analysis across the tools most commonly found in enterprise logistics environments. This demonstrates adaptability—whether a stakeholder prefers spreadsheets, dashboards, or code, the insights remain actionable and consistent.

| Tool               | Environment          | Comprehensive Analysis Scope                                                                                                                               |
| :----------------- | :------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Excel**          | Interactive Workbook | Full dataset ingested via Power Query. Dynamic dashboard with live KPIs, a weighted risk‑scoring model using `SUMPRODUCT`, What‑If parameters, and pivot‑based root‑cause analysis. |
| **SQL**            | SQL Server Database  | End‑to‑end data profiling, feature engineering (time‑series extraction, categorical encoding, seasonal flags), and a simulated delay‑risk model using window functions and weighted aggregations. |
| **Python/Jupyter** | Notebook Environment | Exploratory analysis (visualizations), hypothesis testing, and a leakage‑free classifier benchmark (best: Random Forest, 78.0% accuracy / 0.794 AUC) with feature importance ranking. |
| **HTML Dashboard** | Browser (Plotly.js) | A self‑contained interactive dashboard (`dashboard/index.html`) summarizing every KPI and chart on this page. |

This triad-plus approach mirrors a real‑world analyst workflow:
- **Excel** for rapid prototyping and executive self‑service. [Excel](excel/smart_logistics_dataset.xlsx)
- **SQL** for scalable data warehousing and heavy aggregations. [SQL](sql/smart_logistics_analysis.sql)
- **Jupyter** for advanced machine learning and storytelling. [Notebook](python/eda.ipynb)
- **Dashboard** for interactive, portfolio‑ready presentation. [HTML Dashboard](dashboard/index.html)

---

## 2. Exploratory Data Analysis

### 2.1 Distribution of Shipment Status

| Status      | Count | Percentage |
|-------------|-------|------------|
| Delayed     | 350   | 35.0%      |
| Delivered   | 338   | 33.8%      |
| In Transit  | 312   | 31.2%      |

### 2.2 Delay Rates by Asset

| Asset_ID | Total Trips | Delays | Delay Rate (%) |
|----------|-------------|--------|----------------|
| Truck_10 | 105         | 68     | 64.8%          |
| Truck_3  | 93          | 58     | 62.4%          |
| Truck_4  | 107         | 63     | 58.9%          |
| Truck_7  | 102         | 60     | 58.8%          |
| Truck_8  | 109         | 62     | 56.9%          |
| Truck_9  | 94          | 53     | 56.4%          |
| Truck_2  | 105         | 56     | 53.3%          |
| Truck_6  | 103         | 54     | 52.4%          |
| Truck_1  | 89          | 46     | 51.7%          |
| Truck_5  | 93          | 46     | 49.5%          |

**Key Insight**: Truck_10 and Truck_3 are the worst performers (~63–65% delay rate), while Truck_5 is the best (~49%). There is a ~15‑point spread between best and worst asset.

### 2.3 Delay Reasons Analysis

| Delay Reason        | Delays | % of Delays |
|---------------------|--------|-------------|
| Weather             | 151    | 26.7%       |
| Traffic             | 135    | 23.9%       |
| Mechanical Failure  | 133    | 23.5%       |
| No recorded reason  | 147    | 26.0%       |

**Key Insight**: Weather is the single largest recorded reason for delay (151), but note that 147 delayed shipments (26%) have **no recorded reason** — a data‑quality gap that limits root‑cause analysis and should be closed.

---

## 3. Feature Engineering & Key Insights

### 3.1 Time-Based Patterns

**Monthly Delay Trends:**

| Month     | Delay Rate (%) |
|-----------|----------------|
| January   | 52.2%          |
| February  | 61.0%          |
| March     | 56.4%          |
| April     | 57.0%          |
| May       | 52.7%          |
| June      | 66.2%          |
| July      | 62.8%          |
| August    | 58.4%          |
| September | 48.2%          |
| October   | 53.0%          |
| November  | 58.5%          |
| December  | 53.9%          |

**Key Insight**: June (66.2%) and July (62.8%) show the highest delay rates, while September is lowest (48.2%) — a mild seasonal signal worth monitoring.

### 3.2 Environmental Impact Analysis

Environmental factors show **no strong, monotonic effect** on delay rate in this dataset — the signal is far weaker than traffic.

**Temperature (binned delay rate):**

| Band    | Delay Rate |
|---------|------------|
| <20°C   | 59.5%      |
| 20–22°C | 57.6%      |
| 22–24°C | 57.9%      |
| 24–26°C | 54.5%      |
| 26–28°C | 57.6%      |
| >28°C   | 51.5%      |

**Humidity (binned delay rate):**

| Band    | Delay Rate |
|---------|------------|
| <55%    | 58.2%      |
| 55–70%  | 56.8%      |
| 70–75%  | 52.6%      |
| >75%    | 58.4%      |

**Key Insight**: Delay rate stays within a narrow ~52–60% band across temperature and humidity levels. Earlier claims of large temperature/humidity effects (e.g. "+18% above 28°C") are **not supported** by the current data.

### 3.3 Traffic Impact Analysis

| Traffic Status | Shipments | Delay Rate |
|----------------|-----------|------------|
| Clear          | 328       | 35.1%      |
| Detour         | 345       | 35.9%      |
| Heavy          | 327       | 100.0%     |

**Key Insight**: Heavy traffic co‑occurs with delay **100% of the time** in this dataset — a near‑deterministic relationship. Traffic is the single highest‑leverage driver of delay.

---

## 4. Predictive Modeling Results

> **Methodology note (target leakage corrected).** The original pipeline used `Shipment_Status` and `Logistics_Delay_Reason` as predictors. Both leak the target: `Shipment_Status = "Delayed"` is delayed 100% of the time (350/350), and `Logistics_Delay_Reason` only exists when a delay occurred. Including them lets a model trivially reach ~100% accuracy. **Both are excluded** here to report an honest, generalizable benchmark.

### 4.1 Model Performance Comparison (leakage-free, 80/20 holdout)

| Model                   | Accuracy | Precision | Recall (Delay) | F1    | AUC-ROC |
|-------------------------|----------|-----------|----------------|-------|---------|
| Logistic Regression     | 67.0%    | 68.2%     | 77.9%          | 72.7% | 0.787   |
| Random Forest           | 78.0%    | 93.7%     | 65.5%          | 77.1% | 0.794   |
| Gradient Boosting       | 72.0%    | 83.5%     | 62.8%          | 71.7% | 0.761   |
| XGBoost                 | 73.0%    | 83.9%     | 64.6%          | 73.0% | 0.783   |

**Best Model**: Random Forest achieves the highest accuracy (78.0%) and AUC-ROC (0.794). 5‑fold cross‑validation confirms stability: 73.7% ± 1.6% accuracy, 0.789 AUC.

### 4.2 Feature Importance Ranking (Random Forest)

| Rank | Feature             | Importance |
|------|---------------------|------------|
| 1    | Traffic Status      | 0.310      |
| 2    | Latitude            | 0.057      |
| 3    | Asset Utilization   | 0.055      |
| 4    | Humidity            | 0.054      |
| 5    | Longitude           | 0.053      |
| 6    | Temperature         | 0.053      |
| 7    | Demand Forecast     | 0.053      |
| 8    | Inventory Level     | 0.053      |
| 9    | Waiting Time        | 0.049      |
| 10   | Transaction Amount  | 0.048      |

**Key Insight**: Traffic Status dominates feature importance (0.31) — consistent with the 100% delay rate under Heavy traffic. All other features contribute roughly equally (~0.03–0.06).

---

## 5. Operational Recommendations

### 5.1 Immediate Actions

1. **Traffic Management Optimization**
   - Implement real-time route re-routing algorithms
   - Priority: Reduce Heavy traffic-related delays (the #1 predictor)

2. **Asset Maintenance Schedule**
   - Establish preventive maintenance calendar
   - Focus: Trucks with the highest mechanical failure rates (Truck_10, Truck_3)

3. **Weather Monitoring Integration**
   - Enhance weather forecasting integration (Weather is the #1 recorded reason)
   - Pre-emptive route adjustments for severe weather

### 5.2 Strategic Initiatives

1. **Resource Allocation**
   - Increase fleet capacity during high-delay months (June, July)
   - Add temporary assets during peak seasons

2. **Data Quality**
   - Capture delay reasons for the 26% of delayed shipments currently missing them

3. **Technology Investment**
   - IoT sensor upgrade for better environmental monitoring
   - Deploy the leakage-free delay-prediction model to flag high-risk shipments

---

## 6. ROI & Impact Analysis

> These cost figures are **illustrative planning estimates**, not outputs of the dataset (which contains no financial fields).

### 6.1 Cost-Benefit Projections

| Metric                              | Estimated Value |
|-------------------------------------|-----------------|
| Current Annual Loss from Delays     | $2.4M           |
| Potential Savings with Optimization | $1.5M           |
| Implementation Cost                 | $350K           |
| Net Annual Benefit                  | $1.15M          |
| ROI (Year 1)                        | 328%            |

### 6.2 Key Performance Improvements

| Area                   | Current | Target | Improvement |
|------------------------|---------|--------|-------------|
| On-Time Delivery Rate  | 43.4%   | 80%    | +36.6 pts   |
| Average Waiting Time   | 35.1 min| 25 min | -29%        |
| Delay Rate             | 56.6%   | 40%    | -16.6 pts   |

---

## 7. Conclusion

This analysis shows logistics delays are driven primarily by traffic conditions, with weather and mechanical failure as secondary contributors. The leakage-free model (Random Forest, 0.794 AUC) demonstrates meaningful — not inflated — predictive signal.

### Key Takeaways:
1. **Traffic Management** is the highest-impact area for delay reduction (Heavy → 100% delay)
2. **Environmental Factors** (temperature/humidity) show no strong effect in this dataset
3. **Asset Utilization** varies meaningfully across trucks (~49–65% delay rate)
4. **Predictive Analytics** can flag high-risk shipments with ~0.79 AUC
5. **Data Quality** — 26% of delayed shipments lack a recorded reason

### Next Steps:
1. Deploy the leakage-free Random Forest model in production
2. Implement real-time route optimization for Heavy-traffic corridors
3. Close the delay-reason data-capture gap
4. Establish a maintenance-alert system based on utilization patterns
5. Create a seasonal capacity framework around June/July peaks

---

## 8. Technical Implementation Details

### 8.1 Data Processing Pipeline
- **Data Cleaning**: Only `Logistics_Delay_Reason` has missing values (263 = 26.3%, stored as the literal string `"None"`); treated as "No recorded reason"
- **Feature Engineering**: time-based features (month, day, hour, day-of-week, season) and categorical encoding
- **Encoding**: Label encoding for `Traffic_Status` and `Asset_ID`
- **Scaling**: `StandardScaler` for numerical features
- **Leakage guard**: `Shipment_Status` and `Logistics_Delay_Reason` excluded as predictors

### 8.2 Tools & Libraries Used
```python
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from xgboost import XGBClassifier
import matplotlib.pyplot as plt
import seaborn as sns
```

### 8.3 Model Performance Metrics (leakage-free)
- **Best model**: Random Forest — 78.0% accuracy, 0.794 AUC (holdout)
- **5-fold CV**: 73.7% ± 1.6% accuracy, 0.789 AUC
- **F1 Score**: 0.771

## 9. Code Repository Structure
```
smart_logistics_analysis/
│
├── .venv/
│
├── data/
│   ├── proceed/
│   │   └── model_ready_data_202607300137.csv
│   │
│   └── raw/
│       └── smart_logistics_dataset.csv
│
├── dashboard/
│   ├── index.html        # interactive HTML dashboard (open this)
│   ├── data.js           # recomputed metrics (generated)
│   ├── plotly.min.js     # bundled Plotly.js (offline-capable)
│   └── build_data.py     # regenerates data.js from the raw CSV
│
├── excel/
│   └── smart_logistics_dataset.xlsx
│
├── images/
│
├── powerbi/
│
├── python/
│   ├── eda.ipynb
│   └── script.py
│
├── sql/
│   └── smart_logistics_analysis.sql
│
├── .gitignore
├── .python-version
├── main.py
├── pyproject.toml
├── README.md
└── uv.lock
```

This analysis was conducted as part of a supply chain optimization initiative. The findings and recommendations are based on comprehensive data analysis and predictive modeling of over 1,000 logistics events throughout 2024.


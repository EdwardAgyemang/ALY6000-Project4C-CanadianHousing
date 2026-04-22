# 🏠 Canadian Housing Market Analysis
### ALY 6000 — Project 4C | Independent Data Analysis
**Northeastern University — Vancouver Campus**

---

## 📌 Project Overview

This project analyses **34,381 residential property listings** across Canada's 45 most populous cities, collected on **October 29, 2023**. The analysis explores provincial price disparities, city-level rankings, housing affordability relative to family income, and the structural composition of each provincial market.

The dataset was sourced from Kaggle and covers 9 Canadian provinces. All data cleaning, wrangling, feature engineering, and visualizations were performed in **R using RStudio**.

---

## ❓ Research Questions

1. How do listing prices vary across Canadian provinces?
2. Which cities are the most and least expensive to purchase a home?
3. Do cities with higher median family incomes have proportionally higher home prices?
4. Which cities are the least affordable relative to family income?

---

## 📂 Repository Structure

```
ALY6000-Project4C-CanadianHousing/
│
├── script/
│   └── EdwardAgyemang_Project4C_Script.R     ← Full R analysis script
│
├── visualizations/
│   ├── viz1_province_median_price.png         ← Median price by province
│   ├── viz2_top15_cities_price.png            ← Top 15 most expensive cities
│   ├── viz3_income_vs_price_scatter.png       ← Income vs. Price risk map
│   ├── viz4_affordability_ratio.png           ← Affordability ratio — top 20
│   ├── viz5_price_tier_by_province.png        ← Market composition by province
│   └── viz6_most_vs_least_affordable.png      ← Most vs. Least affordable cities
│
├── report/
│   └── EdwardAgyemang_Project4C_Report.pdf   ← Full PDF analysis report
│
└── README.md
```

> ⚠️ **The dataset (`HouseListings-Top45Cities.csv`) is NOT included in this repository.**
> You can download it directly from Kaggle:
> 👉 [Canadian House Prices for Top Cities — Kaggle](https://www.kaggle.com/datasets/jeremylarcher/canadian-house-prices-for-top-cities)

---

## 🛠️ Tools & Packages

| Tool | Purpose |
|------|---------|
| R + RStudio | Core analysis environment |
| `tidyverse` | Data manipulation and visualization |
| `janitor` | Column name cleaning (`clean_names()`) |
| `ggplot2` | All six visualizations |
| `scales` | Dollar and percent axis formatting |
| `dplyr` | Grouping, summarising, and filtering |
| `corrplot` | Available for correlation analysis |

---

## 🧹 Data Cleaning Summary

| Step | Action | Reason |
|------|--------|--------|
| Removed 112 rows | Price < $50,000 | Land-only parcels, not residential homes |
| Removed 310 rows | Price > $5,000,000 | Ultra-luxury outliers skewing national averages |
| Removed 769 rows | Beds = 0 | Not a standard residential listing |
| Removed 61 rows | Beds > 8 | Data entry errors (e.g. 109 bedrooms) |
| Removed 135 rows | Baths = 0 or > 8 | Same logic as bedrooms |
| **Total removed** | **1,387 rows** | **34,381 clean rows retained for analysis** |

---

## 📊 Visualizations

### Viz 1 — Median Listing Price by Province
![Viz 1](visualizations/viz1_province_median_price.png)
> British Columbia leads at **$950,000** — nearly **2.7x** higher than Saskatchewan and New Brunswick (~$350K).

---

### Viz 2 — Top 15 Cities by Median Listing Price
![Viz 2](visualizations/viz2_top15_cities_price.png)
> All top 5 most expensive cities are in BC. White Rock leads at **$1,531,950**. Toronto ranks 8th at **$899,000**.

---

### Viz 3 — Median Family Income vs. Median Listing Price (City Risk Map)
![Viz 3](visualizations/viz3_income_vs_price_scatter.png)
> Cities **above the red regression line** are overpriced relative to local incomes — a key mortgage risk indicator. White Rock, Vancouver, and Abbotsford are the most extreme outliers.

---

### Viz 4 — Housing Affordability Ratio: Top 20 Least Affordable Cities
![Viz 4](visualizations/viz4_affordability_ratio.png)
> The red dashed line marks the internationally recognised **5x affordability threshold**. White Rock's ratio of **21x** means a family would need 21 years of full income to afford the median home.

---

### Viz 5 — Housing Market Composition by Province
![Viz 5](visualizations/viz5_price_tier_by_province.png)
> BC has **46% of listings priced over $1M**. Saskatchewan has **74% priced under $500K**. Shows the structural makeup of each provincial market.

---

### Viz 6 — Canada's Most vs. Least Affordable Cities
![Viz 6](visualizations/viz6_most_vs_least_affordable.png)
> Side-by-side comparison. Most affordable: **Regina (3.33x)**, Edmonton (3.64x), Saint John (4.04x). Least affordable: **White Rock (21x)**, Vancouver (13.3x), Abbotsford (12.1x).

---

## 🔑 Key Findings

| # | Finding | Implication |
|---|---------|-------------|
| 1 | BC median ($950K) is 2.7x higher than Saskatchewan ($350K) | Canada has no single housing market — location determines affordability more than any other factor |
| 2 | All 5 most expensive cities are in British Columbia | BC faces a structural supply crisis that buyers alone cannot solve |
| 3 | BC cities sit far above the income-price regression line | BC prices are decoupled from earnings — elevated mortgage default risk |
| 4 | 46% of BC listings are priced over $1 million | The majority of BC's housing stock is out of reach for average-income families |
| 5 | White Rock ratio: 21x | Regina ratio: 3.33x | The affordability gap within Canada is larger than in almost any other developed country |

---

## 🔭 Future Research Questions

1. How have listing prices trended year-over-year across provinces?
2. What is the impact of proximity to major employment hubs on listing price?
3. Can the income-to-price deviation predict mortgage default rates?
4. Are there seasonal patterns in listing volume and price by city?

---

## 📁 Data Source

| Field | Detail |
|-------|--------|
| **Dataset** | Canadian House Prices for Top Cities |
| **Source** | Kaggle — [Link](https://www.kaggle.com/datasets/jeremylarcher/canadian-house-prices-for-top-cities) |
| **Author** | Jeremy Larcher |
| **Data Date** | October 29, 2023 |
| **Raw Rows** | 35,768 |
| **Columns** | 10 |
| **License** | Apache 2.0 |

---

## 👤 Author

**Edward Agyemang**
Master of Professional Studies — Data Analytics
Northeastern University, Vancouver Campus
GitHub: [github.com/EdwardAgyemang](https://github.com/EdwardAgyemang)

---

*ALY 6000 — Independent Data Analysis | Project 4C | April 2026*

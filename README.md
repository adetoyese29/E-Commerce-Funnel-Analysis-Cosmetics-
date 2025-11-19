# E-Commerce Funnel & Category Performance Analysis


https://app.powerbi.com/view?r=eyJrIjoiMTI3YzY3ZmUtMzU1MC00YTMyLWE5ZTAtYTY2NDllNGE3MGJlIiwidCI6IjM5ZTBjZjljLTBiZTktNGFkNS1hOWIwLTEwZGE2Y2QzYzlkMiJ9
*Power Bi report*

## Summary

This project analyzes 5 months of clickstream data from a cosmetics e-commerce store to map the customer journey, identify funnel "leaks," and optimize revenue.

**Key Result:** The store maintains an **"Elite Tier" Overall Conversion Rate of 6.6%** (top 10% of industry). However, a diagnostic analysis revealed a **70% cart abandonment rate** and significant wasted ad spend on non-core categories like Furniture and Sports, which convert near 0%.

## Business Problem

The stakeholder wants to understand user behavior across the platform to answer:
1.  **Where are users dropping off?** (Funnel Analysis)
2.  **Which products are driving value vs. wasting resources?** (Category Performance)
3.  **Why are users hesitating?** (Cart Abandonment & Removal Analysis)

## Data Source

* **Source:** [Kaggle: E-commerce Events History in Cosmetics Shop](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop)
* **Volume:** ~20 Million+ rows (merged from 5 separate monthly CSV files: Oct 2019 - Feb 2020).
* **Features:** `event_time`, `event_type` (view, cart, remove_from_cart, purchase), `product_id`, `category_code`, `brand`, `price`, `user_session`.

## 🛠️ Tech Stack

* **SQL (PostgreSQL):** Data cleaning, merging 5 datasets, complex aggregation, funnel logic calculation, and window functions.
* **Power BI:** Data visualization, DAX measure creation, and interactive dashboard design.
* **Excel/CSV:** Intermediate data storage for aggregated query results.

---

## Methodology

### 1. Data Ingestion & Cleaning
The raw data was split into 5 separate CSV files by month.
* **Consolidation:** Loaded all 5 files into a PostgreSQL database.
* **Data Quality Discovery:** Identified a significant number of `remove_from_cart` events with no preceding `cart` event (due to sessions spanning before the dataset start date). *Decision:* Adjusted the "Rejection Rate" analysis to only include products with verified "add" and "remove" actions within the timeframe.

### 2. SQL Analysis
I performed three distinct major types of analysis using CTEs (Common Table Expressions):
* **The Main Funnel:** An analysis counting distinct users who moved from `View` → `Cart` → `Purchase`.
* **Category Segmentation:** A pivot of conversion rates by `category_code` to identify high-performers.
* **Product Rejection Rate:** A custom metric calculating the percentage of users who added a specific product to their cart but later removed it.

### 3. Visualization (Power BI)
Built a 2-page dashboard..
* **DAX Measures:** Created distinct measures for "Global Conversion" (User-based) vs. "Category Conversion" (Interaction-based) to handle the many-to-many relationship of users browsing multiple categories.

## Key Insights

1. High Intent, High Friction
The Good: The Add-to-Cart rate is 22.4%, more than double the industry standard (~10%). This proves users have high purchase intent and product pages are effective.
The Bad: Despite this high intent, ~70% of users abandon their carts.
The Diagnosis: A drop-off this sharp at the final stage typically signals "Sticker Shock" (unexpected shipping/taxes), technical friction, or a lack of trust signals during the payment process.
3.  Behavior Pattern
Users view this store as a "Restocking Destination," not just a browsing site.
Categories like Apparel.glove (39.6%) and Stationery.cartridge (25.5%) have massive conversion rates. These are high-necessity, low-consideration utility items. Users land, find exactly what they need, and buy immediately.
4. Brand Dilution via non-core Categories
Non-core categories are acting as dead weight. Sport.diving (0%) and Furniture (1.6%) are significantly underperforming.
These categories dilute the brand identity and likely waste ad spend resources without generating revenue.
5. The "Blind Spot" Risk
Products with NULL (missing) category data are converting at 7.0%—higher than the site average.
This is a critical data quality issue. We are currently unable to attribute this success to a specific product line, making it impossible to fully optimize inventory or marketing for these obviously popular items.


---

## 🚀 Recommendations
1. Fix Checkout Friction

Immediate Action: Implement a Cart Recovery Strategy. Trigger automated emails (SMS/Email) 1 hour after abandonment to recover lost sales.
UX Fix: Move shipping cost calculations before the checkout flow (e.g., a "Estimate Shipping" calculator in the Cart view) to prevent sticker shock.
Investigation: Audit the checkout UI for unnecessary clicks or forced account creation, which kills conversion.

2. Portfolio Optimization: The "Focus" Strategy

Double Down On Popular Products: Aggressively feature high-velocity items (Gloves, Cartridges, Cosmetic Bags) on the Homepage and in "Frequently Bought Together" widgets. 

These are your cash cows.
Cut the less popular products: Stop all ad spend on Furniture and Sport categories immediately. Consider de-listing sport.diving entirely to streamline the user experience and focus the brand on Beauty/Utility.

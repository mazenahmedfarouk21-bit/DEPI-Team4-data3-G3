# 🏨 Hotel Booking Data Analysis Project

## 📋 Overview
This repository contains a end-to-end SQL analysis project for a comprehensive hotel booking dataset (comparing **City Hotel** and **Resort Hotel**). 

The goal of this project is to clean, transform, and analyze **119,390 raw records** to uncover actionable business insights regarding booking cancellations, seasonal demand patterns, customer segmentation, room allocations, and revenue optimization.

All database queries, data transformations, and analytical views have been modularized across **5 distinct phases** into a single executable script (`AllHotelQuery.sql`).

---

## 🛠️ Project Phases & SQL Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             PROJECT ARCHITECTURE                            │
├─────────────┬─────────────┬─────────────┬─────────────────┬─────────────────┤
│   PHASE 1   │   PHASE 2   │   PHASE 3   │     PHASE 4     │     PHASE 5     │
│ Data Clean  │ Primary KPIs│ Temporal    │ Customer        │ Room, Meal &    │
│ & Prepping  │ Summary     │ Analysis    │ Segmentation    │ Revenue Ops     │
└─────────────┴─────────────┴─────────────┴─────────────────┴─────────────────┘
```

---

### Phase 1: Data Cleaning & Preparation
* **Dataset Scale:** Cleaned from **119,390 rows & 32 columns** down to **118,726 valid rows & 34 columns**.
* **Missing Values Management:**
  * Converted literal string `'NULL'` records into SQL `NULL` values.
  * Dropped negligible missing records: `children` (4 rows) and `country` (488 rows).
  * Imputed missing `agent` (16,340 rows) and `company` (112,593 rows) with `'Unknown'`.
* **Outliers & Integrity Filters Removed:**
  * Ghost Bookings: Removed 170 bookings with zero guests (`adults + children + babies = 0`).
  * Price Anomalies: Excluded negative ADR values and extreme outliers (`adr < 0` OR `adr > 1000`).
  * Invalid Stays: Removed 640 records where `total_nights = 0`.
* **Feature Engineering:**
  * `total_nights`: Calculated as `stays_in_week_nights + stays_in_weekend_nights`.
  * `total_guests`: Calculated as `adults + children + babies`.

---

### Phase 2: Primary Booking KPIs
* Created `View_Primary_Booking_KPIs` to serve as an automated executive summary:
  * **Total Bookings** vs. **Successful** vs. **Canceled Bookings**.
  * **Overall Cancellation Rate (%)**.
  * **Average Lead Time (Days)**.
  * **Repeat Guest Rate (%)**.
  * **Average Daily Rate (ADR) for Successful Bookings**.

---

### Phase 3: Temporal & Seasonality Analysis
Modular views created to understand demand over time:
* `vw_Monthly_Booking_Cancellation`: Monthly booking volume, successful stays, and cancellation rate trends.
* `vw_Peak_Low_Season`: Demand volume aggregated by month and hotel type across all years.
* `vw_Yearly_Booking_Comparison`: Year-over-year performance comparing 2015, 2016, and 2017.
* `vw_Monthly_Seasonality_Across_Years`: Pivot view evaluating monthly trends across distinct years.
* `vw_Weekday_Weekend_Stay`: Compares average weekday vs. weekend stay patterns.
* `vw_Monthly_Booking_Lead_Time`: Tracks average, minimum, and maximum booking lead times.

---

### Phase 4: Customer Behavior & Segmentation
Views built to evaluate customer demographics, channels, and booking policies:
* `Market_Segment_Analysis`: Analyzes bookings, total cancellations, and repeat cancellers across market segments.
* `Total_distribution_channel`: Distribution channel volume breakdown.
* `REPEATED_VS_NON_REPEATED`: Evaluates repeat guest loyalty.
* `Cancellation_Rate`: Cancellation rate by customer type (`Transient`, `Contract`, `Group`, etc.).
* `Deposit_Cancellation_Rate` & `Deposit_Type_Cancellation_Summary`: Evaluates cancellation behavior, lead time, and ADR across deposit types (`No Deposit`, `Non Refund`, `Refundable`).
* `Top_10_Countries_Booking`: Identifies the top 10 geographical markets by booking volume.

---

### Phase 5: Room, Meal & Revenue Operations
Operational and financial analytics:
* `View_Room_Operations`: Compares `reserved_room_type` against `assigned_room_type` to calculate room change rates, upgrades/downgrades, and cancellation impact.
* `View_Meal_Operations`: Analyzes revenue, booking count, guest count, and cancellation rates across meal plans (`BB`, `HB`, `FB`, `SC`).
* `View_Revenue_Operations`: Tracks total revenue, lost revenue from cancellations, `avg_adr_success`, `revenue_per_night`, and `revenue_per_booking`.
* `View_Revenue_By_Room_Meal`: Cross-analyzes room types and meal bundles to identify the highest revenue-generating packages.

---

## 📂 File Structure
* `AllHotelQuery.sql`: Consolidated SQL script containing all data cleaning statements, feature engineering, and 18 analytical SQL Views.
* `hotel_analysis.pbix`: Power BI report file linked directly to the SQL Views.
* `README.md`: Project documentation and workflow outline.

---

## 🚀 How to Run the SQL Script
1. Open **SQL Server Management Studio (SSMS)**.
2. Create or select your database:
   ```sql
   CREATE DATABASE hotel;
   USE hotel;
   ```
3. Execute `AllHotelQuery.sql` to clean the dataset and create all 18 analytical views automatically.
4. Connect **Power BI** to the SQL Server database and load the views for dashboard creation.

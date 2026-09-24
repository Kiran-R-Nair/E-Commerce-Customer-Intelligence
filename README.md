# E-Commerce Customer Intelligence, Conversion Analytics & Purchase Prediction

## Project Overview

This project analyzes e-commerce customer, website, transaction, product, inventory, and marketing data to understand customer behavior, conversion patterns, and business performance.

The project also develops a machine learning model to predict whether a website session will result in a purchase using information available before the purchase outcome.

## Objectives

* Analyze customer purchasing and website behavior
* Understand the customer conversion funnel
* Identify factors associated with purchase conversion
* Analyze product, inventory, sales, and marketing performance
* Build and evaluate purchase prediction models
* Convert analytical findings into business recommendations
* Present insights through Excel and Power BI

## Dataset

**Dataset:** Kshashtra - ECommerce Store Marketing & Sales
**Source:** Kaggle
**Format:** CSV
**Source Files:** 9
**Total Records:** 599,960
**Dataset Size:** 50.13 MB

Main tables include:

* Customers
* Orders
* Order Line Items
* SKU Catalog
* Website Sessions
* Website Daily
* Inventory Snapshots
* Purchase Orders
* Meta Ads Campaigns

## Project Workflow

```text
Raw Data
   ↓
SQL Data Preparation
   ↓
Data Cleaning & Quality Checks
   ↓
Exploratory Data Analysis
   ↓
Feature Engineering
   ↓
Data Preprocessing
   ↓
Machine Learning
   ↓
Model Comparison & Cross-Validation
   ↓
Final Model Evaluation
   ↓
Business Analysis
   ↓
Excel & Power BI
```

## Machine Learning

### Problem

Binary classification:

* `0` = No Purchase
* `1` = Purchase

One website session is treated as one observation.

### Models Evaluated

Six model configurations were compared:

1. Logistic Regression
2. Balanced Logistic Regression
3. Decision Tree
4. Balanced Decision Tree
5. Random Forest
6. Balanced Random Forest

### Evaluation

Models were evaluated using:

* Accuracy
* Precision
* Recall
* F1 Score
* ROC-AUC
* 5-Fold Stratified Cross-Validation

Class imbalance was handled using balanced class weights.

### Final Model

**Balanced Logistic Regression**

Final test-set performance:

| Metric    |   Score |
| --------- | ------: |
| Accuracy  |  95.98% |
| Precision |  58.37% |
| Recall    | 100.00% |
| F1 Score  |  73.71% |
| ROC-AUC   |  98.15% |

The analysis identified **Add to Cart** and **Begin Checkout** as important indicators of purchase intent.

## Business Analytics

The project covers four major analytical areas:

### Customer & Order Analytics

* First-time vs. repeat customers
* Order value
* Discounts
* Payment methods
* Fulfillment outcomes
* Customer purchasing behavior

### Product & Inventory Analytics

* Product and SKU performance
* Inventory levels
* Sales velocity
* Inventory coverage
* Dead stock
* Supplier lead time

### Marketing & Website Analytics

* Traffic sources
* Website sessions
* Conversion rates
* Product views
* Add-to-cart activity
* Checkout activity
* Purchases
* Revenue
* Meta advertising performance
* Device performance

### Excel Analysis

Excel was used for:

* KPI calculations
* Pivot table analysis
* Customer analysis
* Product and sales analysis
* Inventory risk analysis
* Marketing and website analysis

## Power BI Dashboard

The Power BI dashboard contains six main pages:

1. Executive Overview
2. Customer Intelligence
3. Product & Sales Intelligence
4. Inventory & Supply Intelligence
5. Marketing & Conversion Intelligence
6. Purchase Prediction Intelligence

The dashboard combines business KPIs, customer insights, marketing performance, inventory analysis, conversion analysis, and machine learning predictions.

## Key Business Insights

* Repeat customers have higher average order value than first-time customers.
* Product performance varies significantly across SKUs and categories.
* Marketing channels differ in traffic scale and conversion efficiency.
* The website funnel shows significant drop-offs between browsing, cart, checkout, and purchase.
* Add-to-cart and checkout activity are strong purchase-intent indicators.
* Mobile represents an important customer segment.
* Inventory analysis can help identify stock and slow-moving inventory risks.
* Purchase prediction can be used to identify high-intent sessions for targeted engagement.

## Technologies

* Python
* Pandas
* NumPy
* Matplotlib
* Seaborn
* Scikit-learn
* SQL
* Excel
* Power BI
* Jupyter Notebook

## Project Structure

```text
E-Commerce-Customer-Intelligence/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── sql/
│   ├── Data_Audit.sql
│   └── Final_Tables.sql
│
├── notebooks/
│   └── Ecommerce_Customer_Intelligence.ipynb
│
├── excel/
│
├── powerbi/
│
└── README.md
```

## Conclusion

This project provides an end-to-end e-commerce analytics solution combining SQL, Python, machine learning, Excel, and Power BI.

It moves from understanding historical business performance to identifying customer behavior and predicting purchase intent, providing a foundation for improved customer retention, conversion optimization, marketing decisions, and inventory planning.

## Author

**Kiran R Nair**

Capstone Project 1 - Data Science / Machine Learning



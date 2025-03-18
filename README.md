# Customer Segmentation and Target Market Analysis

## 📌 Project Overview

The marketing department at **Sunshine E-commerce** has engaged the **Data Analytics team** to analyze customer segmentation and identify target customers for optimizing their **$1.5 million marketing budget** in the upcoming quarters. The goal is to increase revenues by strategically targeting high-value customer segments.

---

## 📖 Table of Contents

- [Problem Outline](#problem-outline)
- [Project Workflow](#project-workflow)
- [Data Overview](#data-overview)
- [Code](#Code)
- [Visualizations](#visualizations)
- [Insights & Key Takeaways](#insights--key-takeaways)
- [Next Steps](#next-steps)

---
## Problem Outline

To maximize the effectiveness of marketing efforts, we aim to:

### 🏆 Understand Customer Value  
Identify top customers contributing most to revenue.

### 🔄 Customer Retention & Engagement  
Retain loyal customers and boost engagement among mid-tier ones.

### 💰 Marketing & Budget Allocation  
Design promotions prioritizing high-return segments.

### 📊 Strategic Deciling  
Rank customers into deciles based on **RFM (Recency, Frequency, and Monetary)** metrics to establish an actionable hierarchy.

---

## 🏗️ Project Workflow

1. **Data Preparation & Cleaning**
   - Handle missing values and data inconsistencies.
   - Convert data into a structured format for analysis.

2. **Exploratory Data Analysis (EDA)**
   - Analyze customer behavior and purchasing patterns.
   - Identify trends and anomalies.

3. **RFM Segmentation**
   - Categorize customers based on **Recency, Frequency, and Monetary value**.
   - Assign customer scores for segmentation.

4. **Deciling Analysis**
   - Rank customers into **deciles** (top 10% vs. bottom 10%).
   - Analyze revenue contribution from each segment.

5. **Develop Recommendations**
   - Provide actionable insights for **targeted marketing strategies**.
   - Suggest **budget allocation** for maximizing ROI.

---

## 📊 Data Overview

The dataset used for this project is an **E-commerce transaction dataset**  It includes records of purchases made by customers from various countries.


### 📑 Columns Description:

| Column Name        | Description |
|-------------------|------------|
| **InvoiceNo** | Unique invoice number for each transaction |
| **StockCode** | Product code |
| **Description** | Name of the product |
| **Quantity** | Number of units purchased |
| **InvoiceDate** | Date and time of transaction |
| **UnitPrice** | Price per unit of the product (£) |
| **CustomerID** | Unique identifier for each customer |
| **Country** | Country where the customer is located |

---

## Code

### 1. Database Creation in SQL

```sql
CREATE Database ecommerce;
USE ecommerce;

SHOW DATABASES;
```

### 2.Creating Table "Transactions" in SQL

```sql
CREATE TABLE transactions (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    Price DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(50)
);
```
### 3. Inserting Data Using Python

```Python
import pandas as pd
from sqlalchemy import create_engine

# Step 1: Load the dataset
df = pd.read_csv("/Users/maaz/Documents/Data/data.csv")  # Replace with the path to your CSV file

# Step 2: Convert InvoiceDate to datetime
df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"])

# Step 3: Create a MySQL engine for connecting
from sqlalchemy import create_engine
import getpass

password = getpass.getpass("Enter MySQL password: ")
engine = create_engine(f"mysql+pymysql://root:{password}@localhost/ecommerce")

# Step 4: Insert the data into the MySQL database
df.to_sql("transactions", con=engine, if_exists="append", index=False)

print("Data imported successfully!")
```
### 4.Data Exploration
How many unique customers are active over the selected timeframe?
```sql
SELECT 
    COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM 
    transactions;
```
Distribution of total sales, average purchase size, and frequency of transactions
```sql
SELECT
    CustomerID,
    COUNT(*) AS TransactionFrequency, -- Frequency of Transactions
    SUM(totalsales) AS TotalSales, -- Total sales per customer
    AVG(totalsales) AS AveragePurchaseSize -- Average Purchase per customer
FROM (
    SELECT *, Quantity * UnitPrice AS totalsales FROM transactions
) a
GROUP BY 
    CustomerID
ORDER BY 
    TotalSales DESC;
```
### 5. Data Cleaning and Creating a View for Analysis
```sql
CREATE VIEW project AS
SELECT 
    InvoiceNo,
    StockCode,
    COALESCE(Description, 'Unknown') AS Description,  -- Fill missing values in Description with 'Unknown'
    CONVERT(Quantity, SIGNED) AS Quantity,  -- Convert Quantity to integer
    CAST(InvoiceDate AS DATETIME) AS InvoiceDate,  -- Convert InvoiceDate to DATETIME
    COALESCE(CAST(UnitPrice AS DECIMAL(10, 2)), 0) AS UnitPrice,  -- Handle NULLs and data type
    COALESCE(CustomerID, -1) AS CustomerID,  -- Fill missing CustomerID with -1
    UPPER(Country) AS Country,
    ROUND(Quantity * UnitPrice, 2) AS TotalSales  -- Create TotalSales column and round it to 2 decimal places
FROM transactions
WHERE 
    LENGTH(StockCode) >= 5  -- Remove rows where StockCode is less than 5 characters
    AND Description != '?'  -- Remove rows where Description is "?" 
    AND Quantity >= 0;  -- Remove rows where Quantity is negative
```
### 6. RFM Analysis
```sql
WITH RecencyCTE AS (
    SELECT
        CustomerID,
        DATEDIFF(CURRENT_DATE(), MAX(STR_TO_DATE(invoicedate, '%m/%d/%Y'))) AS Recency
    FROM
        Project
    GROUP BY 
        CustomerID
),
FrequencyCTE AS (
    SELECT
        CustomerID,
        COUNT(*) AS Frequency
    FROM project
    GROUP BY CustomerID
),
MonetaryCTE AS (
    SELECT
        CustomerID,
        SUM(totalsales) AS Monetary
    FROM 
        project
    GROUP BY CustomerID
),
RFM AS (
    SELECT
        R.CustomerID,
        NTILE(5) OVER (ORDER BY R.Recency ASC) AS RecencyScore,
        NTILE(5) OVER (ORDER BY F.Frequency DESC) AS FrequencyScore,
        NTILE(5) OVER (ORDER BY M.Monetary DESC) AS MonetaryScore
    FROM
        RecencyCTE R
    JOIN
        FrequencyCTE F ON R.CustomerID = F.CustomerID
    JOIN
        MonetaryCTE M ON R.CustomerID = M.CustomerID
)
SELECT
    CustomerID,
    RecencyScore,
    FrequencyScore,
    MonetaryScore,
    (RecencyScore + FrequencyScore + MonetaryScore) AS RFMScore
FROM
    RFM
ORDER BY 
    RFMScore DESC;
```
### 7. Identify Declining Segment
```sql
WITH DeclineSegment AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN TotalSales >= 2000 THEN 'High Value'
            WHEN TotalSales BETWEEN 800 AND 2000 THEN 'Medium Value'
            WHEN TotalSales BETWEEN 400 AND 799 THEN 'Low Value'
            ELSE 'Dormant'
        END AS SalesSegment
    FROM 
        project
)
SELECT 
    SalesSegment,
    COUNT(DISTINCT CustomerID) AS CustomerCount
FROM 
    DeclineSegment
GROUP BY 
    SalesSegment
ORDER BY 
    FIELD(SalesSegment, 'High Value', 'Medium Value', 'Low Value', 'Dormant');
```
## 📊 Visualizations

<img width="423" alt="Screenshot 2025-03-17 at 10 55 45 PM" src="https://github.com/user-attachments/assets/5f8f4d2e-96d7-4e1f-9d8e-8d100d0640ff" />

<img width="451" alt="Screenshot 2025-03-17 at 10 55 55 PM" src="https://github.com/user-attachments/assets/5d40347f-a159-47e5-800f-37be18d71ca8" />

<img width="400" alt="Screenshot 2025-03-17 at 11 01 41 PM" src="https://github.com/user-attachments/assets/f3897c03-9203-4a65-97d6-4f737c64da20" />

## 🔎 Insights & Key Takeaways
- **The top 20% of customers contribute to over 60% of total revenue.**
- **Loyal customers should be nurtured with exclusive promotions.**
- **Mid-tier customers have potential for upselling with personalized marketing.**
- **Strategic budget allocation can maximize ROI by focusing on high-value segments.**

## 🚀 Next Steps

### 1.Develop Targeted Marketing Campaigns
   - Personalized Offers: Use insights from the RFM segments to craft personalized marketing offers tailored to the needs and behavior of different customer groups (e.g., loyalty programs for high-value segments or incentives for at-risk customers).
   - Customer Retention Programs: For customers who score low in recency or frequency, design retention campaigns to re-engage them, such as sending reminders, special discounts, or content relevant to their interests.

 ### 2. Optimize Customer Experience (CX)

- **Improve User Journey**:  
  Based on insights from deciling and RFM analysis, streamline customer experiences (e.g., better communication with high-frequency buyers or special offers for customers with a high monetary score).

- **Customized Engagement**:  
  Different segments may need different customer service or communication levels. High-value clients might need VIP treatment, while lower-value customers may appreciate self-service options.

---

### 3. Create Cross-Selling and Up-Selling Strategies

- Identify cross-selling or upselling opportunities based on customer behavior patterns across different RFM segments.  
  For example:
  - Upsell premium products to high-frequency customers.
  - Recommend related products to high-value customers.

---

### 4. Data-Driven Forecasting

- **Revenue Forecasting**:  
  Leverage insights from decile and RFM analysis to predict revenue growth or possible churn, and strategize accordingly for product launches or resource allocation.

- **Campaign Effectiveness**:  
  Evaluate the effectiveness of your campaigns by examining the response from different deciles of customers. Track performance based on how well specific segments have converted, improved frequency, or increased spend.

---

### 5. Review and Iterate

- Regularly monitor how your segments evolve over time. RFM scores can change, so refine your marketing strategies, communication plans, and customer service offerings as necessary.

- **Test Different Approaches**:  
  Use A/B testing to determine what type of messaging, promotions, or offers work best for different customer groups identified through RFM analysis.

---

### 6. Resource Allocation

- Allocate more resources (e.g., marketing budget, account management) to high-value or loyal segments to maximize return on investment (ROI).

- Optimize efforts on lower-value segments by running cost-effective campaigns to slowly elevate them to more profitable levels.

---

 ### 7. Integration with Other Business Units

- **Sales and Support Collaboration**:  
  Share segmentation insights with sales and customer support teams for better targeting, retention efforts, or resolving customer issues specific to certain segments.

- **Product Development Feedback**:  
  Feedback from customer segments can provide product teams with valuable insights on feature requirements or new product opportunities that address customer needs.

---

These strategies will help you not just understand your customer base better but also implement actions that maximize long-term customer value.






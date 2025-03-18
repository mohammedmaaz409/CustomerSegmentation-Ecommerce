
-- Step 1: Cretaed databases in the server and validated it
CREATE Database ecommerce;
use ecommerce;

SHOW DATABASES;

-- Step 2: inserting the data by creating a table

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

-- Step 3: inserting the data using python 

-- Validation 

select * from transactions limit 10

-- Data Exploration
-- How many unique customers are active over the selected timeframe?

select 
	count(distinct CustomerID) as ActiveCsutomers
from 
	transactions

-- distribution of total sales, average purchase size, and frequency of transactions

select
	CustomerID,
    count(*) as TransactionFrequency, -- Frequency of Transactions
    sum(totalsales) as TotalSales, -- Total sales per customer
    avg(totalsales) as AveragePurchaseSize -- Average Purchase per customer
from (
select *, quantity*Unitprice as totalsales from transactions
) a
group by 
	customerid
order by totalsales desc

-- Data cleaning and creating a view to perform analysis

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


-- Data validation

select * from project limit 10

-- Data exploration after cleaning data

select
	CustomerID,
    count(*) as TransactionFrequency, -- Frequency of Transactions
    avg(totalsales) as AveragePurchaseSize -- Average Purchase per customer
from project
group by 
	customerid
order by AveragePurchaseSize desc

-- Understanding RFM Analysis
-- Recency: Measures of recently a customer has purchased
-- Frequncy: Counts the number of purchases by the customer at a given time period
-- Monetary: Sums up the total amount spent by a customer

WITH RecencyCTE as (
select
	CustomerID,
    Datediff(CURRENT_DATE(), MAX(STR_TO_DATE(invoicedate, '%m/%d/%Y'))) as Recency
from
	Project
Group by 
	CustomerID
),
Frequency CTE as (
select
	CustomerID,
    count(*) as Frequency
From project
Group by customerID
),
MonetaryCTE as (
select
	customerid,
	sum(totalsales) as monetary
 from 
	project
Group by customerID
),
RFM as (
select
	r.customerid,
    NTILE(5) over (order by R.Recency asc) as Recencyscore
    NTILE(5) over (order by F.Frequency desc) as Frequncyscore
    NTILE(5) over (order by M.Monetary desc) as Monetaryscore
from
	RecencyCTE R
Join
	FrequencyCTE F on R.CustomerID = F.CustomerID
Join
	MonetaryCTE M on R.CustomerID = M.CustomerID
)
select
	CustomerID,
    Recencyscore,
    Frequencyscore,
    Monetaryscore,
    (Recencyscore + Fequencyscore + Monetaryscore) as RFMscore
from
	RFM
order by RFM desc 

-- 

WITH TotalSales AS (
    SELECT 
        CustomerID,
        SUM(totalsales) AS TotalSales
    FROM 
        (select *, quantity*unitprice as totalsales from project) as a
    GROUP BY 
        CustomerID
),
DeclineSegment AS (
    select 
        customerid,
        case 
            when TotalSales >= 2000 THEN 'High Value'
            when TotalSales BETWEEN 800 AND 2000 THEN 'Medium Value'
            when TotalSales BETWEEN 400 AND 799 THEN 'Low Value'
            else 'Dormant'
        end as SalesSegment
    FROM 
        TotalSales
)
select 
    SalesSegment,
    COUNT(CustomerID) AS CustomerCount
from 
    DeclineSegment
group bu 
    SalesSegment
order by
    FIELD(SalesSegment, 'High Value', 'Medium Value', 'Low Value', 'Dormant');

-- identify declining segment

WITH 
DeclineSegment AS (
    select 
        CustomerID,
        case 
            when TotalSales >= 2000 then 'High Value'
            when TotalSales between 800 and 2000 then 'Medium Value'
            when TotalSales between 400 and 799 then 'Low Value'
            else 'Dormant'
        end as SalesSegment
    from 
        project
)
SELECT 
    SalesSegment,
    COUNT(CustomerID) AS CustomerCount
FROM 
    DeclineSegment
GROUP BY 
    SalesSegment
ORDER BY 
    FIELD(SalesSegment, 'High Value', 'Medium Value', 'Low Value', 'Dormant');

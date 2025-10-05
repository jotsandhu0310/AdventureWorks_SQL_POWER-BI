USE adventure_works;

-- 1️ Total Sales by Year
-- First I checked the sales table to see how data looks
SELECT * FROM sales;

-- Tried to get total sales by year
SELECT YEAR(OrderDate) AS Year,    
       SUM(Sales) AS TotalSales   
FROM sales
GROUP BY YEAR(OrderDate)          
ORDER BY Year;

-- Problem: YEAR(OrderDate) returned NULL and SUM(Sales) = 0
-- Reason: OrderDate and Sales were stored as text (VARCHAR) not proper DATE/DECIMAL

-- So I need to clean data first
DESCRIBE sales;  -- check column types

-- Convert OrderDate from string to proper date format
UPDATE sales
SET OrderDate = STR_TO_DATE(OrderDate, '%W, %M %d, %Y');

-- Check if conversion worked
SELECT OrderDate
FROM sales
LIMIT 10;

-- Check Sales column for weird characters like ₹, $ or extra spaces
SELECT Sales, LENGTH(Sales), Sales REGEXP '[^0-9.]' AS HasNonNumeric
FROM sales
LIMIT 20;

-- Remove weird characters and extra spaces
UPDATE sales
SET Sales = TRIM(REPLACE(REPLACE(REPLACE(Sales, ',', ''), '$', ''), '₹', ''));

-- Convert Sales column to decimal so we can sum it
ALTER TABLE sales
MODIFY Sales DECIMAL(12,2);

-- Check cleaned Sales column
SELECT Sales
FROM sales
LIMIT 10;

-- Now sum by year works fine
SELECT YEAR(OrderDate) AS Year,
       SUM(Sales) AS TotalSales
FROM sales
GROUP BY YEAR(OrderDate)
ORDER BY Year;


-- 2️ Top 10 Products by Sales
-- Check sales and product tables first
SELECT * FROM sales;
SELECT * FROM product;

-- I want top selling products, so I join sales and product on ProductKey
-- then sum sales per product, group by product and order descending
SELECT p.product,
       SUM(s.Sales) AS TotalSales
FROM sales s
JOIN product p ON p.ProductKey = s.ProductKey
GROUP BY p.product
ORDER BY TotalSales DESC
LIMIT 10;


-- 3️ Sales by Region
SELECT * FROM sales;
SELECT * FROM reseller;
SELECT * FROM region;

-- Problem: reseller had column Country-Region which was giving error because of '-' and sales and region didn't have common column
-- Fix: rename column to Country
ALTER TABLE reseller
RENAME COLUMN `Country-Region` TO Country;

-- Now I can join sales → reseller → region to get total sales by region
SELECT r.region,
       SUM(s.Sales) AS TotalSales
FROM sales s
JOIN reseller re ON re.ResellerKey = s.ResellerKey
JOIN region r ON r.Country = re.Country
GROUP BY r.region
ORDER BY TotalSales DESC
LIMIT 10;


-- 4️ Salesperson Performance
SELECT * FROM sales;
SELECT * FROM salesperson;

-- I want to see total sales and number of deals closed by each salesperson
-- Join sales and salesperson on EmployeeKey
SELECT sp.salesperson,
       SUM(Sales) AS TotalSales,
       COUNT(DISTINCT SalesOrderNumber) AS DealsClosed
FROM sales s
JOIN salesperson sp ON sp.EmployeeKey = s.EmployeeKey
GROUP BY sp.salesperson
ORDER BY TotalSales DESC;


-- 5️ Actual Sales vs Targets
SELECT * FROM sales;
SELECT * FROM reseller;
SELECT * FROM targets;
SELECT * FROM region;
SELECT * FROM salesperson;
SELECT * FROM salespersonregion;

-- Convert TargetMonth to DATE because it was text
UPDATE targets
SET TargetMonth = STR_TO_DATE(TargetMonth, '%W, %M %d, %Y');

-- Check it
SELECT TargetMonth
FROM targets
LIMIT 10;

-- Now join sales → reseller → region → salesperson → targets to get Actual vs Target
-- Targets are per salesperson so join on EmployeeId
-- Compare year of sale and target month
SELECT r.Region,
       YEAR(s.OrderDate) AS Year,
       SUM(s.Sales) AS ActualSales,
       t.Target,
       (SUM(s.Sales) - t.Target) AS Variance
FROM sales s
JOIN reseller re ON re.ResellerKey = s.ResellerKey
JOIN region r ON re.Country = r.Country
JOIN salesperson sp ON sp.EmployeeKey = s.EmployeeKey
JOIN targets t ON sp.EmployeeId = t.EmployeeId
              AND YEAR(s.OrderDate) = YEAR(t.TargetMonth)
GROUP BY r.Region, YEAR(s.OrderDate), t.Target
ORDER BY Year, r.Region;

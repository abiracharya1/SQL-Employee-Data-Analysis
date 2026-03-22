--Project: Finance & Supply Chain Analytics for AtliQ Technology
--Tools & Technologies: SQL Server (T-SQL), SQL Queries, Pivot Tables, Data Analysis


--1. Database Creation
CREATE DATABASE SupplyChainFinanceManagement;
GO
USE SupplyChainFinanceManagement;
GO

--2. Dimension Tables
--2.1 Customer Dimension

CREATE TABLE dim_customer (
customer_id INT PRIMARY KEY,
customer_name VARCHAR(100) NOT NULL,
channel VARCHAR(50),
region VARCHAR(50));

--2.2 Product Dimension
CREATE TABLE dim_product (
product_id INT PRIMARY KEY,
product_name VARCHAR(100) NOT NULL,
category VARCHAR(50),
variant VARCHAR(50));

--3. Fact Tables
--3.1 Monthly Forecast
CREATE TABLE fact_forecast_monthly (
forecast_id INT PRIMARY KEY,
product_id INT NOT NULL,
fiscal_year VARCHAR(10),
month INT,
forecast_qty INT,
CONSTRAINT FK_forecast_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id));


--3.2 Freight Cost
CREATE TABLE fact_freight_cost (
freight_id INT PRIMARY KEY,
product_id INT NOT NULL,
market VARCHAR(50),
fiscal_year VARCHAR(10),
cost DECIMAL(10,2),
CONSTRAINT FK_freight_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id));

--3.3 Gross Price
CREATE TABLE fact_gross_price (
price_id INT PRIMARY KEY,
product_id INT NOT NULL,
fiscal_year VARCHAR(10),
gross_price DECIMAL(10,2),
CONSTRAINT FK_grossprice_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id));

--3.4 Manufacturing Cost
CREATE TABLE fact_manufacturing_cost (
cost_id INT PRIMARY KEY,
product_id INT NOT NULL,
fiscal_year VARCHAR(10),
manufacturing_cost DECIMAL(10,2),
CONSTRAINT FK_manufacturing_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id));

--3.5 Post-Invoice Deductions
CREATE TABLE fact_post_invoice_deductions (
deduction_id INT PRIMARY KEY,
product_id INT NOT NULL,
fiscal_year VARCHAR(10),
post_invoice_deduction DECIMAL(10,2),
CONSTRAINT FK_postinvoice_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

--3.6 Pre-Invoice Deductions
CREATE TABLE fact_pre_invoice_deductions (
pre_deduction_id INT PRIMARY KEY,
product_id INT NOT NULL,
fiscal_year VARCHAR(10),
pre_invoice_deduction DECIMAL(10,2),
CONSTRAINT FK_preinvoice_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id));

--3.7 Monthly Sales
CREATE TABLE fact_sales_monthly (
sales_id INT PRIMARY KEY,
customer_id INT NOT NULL,
product_id INT NOT NULL,
fiscal_year VARCHAR(10),
month INT,
quantity_sold INT,
gross_price DECIMAL(10,2),
CONSTRAINT FK_sales_customer
FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
CONSTRAINT FK_sales_product
FOREIGN KEY (product_id) REFERENCES dim_product(product_id));

--4. Sample Data Insertion
--4.1 Customers
INSERT INTO dim_customer VALUES
(1, 'Croma', 'Retail', 'North'),
(2, 'Amazon', 'E-Commerce', 'Global');

--4.2 Products
INSERT INTO dim_product VALUES
(101, 'AtliQ Mouse', 'Accessory', 'Wireless'),
(102, 'AtliQ Keyboard', 'Accessory', 'Mechanical');

--4.3 Gross Price
INSERT INTO fact_gross_price VALUES
(1, 101, '2023-2024', 30.00),
(2, 102, '2023-2024', 50.00);

--4.4 Pre-Invoice Deductions
INSERT INTO fact_pre_invoice_deductions VALUES
(1, 101, '2023-2024', 2.00),
(2, 102, '2023-2024', 5.00);

--4.5 Post-Invoice Deductions
INSERT INTO fact_post_invoice_deductions VALUES
(1, 101, '2023-2024', 3.00),
(2, 102, '2023-2024', 4.00);

--4.6 Manufacturing Cost
INSERT INTO fact_manufacturing_cost VALUES
(1, 101, '2023-2024', 20.00),
(2, 102, '2023-2024', 30.00);

--4.7 Monthly Sales
INSERT INTO fact_sales_monthly VALUES
(1, 1, 101, '2023-2024', 7, 100, 30.00),
(2, 2, 102, '2023-2024', 7, 50, 50.00);

--5. Analytical Queries (T-SQL)
--5.1 Fiscal Year Logic (AtliQ: Sep–Aug)
DECLARE @calendar_date DATE = '2023-07-15';

SELECT
CASE
WHEN MONTH(@calendar_date) >= 9 THEN YEAR(@calendar_date) + 1
ELSE YEAR(@calendar_date)
END AS fiscal_year;


--5.2 Monthly Product Sales Report
SELECT
s.fiscal_year,
s.month,
p.product_name,
p.variant,
s.quantity_sold,
s.gross_price,
s.quantity_sold * s.gross_price AS total_gross_revenue
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_id = p.product_id
JOIN dim_customer c
ON s.customer_id = c.customer_id
WHERE c.customer_name = 'Croma'
AND s.fiscal_year = '2023-2024';

--5.3 Gross Margin Calculation

SELECT
p.product_name,(s.quantity_sold * s.gross_price) - (s.quantity_sold * m.manufacturing_cost) AS gross_margin, ((s.quantity_sold * s.gross_price) - (s.quantity_sold * m.manufacturing_cost)) * 100.0 / (s.quantity_sold * s.gross_price) AS gross_margin_percentage
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_id = p.product_id
JOIN fact_manufacturing_cost m
ON s.product_id = m.product_id
AND s.fiscal_year = m.fiscal_year;

--5.4 Forecast Accuracy
SELECT
f.fiscal_year,
f.month,
p.product_name,
f.forecast_qty,
ISNULL(s.quantity_sold, 0) AS actual_qty,
CASE
WHEN f.forecast_qty > 0
THEN CAST(ISNULL(s.quantity_sold,0) AS FLOAT) / f.forecast_qty * 100
ELSE NULL
END AS forecast_accuracy_percentage
FROM fact_forecast_monthly f
LEFT JOIN fact_sales_monthly s
ON f.product_id = s.product_id
AND f.month = s.month
AND f.fiscal_year = s.fiscal_year
JOIN dim_product p
ON f.product_id = p.product_id;


## Create database
CREATE DATABASE ecommerce;
USE ecommerce;

## Create a imported dataset table
CREATE TABLE dataset_ori (
    InvoiceNo VARCHAR(255),
    StockCode VARCHAR(255),
    Description TEXT,
    Quantity VARCHAR(255),
    InvoiceDate VARCHAR(255),
    UnitPrice VARCHAR(255),
    CustomerID VARCHAR(255),
    Country VARCHAR(255)
);

## Import dataset into database as one table
-- Remember to adjust secure config of mysql server
LOAD DATA INFILE "/usr/local/mysql-8.1.0-macos13-x86_64/to-import-data/dataset/data.csv" -- directory to dataset csv file
	INTO TABLE dataset_ori
    CHARACTER SET latin1
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n' 
	IGNORE 1 LINES; -- skip header row


## CLEAN dataset
CREATE TABLE dataset_cleaned AS
	SELECT * FROM dataset_ori;
ALTER TABLE dataset_cleaned
	ADD COLUMN DatasetID INT AUTO_INCREMENT PRIMARY KEY;

#### checking data
SELECT * FROM dataset_cleaned;

### Cleaning each column
-- Description
DELETE FROM dataset_cleaned WHERE Description = '' AND DatasetID > 0;
UPDATE dataset_cleaned
	SET Description = TRIM(Description) 
    WHERE DatasetID > 0;
-- Quantity
ALTER TABLE dataset_cleaned
	MODIFY COLUMN Quantity INT; 
-- InvoiceDate
UPDATE dataset_cleaned
	SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i') WHERE DatasetID > 0;
ALTER TABLE dataset_cleaned
	MODIFY COLUMN InvoiceDate DATETIME;
-- UnitPrice
ALTER TABLE dataset_cleaned
	MODIFY COLUMN UnitPrice DECIMAL(10, 2); -- 10 digits in total including 2 digits after decimal point
DELETE FROM dataset_cleaned WHERE UnitPrice < 0 AND DatasetID > 0;
-- CustomerID
DELETE FROM dataset_cleaned WHERE CustomerID = '' AND DatasetID > 0;
ALTER TABLE dataset_cleaned
	MODIFY COLUMN CustomerID INT; 



## DATABASE NORMALISATION

### Countries table
CREATE TABLE countries AS
	SELECT DISTINCT Country AS CountryName
	FROM dataset_cleaned;
ALTER TABLE countries
	ADD COLUMN CountryID INT AUTO_INCREMENT PRIMARY KEY;
-- check
SELECT * FROM countries;

### customers table
CREATE TABLE customers AS
	SELECT DISTINCT CustomerID AS CustomerID
	FROM dataset_cleaned;
ALTER TABLE customers
	ADD PRIMARY KEY (CustomerID);
-- check
SELECT * FROM customers;

### customers_countries table
CREATE TABLE customers_countries AS
	SELECT DISTINCT dc.CustomerID AS CustomerID, c.CountryID AS CountryID
	FROM dataset_cleaned dc
	JOIN countries c ON dc.Country = c.CountryName;
ALTER TABLE customers_countries
	ADD PRIMARY KEY(CustomerID, CountryID),
    ADD FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
    ADD FOREIGN KEY (CountryID) REFERENCES countries(CountryID);
-- check
SELECT * FROM customers_countries;

### products table
CREATE TABLE products AS
	SELECT DISTINCT StockCode, Description, UnitPrice
    FROM dataset_cleaned;
ALTER TABLE products
	ADD COLUMN ProductID INT AUTO_INCREMENT PRIMARY KEY;
-- check
SELECT * FROM products;

### invoices table
CREATE TABLE invoices AS
	SELECT DISTINCT dc.InvoiceNo, dc.InvoiceDate, c.CustomerID
    FROM dataset_cleaned dc
    JOIN customers c ON dc.CustomerID = c.CustomerID;
ALTER TABLE invoices
	ADD COLUMN InvoiceID INT AUTO_INCREMENT PRIMARY KEY,
	ADD FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID);
-- check
SELECT * FROM invoices;

### invoices_products table
CREATE TABLE invoices_products (
    InvoiceID INT,
    ProductID INT,
    Quantity INT,
    PRIMARY KEY (InvoiceID, ProductID),
    FOREIGN KEY (InvoiceID) REFERENCES invoices(InvoiceID),
    FOREIGN KEY (ProductID) REFERENCES products(ProductID)
);
-- Populate Invoices_Products table
INSERT IGNORE INTO Invoices_Products (InvoiceID, ProductID, Quantity)
	SELECT i.InvoiceID, p.ProductID, dc.Quantity
	FROM dataset_cleaned dc
	LEFT JOIN invoices i ON dc.InvoiceNo = i.InvoiceNo
	LEFT JOIN products p ON dc.StockCode = p.StockCode;
-- check
SELECT * FROM invoices_products;


## INSIGHTFUL VIEWS

-- Total Revenue Per Country:
CREATE VIEW total_rev_per_country AS
	SELECT c.CountryName, SUM(p.UnitPrice * ip.Quantity) AS TotalRevenue
		FROM countries c
		JOIN customers_countries cc ON c.CountryID = cc.CountryID
		JOIN invoices i ON cc.CustomerID = i.CustomerID
		JOIN invoices_products ip ON i.InvoiceID = ip.InvoiceID
		JOIN products p ON ip.ProductID = p.ProductID
		GROUP BY c.CountryName
		ORDER BY TotalRevenue DESC;


-- Monthly Revenue Trend:
CREATE VIEW monthly_rev_trend AS
	SELECT DATE_FORMAT(i.InvoiceDate, '%Y-%m') AS Month, SUM(p.UnitPrice * ip.Quantity) AS MonthlyRevenue
		FROM invoices i
		JOIN invoices_products ip ON i.InvoiceID = ip.InvoiceID
		JOIN products p ON ip.ProductID = p.ProductID
		GROUP BY Month
		ORDER BY Month;

-- Total Amount of Each Invoice:
CREATE VIEW invoice_totals AS
	SELECT i.InvoiceID, SUM(p.UnitPrice * ip.Quantity) AS InvoiceTotal
		FROM invoices i
		JOIN invoices_products ip ON i.InvoiceID = ip.InvoiceID
		JOIN products p ON ip.ProductID = p.ProductID
		GROUP BY i.InvoiceID;

-- Average Invoice Amount:
CREATE VIEW avg_invoice_amount AS
	SELECT AVG(InvoiceTotal) AS AverageInvoiceAmount
		FROM invoice_totals;



## export views to csv files
SELECT * 
	INTO OUTFILE "/usr/local/mysql-8.1.0-macos13-x86_64/exported_views/total_rev_per_country.csv"
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
	ESCAPED BY '\\'
	LINES TERMINATED BY '\n'
    FROM total_rev_per_country;

SELECT * 
	INTO OUTFILE '/usr/local/mysql-8.1.0-macos13-x86_64/exported_views/monthly_rev_trend.csv'
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
	ESCAPED BY '\\'
	LINES TERMINATED BY '\n'
	FROM monthly_rev_trend;

SELECT * 
	INTO OUTFILE '/usr/local/mysql-8.1.0-macos13-x86_64/exported_views/invoice_totals.csv'
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
	ESCAPED BY '\\'
	LINES TERMINATED BY '\n'
	FROM invoice_totals;

SELECT * 
	INTO OUTFILE '/usr/local/mysql-8.1.0-macos13-x86_64/exported_views/avg_invoice_amount.csv'
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"'
	ESCAPED BY '\\'
	LINES TERMINATED BY '\n'
	FROM avg_invoice_amount;






##### NOTE ######
SELECT *
	FROM products
	WHERE UnitPrice <= 0;


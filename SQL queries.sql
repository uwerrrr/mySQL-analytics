## Create database
CREATE DATABASE ecommerce;
USE ecommerce;

## Create a imported dataset table
CREATE TABLE dataset (
    InvoiceNo INT,
    StockCode VARCHAR(255),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10, 2),
    CustomerID INT,
    Country VARCHAR(255)
);
CREATE TABLE dataset (
    InvoiceNo VARCHAR(255),
    StockCode VARCHAR(255),
    Description TEXT,
    Quantity VARCHAR(255),
    InvoiceDate VARCHAR(255),
    UnitPrice VARCHAR(255),
    CustomerID VARCHAR(255),
    Country VARCHAR(255)
);

SHOW TABLES;
SELECT * FROM dataset;

DROP TABLE dataset;

## Import dataset into database as one table
## The script below does NOT work because of server sercurity option
-- LOAD DATA INFILE '/Users/vannguyen/Library/Mobile Documents/com~apple~CloudDocs/<>iCloud cua Van/Work/Projects/Repos/mySQL-analytics/dataset/data.csv' 
LOAD DATA INFILE './dataset/data.csv' 
	INTO TABLE dataset
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n' 
	IGNORE 1 LINES; -- skip header row


SHOW VARIABLES LIKE 'secure_file_priv';

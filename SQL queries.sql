SHOW TABLES;
SELECT * FROM dataset;

DROP TABLE dataset;


## Create database
CREATE DATABASE ecommerce;
USE ecommerce;

## Create a imported dataset table
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


## Import dataset into database as one table
-- Remember to adjust secure config of mysql server
LOAD DATA INFILE "/usr/local/mysql-8.1.0-macos13-x86_64/to-import-data/dataset/data.csv" -- directory to dataset csv file
	INTO TABLE dataset
    CHARACTER SET latin1
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n' 
	IGNORE 1 LINES; -- skip header row


## DATABASE NORMALISATION
### Countries Table
-- create
CREATE TABLE Countries (
    CountryID INT AUTO_INCREMENT PRIMARY KEY,
    CountryName VARCHAR(255) UNIQUE
);
-- populate
INSERT INTO Countries (CountryName)
	SELECT DISTINCT Country FROM dataset; 
-- check
SELECT * FROM Countries;





SHOW TABLES;
SELECT * FROM dataset;

DROP TABLE dataset;


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
SET SQL_SAFE_UPDATES=0; -- turn update safe mode off for updating table easier
SET SQL_SAFE_UPDATES=1;


CREATE TABLE dataset_cleaned AS
	SELECT * FROM dataset_ori;
ALTER TABLE dataset_cleaned
	ADD COLUMN DatasetID INT AUTO_INCREMENT PRIMARY KEY;
UPDATE dataset_cleaned
	SET CustomerID = '0'
	WHERE CustomerID = '' AND DatasetID > 0; 


## DATABASE NORMALISATION
### Countries Table
DROP TABLE Countries;
-- create
CREATE TABLE Countries (
    CountryID INT AUTO_INCREMENT PRIMARY KEY,
    CountryName VARCHAR(255) UNIQUE
    );
    
-- populate
INSERT INTO Countries (CountryName)
	SELECT DISTINCT Country FROM dataset_cleaned; 

-- add CountryID to dataset_cleaned
ALTER TABLE dataset_cleaned
	ADD COLUMN CountryID INT;
ALTER TABLE dataset_cleaned
	ADD FOREIGN KEY (CountryID) REFERENCES Countries(CountryID);
UPDATE dataset_cleaned AS dc 
	JOIN Countries AS c ON dc.Country = c.CountryName
	SET dc.CountryID = c.CountryID
	WHERE  dc.Country = c.CountryName AND dc.DatasetID > 0;

-- check
SELECT * FROM Countries;


### Customer Table
DROP TABLE Customer;
-- create
CREATE TABLE Customer (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
	CountryID INT,
	FOREIGN KEY(CountryID) REFERENCES Countries(CountryID) 
);

-- populate
INSERT INTO Customer (CustomerID)
	SELECT DISTINCT Country FROM dataset_cleaned; 



-- check
SELECT * FROM Customer;



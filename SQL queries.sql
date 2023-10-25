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
DROP TABLE dataset_cleaned;

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
### Countries Table
-- DROP TABLE Countries;
-- create
CREATE TABLE Countries (
    CountryID INT AUTO_INCREMENT PRIMARY KEY,
    CountryName VARCHAR(255) UNIQUE
    );
-- populate
INSERT INTO Countries (CountryName)
	SELECT DISTINCT Country FROM dataset_cleaned; 
-- check
SELECT * FROM Countries;
-- add CountryID to dataset_cleaned
ALTER TABLE dataset_cleaned
	ADD COLUMN CountryID INT;
ALTER TABLE dataset_cleaned
	ADD FOREIGN KEY (CountryID) REFERENCES Countries(CountryID);
UPDATE dataset_cleaned AS dc 
	JOIN Countries AS c ON dc.Country = c.CountryName
	SET dc.CountryID = c.CountryID
	WHERE  dc.Country = c.CountryName AND dc.DatasetID > 0;



### Customer Table
-- DROP TABLE Customers;
-- create
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY
);

-- populate
INSERT INTO Customers (CustomerID)
	SELECT DISTINCT CustomerID FROM dataset_cleaned; 
    
-- check
SELECT * FROM Customers;


### CustomerCountry table
-- create
CREATE TABLE CustomerCountry(
    CustomerID INT NOT NULL,
    CountryID INT NOT NULL,
    PRIMARY KEY(CustomerID, CountryID),
    FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY(CountryID) REFERENCES Countries(CountryID)
);

-- populate
INSERT INTO CustomerCountry (CustomerID, CountryID)
	SELECT c.CustomerID, d.CountryID
	FROM dataset_cleaned d
	JOIN Customers c ON d.CustomerID = c.CustomerID
	JOIN Countries cntry ON d.CountryID = cntry.CountryID;


-- check
SELECT * FROM CustomerCountry;











#### Note
SET SQL_SAFE_UPDATES=0; -- turn update safe mode off for updating table easier
SET SQL_SAFE_UPDATES=1;

CREATE TABLE Customer (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
	CountryID INT,
	FOREIGN KEY(CountryID) REFERENCES Countries(CountryID) 
);

SELECT COUNT(*) FROM (SELECT DISTINCT CustomerID FROM dataset_cleaned) AS a; -- 4373

SELECT DISTINCT CustomerID, COUNT(*) AS Count
FROM dataset_cleaned
GROUP BY CustomerID
HAVING Count > 1;


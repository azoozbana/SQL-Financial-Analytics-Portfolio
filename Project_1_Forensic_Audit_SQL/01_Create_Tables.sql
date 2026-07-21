-- =========================================================================
-- DATABASE 1: FinancePractice (Staging & Practice Playground)
-- =========================================================================

USE FinancePractice;
GO

-- Drop existing tables to ensure a clean slate
DROP TABLE IF EXISTS Company_Expenses;
DROP TABLE IF EXISTS Corporate_Ledger;
DROP TABLE IF EXISTS Department_Directory;
DROP TABLE IF EXISTS Approved_Vendors;
DROP TABLE IF EXISTS Price_Master;
DROP TABLE IF EXISTS Inventory_Stock;
DROP TABLE IF EXISTS Active_Roster;
DROP TABLE IF EXISTS Sales_Ledger;
DROP TABLE IF EXISTS Procedure_Master;
DROP TABLE IF EXISTS Claims_Ledger;
GO

-- Core transactional table for company expenses
CREATE TABLE Company_Expenses (
    Transaction_ID INT IDENTITY(1,1) PRIMARY KEY,
    Expense_Date DATE,
    Department VARCHAR(50),
    Category VARCHAR(50), -- Fixed spelling typo
    Amount DECIMAL(10, 2)
);
GO

-- Corporate general ledger records with approval tracking
CREATE TABLE Corporate_Ledger (
    Ledger_Sequence_ID INT IDENTITY(1,1) PRIMARY KEY,
    Invoice_ID INT,
    Post_Date DATE,
    Vendor VARCHAR(100),
    Department VARCHAR(50),
    Amount DECIMAL(10, 2),
    Approved_By VARCHAR(50)
);
GO

-- Directory mapping departments to their active managers
CREATE TABLE Department_Directory (
    Department VARCHAR(50),
    Manager_Name VARCHAR(50)
);
GO

-- Master directory of approved vendors
CREATE TABLE Approved_Vendors (
    Vendor_Code INT PRIMARY KEY,
    Vendor_Name VARCHAR(50)
);
GO

-- Standard cost reference sheet for products
CREATE TABLE Price_Master (
    Item_Name VARCHAR(50) PRIMARY KEY,
    Standard_Cost INT
);
GO

-- Warehouse stock ledger with storage aging
CREATE TABLE Inventory_Stock (
    Item_ID INT PRIMARY KEY,
    Item_Name VARCHAR(50),
    Category VARCHAR(50),
    Unit_Cost INT,
    Days_In_Storage INT
);
GO

-- Active payroll roster for sales representatives
CREATE TABLE Active_Roster (
    Rep_Name VARCHAR(50) PRIMARY KEY,
    Region VARCHAR(50),
    Base_Salary INT
);
GO

-- Sales transaction records for commissions
CREATE TABLE Sales_Ledger (
    Transaction_ID INT PRIMARY KEY,
    Sales_Rep_Name VARCHAR(50),
    Deal_Amount INT,
    Contract_Status VARCHAR(50)
);
GO

-- Master list of medical procedures and allowed insurance caps
CREATE TABLE Procedure_Master (
    Proc_Code VARCHAR(10) PRIMARY KEY,
    Category VARCHAR(50),
    Max_Allowed_Amount INT
);
GO

-- Insurance claims ledger
CREATE TABLE Claims_Ledger (
    Claim_ID INT PRIMARY KEY,
    Patient_ID INT,
    Procedure_Code VARCHAR(10),
    Billed_Amount INT,
    Approval_Status VARCHAR(50)
);
GO


-- =========================================================================
-- DATABASE 2: AlNoorTrading (Core Enterprise Star Schema)
-- =========================================================================

USE master;
GO

-- Safely recreate AlNoorTrading database to avoid deployment conflicts
DROP DATABASE IF EXISTS AlNoorTrading;
GO

CREATE DATABASE AlNoorTrading;
GO

USE AlNoorTrading;
GO

-- Ensure clean schema recreation
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_employees;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS fact_sales;
GO

-- Customer master directory
CREATE TABLE dim_customers (
    customer_id     INT PRIMARY KEY,
    customer_name   VARCHAR(100),
    city            VARCHAR(50),
    customer_type   VARCHAR(20),  -- 'Retail' or 'Wholesale'
    credit_limit    DECIMAL(10,2)
);

-- Employee payroll directory
CREATE TABLE dim_employees (
    employee_id     INT PRIMARY KEY,
    employee_name   VARCHAR(100),
    department      VARCHAR(50),
    job_title       VARCHAR(50),
    hire_date       DATE,
    salary          DECIMAL(10,2)
);

-- Product catalog directory
CREATE TABLE dim_products (
    product_id      INT PRIMARY KEY,
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    unit_cost       DECIMAL(10,2),
    unit_price      DECIMAL(10,2)
);

-- Central sales transaction fact table
CREATE TABLE fact_sales (
    sale_id         INT PRIMARY KEY,
    sale_date       DATE,
    customer_id     INT,
    employee_id     INT,
    product_id      INT,
    quantity        INT,
    discount_pct    DECIMAL(4,2),
    is_returned     VARCHAR(3)  -- 'Yes' or 'No'
);
GO
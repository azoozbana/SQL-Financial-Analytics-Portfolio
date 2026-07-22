/* ============================================================
   01_Create_Tables.sql
   ------------------------------------------------------------
   Sets up two separate practice databases:

   1. FinancePractice - a looser staging/playground schema, used 
      for one-off audit scenarios (expenses, payroll, insurance 
      claims, sales commissions). No FK constraints here on 
      purpose - built for quick, flexible audit testing.

   2. AlNoorTrading - the main portfolio database, a proper star 
      schema (fact_sales + three dimension tables) with real 
      FK constraints enforcing referential integrity.
   ============================================================ */


-- =========================================================================
-- DATABASE 1: FinancePractice (Staging & Practice Playground)
-- =========================================================================

USE FinancePractice;
GO

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

-- Company expense transactions by department
CREATE TABLE Company_Expenses (
    Transaction_ID INT IDENTITY(1,1) PRIMARY KEY,
    Expense_Date DATE,
    Department VARCHAR(50),
    Category VARCHAR(50),
    Amount DECIMAL(10, 2)
);
GO

-- Corporate general ledger, with who approved each entry
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

-- Which manager owns which department
CREATE TABLE Department_Directory (
    Department VARCHAR(50),
    Manager_Name VARCHAR(50)
);
GO

-- Approved supplier list
CREATE TABLE Approved_Vendors (
    Vendor_Code INT PRIMARY KEY,
    Vendor_Name VARCHAR(50)
);
GO

-- Standard cost reference sheet, used to catch invoices billed 
-- above the agreed price
CREATE TABLE Price_Master (
    Item_Name VARCHAR(50) PRIMARY KEY,
    Standard_Cost INT
);
GO

-- Warehouse stock, including how long each item has been sitting - 
-- useful for flagging aging/dead inventory
CREATE TABLE Inventory_Stock (
    Item_ID INT PRIMARY KEY,
    Item_Name VARCHAR(50),
    Category VARCHAR(50),
    Unit_Cost INT,
    Days_In_Storage INT
);
GO

-- Active sales reps and their base salary, used for commission audits
CREATE TABLE Active_Roster (
    Rep_Name VARCHAR(50) PRIMARY KEY,
    Region VARCHAR(50),
    Base_Salary INT
);
GO

-- Sales deals booked, with contract status (Draft/Active/Cancelled etc.)
CREATE TABLE Sales_Ledger (
    Transaction_ID INT PRIMARY KEY,
    Sales_Rep_Name VARCHAR(50),
    Deal_Amount INT,
    Contract_Status VARCHAR(50)
);
GO

-- Medical procedure codes and the maximum insurance will pay per procedure
CREATE TABLE Procedure_Master (
    Proc_Code VARCHAR(10) PRIMARY KEY,
    Category VARCHAR(50),
    Max_Allowed_Amount INT
);
GO

-- Insurance claims submitted against those procedures
CREATE TABLE Claims_Ledger (
    Claim_ID INT PRIMARY KEY,
    Patient_ID INT,
    Procedure_Code VARCHAR(10),
    Billed_Amount INT,
    Approval_Status VARCHAR(50)
);
GO


-- =========================================================================
-- DATABASE 2: AlNoorTrading (Core Star Schema)
-- =========================================================================

USE master;
GO

-- Full rebuild every run - fine for a practice/portfolio database
DROP DATABASE IF EXISTS AlNoorTrading;
GO

CREATE DATABASE AlNoorTrading;
GO

USE AlNoorTrading;
GO

-- fact_sales dropped first since FK constraints reference the 
-- dimension tables - SQL Server won't drop a table something 
-- else still points to
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_employees;
DROP TABLE IF EXISTS dim_products;
GO

-- Customer master directory
CREATE TABLE dim_customers (
    customer_id     INT PRIMARY KEY,
    customer_name   VARCHAR(100),
    city            VARCHAR(50),
    customer_type   VARCHAR(20),  -- 'Retail' or 'Wholesale'
    credit_limit    DECIMAL(10,2)
);
GO

-- Employee/payroll directory
CREATE TABLE dim_employees (
    employee_id     INT PRIMARY KEY,
    employee_name   VARCHAR(100),
    department      VARCHAR(50),
    job_title       VARCHAR(50),
    hire_date       DATE,
    salary          DECIMAL(10,2)
);
GO

-- Product catalog
CREATE TABLE dim_products (
    product_id      INT PRIMARY KEY,
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    unit_cost       DECIMAL(10,2),
    unit_price      DECIMAL(10,2)
);
GO

-- Central sales fact table - one row per line item sold.
-- FK constraints ensure the database itself rejects a sale pointing 
-- to a customer/employee/product that doesn't exist.
CREATE TABLE fact_sales (
    sale_id         INT PRIMARY KEY,
    sale_date       DATE,
    customer_id     INT NULL,
    employee_id     INT NULL,
    product_id      INT NOT NULL,
    quantity        INT,
    discount_pct    DECIMAL(4,2),
    is_returned     VARCHAR(3),  -- 'Yes' or 'No'

    CONSTRAINT FK_fact_sales_customer 
        FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT FK_fact_sales_employee 
        FOREIGN KEY (employee_id) REFERENCES dim_employees(employee_id),
    CONSTRAINT FK_fact_sales_product 
        FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);
GO
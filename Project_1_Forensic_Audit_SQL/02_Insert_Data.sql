-- =========================================================================
-- DATABASE 1: FinancePractice (Staging & Practice Data)
-- =========================================================================

USE FinancePractice;
GO

-- Staging expense records for departmental audits
INSERT INTO Company_Expenses (Expense_Date, Department, Category, Amount)
VALUES 
('2026-05-01', 'Marketing', 'Software Subscription', 1200.00),
('2026-05-03', 'Finance', 'Consulting Fees', 5000.00),
('2026-05-15', 'Sales', 'Travel & Lodging', 850.50),
('2026-05-20', 'Marketing', 'Online Advertising', 3500.00),
('2026-05-22', 'HR', 'Employee Training', 1500.00);
GO

-- Transactional general ledger entries for approval testing
INSERT INTO Corporate_Ledger (Invoice_ID, Post_Date, Vendor, Department, Amount, Approved_By)
VALUES 
(1001, '2026-06-01', 'CloudSync SaaS', 'IT', 4500.00, 'Sarah King'),
(1002, '2026-06-01', 'Office Depot', 'HR', 250.50, 'John Doe'),
(1003, '2026-06-02', 'Global Logistics', 'Operations', 12500.00, 'Sarah King'),
(1004, '2026-06-03', 'Downtown Catering', 'Marketing', 850.00, 'Alex Wong'),
(1005, '2026-06-04', 'AWS Cloud Hosting', 'IT', 8900.00, 'Sarah King'),
(1006, '2026-06-05', 'Elite Consultants', 'Finance', 15000.00, 'Michael Chang'),
(1007, '2026-06-07', 'Luxury Hotel & Spa', 'Marketing', 9500.00, 'Alex Wong'),
(1008, '2026-06-08', 'Staples Paper', 'HR', 120.00, 'John Doe'),
(1009, '2026-06-09', 'Global Logistics', 'Operations', 12500.00, 'Sarah King'),
(1010, '2026-06-10', 'Adobe Suite Creative', 'Marketing', 1200.00, 'Alex Wong'),
(1011, '2026-06-11', 'Main Street Landlord', 'Finance', 6000.00, 'Michael Chang'),
(1012, '2026-06-12', 'QuickPrint Flyers', 'Marketing', 450.00, 'Alex Wong'),
(1013, '2026-06-14', 'CEO Personal Flight', 'Executive', 25000.00, 'John Doe'),
(1014, '2026-06-15', 'AWS Cloud Hosting', 'IT', 8900.00, 'Sarah King');
GO

-- Dynamic department-to-manager directories
INSERT INTO Department_Directory (Department, Manager_Name)
VALUES 
('Human Resources', 'Sarah Al-Otaibi'),
('Finance', 'Ahmed Mansoor'),
('Operations', 'Tariq Abdulaziz');
GO

-- Audit Test: Intentionally inserting unmapped or unapproved records to test validation
INSERT INTO Corporate_Ledger (Invoice_ID, Department, Amount)
VALUES (999, 'Marketing', 42000);

INSERT INTO Department_Directory (Department, Manager_Name)
VALUES 
('Executive', 'Waleed Ahmad'),
('IT', 'Khaled Saleh'),
('Marketing', 'Abdullah Yahya');

INSERT INTO Corporate_Ledger (Invoice_ID, Department, Amount)
VALUES (105, 'Finance', 1500);

INSERT INTO Corporate_Ledger (Invoice_ID, Amount, Approved_By)
VALUES (111, 45000, 'windy');
GO

-- Whitelisted corporate vendor directory
INSERT INTO Approved_Vendors (Vendor_Code, Vendor_Name)
VALUES 
(1001, 'Apex Office Supplies'),
(1002, 'Global Logistics Corp'),
(1003, 'Prime Utilities');
GO

-- Item standard cost catalog
INSERT INTO Price_Master (Item_Name, Standard_Cost)
VALUES 
('Industrial Generator', 12000),
('Server Rack v2', 4500),
('Office Desk', 300);
GO

-- Warehouse inventory status (includes intentionally unmapped products for audit testing)
INSERT INTO Inventory_Stock (Item_ID, Item_Name, Category, Unit_Cost, Days_In_Storage)
VALUES 
(101, 'Industrial Generator', 'Heavy Equipment', 12000, 400),
(102, 'Server Rack v2', 'IT Hardware', 4500, 200),
(103, 'Mystery Widget X', 'Electronics', 750, 45),   -- unmapped in Price_Master, on purpose
(104, 'Forklift Battery', NULL, 900, 15),             -- category deliberately left NULL
(105, 'Premium Apples', 'Perishables', 600, 10);      -- perishable stock, aging test case
GO

-- Active payroll roster
INSERT INTO Active_Roster (Rep_Name, Region, Base_Salary)
VALUES 
('Ahmed Mansoor', 'Middle East', 8000),
('Sarah Smith', 'Europe', 9500),
('John Doe', 'North America', 7000);
GO

-- Sales contract records (includes unmapped reps and inactive states for audit testing)
INSERT INTO Sales_Ledger (Transaction_ID, Sales_Rep_Name, Deal_Amount, Contract_Status)
VALUES 
(501, 'Ahmed Mansoor', 65000, 'Approved'),   -- active, valid regional contract
(502, 'Ahmed Mansoor', 12000, 'Draft'),      -- active, but unapproved state
(503, 'Sarah Smith', 45000, 'Approved'),     -- non-ME region, should filter out
(504, 'Ghost Employee', 15000, 'Approved'),  -- rep not on Active Roster, on purpose
(505, 'John Doe', 25000, 'Approved'),        -- standard clean transaction
(506, 'John Doe', 4000, 'Approved');         -- active, but under the $10k audit threshold
GO

-- Medical procedures master index
INSERT INTO Procedure_Master (Proc_Code, Category, Max_Allowed_Amount)
VALUES 
('99213', 'Outpatient Visit', 250),
('33533', 'Cardiology Surgery', 15000),
('70551', 'MRI Scan', 1200);
GO

-- Health insurance claims records (includes over-limit and denied codes for audit testing)
INSERT INTO Claims_Ledger (Claim_ID, Patient_ID, Procedure_Code, Billed_Amount, Approval_Status)
VALUES 
(801, 1001, '33533', 18000, 'Approved'),    -- over max limit ($18k > $15k)
(802, 1002, '99213', 200, 'Denied'),        -- denied status, risk case
(803, 1003, '99999', 450, 'Approved'),      -- unindexed procedure code, on purpose
(804, 1004, '70551', 1100, 'Cancelled'),    -- cancelled state, should filter out
(805, 1005, '70551', 1300, 'Approved'),     -- over max limit ($1.3k > $1.2k)
(806, 1006, '99213', 150, 'Approved');      -- standard compliant transaction
GO


-- =========================================================================
-- DATABASE 2: AlNoorTrading (Core Star Schema)
-- =========================================================================

USE AlNoorTrading;
GO

-- Master customer records
INSERT INTO dim_customers (customer_id, customer_name, city, customer_type, credit_limit)
VALUES 
(1, 'Al-Rajhi Supplies', 'Riyadh', 'Wholesale', 100000),
(2, 'Al-Jazirah Furniture', 'Jeddah', 'Wholesale', 80000),
(3, 'Fatima Al-Otaibi', 'Riyadh', 'Retail', 5000),
(4, 'Khalid Trading Est', 'Dammam', 'Wholesale', 60000),
(5, 'Noura Al-Harbi', 'Jeddah', 'Retail', 3000),
(6, 'Al-Othaim Markets', 'Riyadh', 'Wholesale', 120000),
(7, 'Sara Al-Qahtani', 'Mecca', 'Retail', 4000),
(8, 'Saad Office Solutions', 'Dammam', 'Wholesale', 70000),
(9, 'Saudi National Logistics', 'Riyadh', 'Wholesale', 150000);
GO

-- Employee directory (includes a NULL name on purpose, for audit testing)
INSERT INTO dim_employees (employee_id, employee_name, department, job_title, hire_date, salary)
VALUES 
(1, 'Abdullah Al-Saud', 'Sales', 'Sales Manager', '2021-03-01', 12000),
(2, 'Mona Al-Ghamdi', 'Sales', 'Sales Rep', '2022-06-15', 7000),
(3, 'Yousef Al-Dosari', 'Sales', 'Sales Rep', '2023-01-10', 6500),
(4, 'Layla Al-Zahrani', 'Finance', 'Accountant', '2020-09-01', 9000),
(5, 'Omar Al-Subaie', 'Sales', 'Sales Rep', '2023-08-20', 6000),
(6, NULL, 'Sales', 'Sales Rep', '2024-01-05', 5500);
GO

-- Core product catalog
INSERT INTO dim_products (product_id, product_name, category, unit_cost, unit_price)
VALUES 
(1, 'Office Chair', 'Furniture', 200, 350),
(2, 'Office Desk', 'Furniture', 400, 700),
(3, 'Bookshelf', 'Furniture', 150, 280),
(4, 'Laptop Stand', 'Accessories', 30, 60),
(5, 'Desk Lamp', 'Accessories', 25, 50),
(6, 'Filing Cabinet', 'Furniture', 180, 320),
(7, 'Monitor Arm', 'Accessories', 40, 85),
(8, 'Whiteboard', 'Office Supplies', 60, 110);
GO

-- Central sales transaction ledger
INSERT INTO fact_sales (sale_id, sale_date, customer_id, employee_id, product_id, quantity, discount_pct, is_returned)
VALUES 
(1, '2024-01-05', 1, 1, 1, 10, 0.10, 'No'),
(2, '2024-01-08', 2, 2, 2, 5, 0.05, 'No'),
(3, '2024-01-12', 3, 2, 4, 2, 0.00, 'No'),
(4, '2024-01-15', 4, 1, 3, 8, 0.15, 'Yes'),   -- returned transaction
(5, '2024-01-20', 1, 3, 5, 15, 0.00, 'No'),
(6, '2024-02-02', 5, 2, 1, 3, 0.00, 'No'),
(7, '2024-02-05', 6, 1, 2, 12, 0.20, 'No'),
(8, '2024-02-10', 2, 5, 6, 4, 0.10, 'No'),
(9, '2024-02-14', 7, 3, 4, 6, 0.00, 'Yes'),   -- returned transaction
(10, '2024-02-18', 8, 1, 7, 9, 0.05, 'No'),
(11, '2024-03-01', 1, 2, 8, 20, 0.00, 'No'),
(12, '2024-03-05', 3, 3, 1, 7, 0.25, 'No'),
(13, '2024-03-10', 4, 5, 2, 3, 0.00, 'No'),
(14, '2024-03-15', NULL, 1, 5, 10, 0.10, 'No'),  -- unassigned customer, on purpose
(15, '2024-03-20', 6, 2, 3, 5, 0.00, 'Yes'),   -- returned transaction
(16, '2024-04-02', 2, 6, 6, 8, 0.15, 'No'),
(17, '2024-04-08', 5, 3, 7, 4, 0.00, 'No'),
(18, '2024-04-12', 7, 1, 8, 25, 0.05, 'No'),
(19, '2024-04-18', 8, 2, 1, 6, 0.00, 'No'),
(20, '2024-04-25', 1, 5, 4, 12, 0.20, 'No');
GO
######## Prepare data

# Create database
CREATE DATABASE Supplychain;

# Create 7 tables: 2 fact table, 5 dimension table
USE Supplychain;

#1. Create dim_customers table
CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    address VARCHAR(200),
    contract_type VARCHAR(50)
);

#2. Create dim_products table
CREATE TABLE dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_name VARCHAR(50),
    supplier_name VARCHAR(100),
    unit_price DECIMAL(10, 2),
    carrying_cost_per_unit DECIMAL(10, 2)
);

#3. Create dim_warehouses table
CREATE TABLE dim_warehouses (
    warehouse_id VARCHAR(10) PRIMARY KEY,
    warehouse_name VARCHAR(50),
    location_city VARCHAR(50),
    location_country VARCHAR(50),
    capacity INT,
    warehouse_type VARCHAR(50) 
);

#4. Create dim_shipments table
CREATE TABLE dim_shipments (
    shipment_id INT PRIMARY KEY,
    carrier_name VARCHAR(50),
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    shipment_cost DECIMAL(10, 2),
    tracking_number VARCHAR(50)
);

#5. Create dim_suppliers table
CREATE TABLE dim_suppliers (
    supplier_id VARCHAR(10) PRIMARY KEY,
    supplier_name VARCHAR(100),
    address VARCHAR(200), 
    credit_terms VARCHAR(50),
    priority_level INT
);

#6. Create dim_raw_product table
CREATE TABLE dim_raw_product (
    raw_product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category_name VARCHAR(255),
    raw_price DECIMAL(10, 2)
);

#7. Create fact_sales table
CREATE TABLE fact_sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    customer_id INT,
    product_id INT,
    warehouse_id VARCHAR(10),
    shipment_id INT,
    quantity INT,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES dim_warehouses(warehouse_id),
    FOREIGN KEY (shipment_id) REFERENCES dim_shipments(shipment_id)
);

#8. Create fact_purchasing_order
CREATE TABLE fact_purchasing_order (
    purchase_order_id INT PRIMARY KEY,
    purchase_order_date DATE,
    supplier_id VARCHAR(10),
    product_id INT,
    warehouse_id VARCHAR(10),
    quantity INT,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (supplier_id) REFERENCES dim_suppliers(supplier_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES dim_warehouses(warehouse_id)
);

#Delete the total_amount column in fact_sales
ALTER TABLE fact_sales
DROP COLUMN total_amount;

#Delete the total_amount column in fact_purchasing_order
ALTER TABLE fact_purchasing_order
DROP COLUMN total_amount;

#Delete the unit_price column in fact_purchasing_order
ALTER TABLE fact_purchasing_order
DROP COLUMN unit_price;

#Create Trigger(1) for fact_sales
DELIMITER $$

CREATE TRIGGER before_insert_fact_sales
BEFORE INSERT ON fact_sales
FOR EACH ROW
BEGIN
-- Check if quantity <= 0
    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid number (has to be larger than 0)';
    END IF;
    
-- Check if sale_date is in the future
    IF NEW.sale_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sale date must not be in the future';
    END IF;
END $$
DELIMITER ;

#Test Trigger(1)
INSERT INTO fact_sales (
	sale_id, 
    sale_date, 
    customer_id, 
    product_id, 
    warehouse_id, 
    shipment_id, 
    quantity
)
VALUES (249999, '2024-01-11', 2, 6002, 'WH02', 1500, 0);

#Create Trigger(2) for fact_purchasing_order
DROP TRIGGER IF EXISTS before_insert_fact_purchasing_order;
DELIMITER $$

CREATE TRIGGER before_insert_fact_purchasing_order
BEFORE INSERT ON fact_purchasing_order
FOR EACH ROW
BEGIN
    -- Check if quantity <= 0 
    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid number (has to be larger than 0)';
    END IF;
    
    -- Check if purchase_order_date is in the future
    IF NEW.purchase_order_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Purchase order date cannot be in the future';
    END IF;
    
    -- Check if warehouse's type is "raw_material"
    IF NOT EXISTS (
        SELECT 1
        FROM dim_warehouses
        WHERE warehouse_id = NEW.warehouse_id
        AND warehouse_type = 'raw_material'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid warehouse type. It must be "raw_material"';
    END IF;
END $$
DELIMITER ;

#Test Trigger(2)
INSERT INTO fact_purchasing_order (
	purchase_order_id, 
    purchase_order_date, 
    supplier_id, 
    product_id, 
    warehouse_id,
    quantity
)
VALUES
(8300, '2024-01-06', 'SL02', 6006, 'WH02', 150),  
(9007, '2024-01-07', 'SL06', 6007, 'WH03', 500); 


# Change foreign key in fact_purchasing_order
ALTER TABLE fact_purchasing_order
DROP FOREIGN KEY fact_purchasing_order_ibfk_2;

# Insert into fact_purchasing_order
INSERT INTO fact_purchasing_order (
	purchase_order_id, 
    purchase_order_date, 
    supplier_id, 
    product_id, 
    warehouse_id, 
    quantity
)
VALUES
    (8241, '2024-05-30', 'SL16', 6041, 'WH02', 140),
    (8242, '2024-06-20', 'SL20', 6042, 'WH04', 200),
    (8243, '2024-07-10', 'SL02', 6043, 'WH06', 170),
    (8244, '2024-08-15', 'SL05', 6044, 'WH08', 160),
    (8245, '2024-09-25', 'SL08', 6045, 'WH10', 180),
    (8246, '2024-10-15', 'SL10', 6046, 'WH02', 120),
    (8247, '2024-11-20', 'SL16', 6047, 'WH04', 150),
    (8248, '2024-12-10', 'SL20', 6048, 'WH06', 130),
    (8249, '2024-01-15', 'SL02', 6049, 'WH08', 140),
    (8250, '2024-02-05', 'SL05', 6050, 'WH10', 160),
    (8291, '2024-05-18', 'SL16', 6041, 'WH02', 170),
    (8292, '2024-06-06', 'SL20', 6042, 'WH04', 180),
    (8293, '2024-07-19', 'SL02', 6043, 'WH06', 150),
    (8294, '2024-08-01', 'SL05', 6044, 'WH08', 140),
    (8295, '2024-09-12', 'SL08', 6045, 'WH10', 120),
    (8336, '2024-05-03', 'SL17', 6041, 'WH02', 180),
    (8337, '2024-06-22', 'SL19', 6042, 'WH04', 150),
    (8338, '2024-07-18', 'SL04', 6043, 'WH06', 140),
    (8339, '2024-08-29', 'SL06', 6044, 'WH08', 130);








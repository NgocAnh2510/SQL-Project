USE supplychain;

#1.	Sales revenue and profit
#a. By customer
#a.1. By each customer
CREATE VIEW v_sales_by_customer AS
SELECT 
    dc.customer_name,
    -- revenue = quantity * unit price
    SUM(fs.quantity * dp.unit_price) AS total_revenue,  
    -- profit = revenue - carrying_cost_per_unit - raw_price
    SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit  
FROM 
    fact_sales fs
JOIN 
    dim_customers dc ON fs.customer_id = dc.customer_id
JOIN 
    dim_products dp ON fs.product_id = dp.product_id
LEFT JOIN 
-- join with dim_raw_product table to get the raw price
    dim_raw_product dr ON dp.product_name = dr.product_name  
GROUP BY 
    dc.customer_name
ORDER BY 
    total_revenue DESC;
-- Call the view
SELECT * from v_sales_by_customer
ORDER BY total_revenue DESC, profit DESC;

#a.2. By contract type
CREATE VIEW v_sales_by_contract_type AS
SELECT 
    dc.contract_type,
    -- revenue = quantity * unit_price
    SUM(fs.quantity * dp.unit_price) AS total_revenue,
    -- profit = revenue - carrying_cost_per_unit - raw_price
    SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit
FROM 
    fact_sales fs
JOIN 
	-- join with dim_customers to get contract_type
    dim_customers dc ON fs.customer_id = dc.customer_id  
JOIN 
    dim_products dp ON fs.product_id = dp.product_id
LEFT JOIN 
	-- join with dim_raw_product to get raw price
    dim_raw_product dr ON dp.product_name = dr.product_name  
GROUP BY 
    dc.contract_type
ORDER BY 
    total_revenue DESC;
-- Call the view
SELECT * from v_sales_by_contract_type
ORDER BY total_revenue DESC, profit DESC;

#b. By product
#b.1. By product name
CREATE VIEW v_sales_by_product_name AS
SELECT 
    dp.product_name,
    -- revenue = quantity * unit_price
    SUM(fs.quantity * dp.unit_price) AS total_revenue, 
    -- profit = revenue - carrying_cost_per_unit - raw_price
    SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit
FROM 
    fact_sales fs
JOIN 
    dim_products dp ON fs.product_id = dp.product_id
JOIN 
	-- join with dim_raw_product to get raw price
    dim_raw_product dr ON dp.product_name = dr.product_name
GROUP BY 
    dp.product_name
ORDER BY 
    total_revenue DESC;
-- Call the view
SELECT * from v_sales_by_product_name
ORDER BY total_revenue DESC, profit DESC;

#b.2. By product category
CREATE VIEW v_sales_by_product_category AS
SELECT 
    dp.category_name,
    -- revenue = quantity * unit_price
    SUM(fs.quantity * dp.unit_price) AS total_revenue, 
    -- profit = revenue - carrying_cost_per_unit - raw_price
    SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit
FROM 
    fact_sales fs
JOIN 
    dim_products dp ON fs.product_id = dp.product_id
JOIN 
	-- join with dim_raw_product to get raw price
    dim_raw_product dr ON dp.product_name = dr.product_name
GROUP BY 
    dp.category_name
ORDER BY 
    total_revenue DESC;
-- Call the view
SELECT * from v_sales_by_product_category
ORDER BY total_revenue DESC, profit DESC;

#c. By time (Create stored procedures)
#c.1. By product
DELIMITER $$

CREATE PROCEDURE sp_sales_by_time(IN year INT, IN quarter INT, IN month INT)
BEGIN
    SELECT 
        dp.product_name,
        -- revenue = quantity * unit_price
        SUM(fs.quantity * dp.unit_price) AS total_revenue, 
        -- profit = revenue - carrying_cost_per_unit - raw_price
        SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit
    FROM 
        fact_sales fs
    JOIN 
        dim_products dp ON fs.product_id = dp.product_id
    JOIN 
        -- join with dim_raw_product to get raw price
        dim_raw_product dr ON dp.product_name = dr.product_name
    WHERE 
        YEAR(fs.sale_date) = year -- Filter by year
        AND (quarter = 0 OR QUARTER(fs.sale_date) = quarter) -- Filter by quarter
        AND (month = 0 OR MONTH(fs.sale_date) = month) -- Filter by month
    GROUP BY 
        dp.product_name 
    ORDER BY 
        total_revenue DESC;
END $$

DELIMITER ;
-- Call the stored procedures
-- Filter by year and quarter
CALL sp_sales_by_time(2024, 0, 0);

#c.2. Total
DELIMITER $$

CREATE PROCEDURE sp_total_revenue_by_time(IN year INT, IN quarter INT, IN month INT)
BEGIN
    SELECT 
        SUM(fs.quantity * dp.unit_price) AS total_revenue,
		SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit
    FROM 
        fact_sales fs
    JOIN 
        dim_products dp ON fs.product_id = dp.product_id
	JOIN 
        dim_raw_product dr ON dp.product_name = dr.product_name
    WHERE 
        YEAR(fs.sale_date) = year 
        AND (quarter = 0 OR QUARTER(fs.sale_date) = quarter) 
        AND (month = 0 OR MONTH(fs.sale_date) = month);
END $$

DELIMITER ;
-- Call the stored procedures
CALL sp_total_revenue_by_time(2024, 4, 0); -- Calculate total revenue and profit of 2024

#d. By warehouse
CREATE VIEW v_sales_by_warehouse AS
SELECT 
    dw.warehouse_name,
    SUM(fs.quantity * dp.unit_price) AS total_revenue,
    SUM(fs.quantity * (dp.unit_price - dp.carrying_cost_per_unit - COALESCE(dr.raw_price, 0))) AS profit
FROM 
    fact_sales fs
JOIN 
    dim_warehouses dw ON fs.warehouse_id = dw.warehouse_id
JOIN 
    dim_products dp ON fs.product_id = dp.product_id
LEFT JOIN 
    dim_raw_product dr ON dp.product_name = dr.product_name
GROUP BY 
    dw.warehouse_name
ORDER BY 
    total_revenue DESC;
-- Call the view
SELECT * FROM v_sales_by_warehouse
ORDER BY total_revenue DESC, profit DESC;


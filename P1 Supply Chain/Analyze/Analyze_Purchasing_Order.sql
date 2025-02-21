USE supplychain;

#1. By supplier
#1.1. Analyze purchasing order by supplier
SELECT 
    ds.supplier_name,
    SUM(po.quantity * dr.raw_price) AS total_order_value,
    COUNT(po.purchase_order_id) AS order_count
FROM 
    fact_purchasing_order po
JOIN 
    dim_suppliers ds ON po.supplier_id = ds.supplier_id
JOIN 
    dim_raw_product dr ON po.product_id = dr.raw_product_id 
GROUP BY 
    ds.supplier_name
ORDER BY 
    total_order_value DESC; 
    
#1.2. By priority_level
SELECT 
    ds.priority_level,
    SUM(po.quantity * dr.raw_price) AS total_order_value,
    COUNT(po.purchase_order_id) AS order_count
FROM 
    fact_purchasing_order po
JOIN 
    dim_suppliers ds ON po.supplier_id = ds.supplier_id
JOIN 
    dim_raw_product dr ON po.product_id = dr.raw_product_id 
GROUP BY 
    ds.priority_level
ORDER BY 
    total_order_value DESC;

#1.3. Purchasing order by credit term
SELECT 
    ds.credit_terms,
    SUM(po.quantity) AS total_quantity_ordered,
    SUM(po.quantity * dr.raw_price) AS total_order_value
FROM 
    fact_purchasing_order po
JOIN 
    dim_suppliers ds ON po.supplier_id = ds.supplier_id
JOIN
    dim_raw_product dr ON po.product_id = dr.raw_product_id  
GROUP BY 
    ds.credit_terms
ORDER BY 
    total_order_value DESC;

#2. By product
#2.1. By categor
SELECT 
    dp.category_name,  
    SUM(po.quantity) AS total_quantity_ordered,
    SUM(po.quantity * dr.raw_price) AS total_order_value
FROM 
    fact_purchasing_order po
JOIN 
    dim_products dp ON po.product_id = dp.product_id
JOIN 
    dim_raw_product dr ON po.product_id = dr.raw_product_id 
GROUP BY 
    dp.category_name  
ORDER BY 
    total_order_value DESC;

#2.2. By each product
SELECT 
    dp.product_name,
    SUM(po.quantity) AS total_quantity_ordered,
    SUM(po.quantity * dr.raw_price) AS total_order_value
FROM 
    fact_purchasing_order po
JOIN 
    dim_products dp ON po.product_id = dp.product_id
JOIN 
    dim_raw_product dr ON po.product_id = dr.raw_product_id 
GROUP BY 
    dp.product_name
ORDER BY 
    total_order_value DESC;
#2.3. Find the product ordered but not still sold
SELECT 
    po.product_id,
    SUM(po.quantity) AS total_quantity_ordered,
    SUM(po.quantity * IFNULL(dr.raw_price, 0)) AS total_order_value, 
    -- The first time of order
    MIN(po.purchase_order_date) AS first_order_date  
FROM 
    fact_purchasing_order po
LEFT JOIN 
    dim_products dp ON po.product_id = dp.product_id
LEFT JOIN 
    dim_raw_product dr ON po.product_id = dr.raw_product_id  
WHERE 
    dp.product_id IS NULL  
GROUP BY 
    po.product_id
ORDER BY 
    total_order_value DESC;

#3. By time
#3.1. By each product
DELIMITER $$

CREATE PROCEDURE sp_purchasing_order_by_time(IN year INT, IN quarter INT, IN month INT)
BEGIN
    SELECT 
        dp.product_name,
        SUM(po.quantity) AS total_quantity_ordered,
        SUM(po.quantity * dr.raw_price) AS total_order_value
    FROM 
        fact_purchasing_order po
    JOIN 
        dim_products dp ON po.product_id = dp.product_id
    LEFT JOIN 
        dim_raw_product dr ON po.product_id = dr.raw_product_id
    WHERE 
        YEAR(po.purchase_order_date) = year
        AND (quarter = 0 OR QUARTER(po.purchase_order_date) = quarter)
        AND (month = 0 OR MONTH(po.purchase_order_date) = month)  
    GROUP BY 
        dp.product_name
    ORDER BY 
        total_order_value DESC;
END $$

DELIMITER ;
# Call the stored procedures
CALL sp_purchasing_order_by_time(2024, 1, 3);

#3.2. Total
DELIMITER $$

CREATE PROCEDURE sp_total_order_by_time(
    IN year INT, 
    IN quarter INT, 
    IN month INT
)
BEGIN
    SELECT 
        SUM(po.quantity) AS total_quantity_ordered,
        SUM(po.quantity * dr.raw_price) AS total_order_value
    FROM 
        fact_purchasing_order po
    LEFT JOIN 
        dim_raw_product dr ON po.product_id = dr.raw_product_id
    WHERE 
        YEAR(po.purchase_order_date) = year
        AND (quarter = 0 OR QUARTER(po.purchase_order_date) = quarter)
        AND (month = 0 OR MONTH(po.purchase_order_date) = month)
    ORDER BY 
        total_order_value DESC;
END $$

DELIMITER ;
-- Call the procedure
CALL sp_total_order_by_time(2024, 4, 0);


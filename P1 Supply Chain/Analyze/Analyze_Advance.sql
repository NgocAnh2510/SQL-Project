USE supplychain;

#1. Stock-out and Overstock Analysis
SELECT 
    dp.product_id,
    dp.product_name,
    IFNULL(order_table.total_ordered_quantity, 0) AS total_ordered_quantity,
    IFNULL(sales_table.total_sold_quantity, 0) AS total_sold_quantity,
    (IFNULL(order_table.total_ordered_quantity, 0) - IFNULL(sales_table.total_sold_quantity, 0)) AS stock_balance,
    CASE 
        WHEN IFNULL(order_table.total_ordered_quantity, 0) > IFNULL(sales_table.total_sold_quantity, 0) THEN 'Overstock'
        WHEN IFNULL(order_table.total_ordered_quantity, 0) = IFNULL(sales_table.total_sold_quantity, 0) THEN 'Balanced'
        ELSE 'Stock-out' 
    END AS stock_status
FROM 
    dim_products dp
LEFT JOIN 
    (
        SELECT 
            po.product_id,
            SUM(po.quantity) AS total_ordered_quantity
        FROM 
            fact_purchasing_order po
        GROUP BY 
            po.product_id
    ) AS order_table
    ON dp.product_id = order_table.product_id
LEFT JOIN 
    (
        SELECT 
            fs.product_id,
            SUM(fs.quantity) AS total_sold_quantity
        FROM 
            fact_sales fs
        GROUP BY 
            fs.product_id
    ) AS sales_table
    ON dp.product_id = sales_table.product_id
ORDER BY 
    stock_balance DESC;

#2. Demand Forecast
SELECT 
    dp.product_name,
    AVG(fs.quantity) AS average_sales_per_order,
    COUNT(fs.sale_id) AS total_orders_last_year,
    round(AVG(fs.quantity) * COUNT(fs.sale_id) * 1.2, 0) AS yearly_demand_forecast
FROM 
    fact_sales fs
JOIN 
    dim_products dp ON fs.product_id = dp.product_id
WHERE 
    YEAR(fs.sale_date) = YEAR(CURDATE()) - 1
GROUP BY 
    dp.product_name
ORDER BY 
    yearly_demand_forecast DESC;



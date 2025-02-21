USE supplychain;

#2.1. Shipping cost for each shipment
SELECT 
    ss.shipment_id,
    ss.carrier_name,
    ss.shipment_cost
FROM 
    dim_shipments ss
ORDER BY 
	ss.shipment_cost DESC;

#2.1. Total and average shipping cost by carrier
SELECT 
    ss.carrier_name, 
    -- Total shipping cost
    SUM(ss.shipment_cost) AS total_shipment_cost, 
    -- Average shipping cost by carrier
    SUM(ss.shipment_cost) / COUNT(ss.shipment_id) AS avg_shipment_cost_per_shipment 
FROM 
    dim_shipments ss
GROUP BY 
    ss.carrier_name
ORDER BY 
    total_shipment_cost DESC;

#2.1. Find total shipping cost of carrier by warehouse 
#(cause in SCM, the position of warehouse can affect the shipping cost. If
#the warehouse is located far away from carrier, the shipping cause will also be affected)
SELECT 
	ss.carrier_name,
    dw.warehouse_name,
    SUM(ss.shipment_cost) AS total_shipment_cost 
FROM 
    dim_shipments ss
JOIN 
    fact_sales fs ON ss.shipment_id = fs.shipment_id
JOIN 
    dim_warehouses dw ON fs.warehouse_id = dw.warehouse_id
GROUP BY 
    dw.warehouse_name, ss.carrier_name
ORDER BY 
    ss.carrier_name, total_shipment_cost DESC; 

#2.1. Shipping cost by customer
#(function)
DELIMITER //

CREATE FUNCTION calculate_total_shipment_cost(customer_id INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE total_cost DECIMAL(10, 2);

    -- Total cost
    SELECT COALESCE(SUM(ds.shipment_cost), 0) INTO total_cost
    FROM fact_sales fs
    JOIN dim_shipments ds ON fs.shipment_id = ds.shipment_id
    WHERE ds.actual_delivery_date IS NOT NULL
    AND (customer_id IS NULL OR fs.customer_id = customer_id);

    -- Output
    RETURN total_cost;
END //

DELIMITER ;

-- Call the function
SELECT calculate_total_shipment_cost(10);

#general
SELECT 
    fs.customer_id,
    COALESCE(SUM(ds.shipment_cost), 0) AS total_shipping_cost,
    COUNT(fs.sale_id) AS sales_count,
    SUM(fs.quantity) AS total_quantity,
    CASE
        WHEN COUNT(fs.sale_id) * SUM(fs.quantity) = 0 THEN 0
        ELSE SUM(ds.shipment_cost) / (COUNT(fs.sale_id) * SUM(fs.quantity))
    END AS average_shipping_cost
FROM 
    fact_sales fs
JOIN 
    dim_shipments ds ON fs.shipment_id = ds.shipment_id
WHERE 
    ds.actual_delivery_date IS NOT NULL
GROUP BY 
    fs.customer_id
ORDER BY average_shipping_cost DESC;
	

#2.2. date difference of each shipment (along with carrier) 
SELECT 
    ss.shipment_id,
    ss.carrier_name,
    ss.expected_delivery_date,
    ss.actual_delivery_date,
    DATEDIFF(ss.actual_delivery_date, ss.expected_delivery_date) AS delay_days
FROM 
    dim_shipments ss
WHERE 
    ss.actual_delivery_date > ss.expected_delivery_date
ORDER BY 
	delay_days DESC;

#2.2. Total and average delay time by carrier
SELECT 
    ss.carrier_name,
    -- Total delay time
    SUM(DATEDIFF(ss.actual_delivery_date, ss.expected_delivery_date)) AS total_delay_days, 
    -- Number of delayed shipments
    COUNT(ss.shipment_id) AS total_delayed_shipments, 
    -- Delay shipment ratio
	COUNT(ss.shipment_id) / (SELECT COUNT(*) FROM dim_shipments WHERE carrier_name = ss.carrier_name) * 100 AS delayed_shipment_percentage, 
    -- Averge delay time per shipment
    SUM(DATEDIFF(ss.actual_delivery_date, ss.expected_delivery_date)) / COUNT(ss.shipment_id) AS avg_delay_per_shipment 
FROM 
    dim_shipments ss
WHERE 
    ss.actual_delivery_date > ss.expected_delivery_date -- Filter delayed shipments
GROUP BY 
    ss.carrier_name
ORDER BY 
    total_delay_days DESC;

#2.2. Average delay time of carrier by warehouse
SELECT 
	ss.carrier_name,
    dw.warehouse_name,
    ROUND(AVG(DATEDIFF(ss.actual_delivery_date, ss.expected_delivery_date)), 2) AS avg_delay_days 
FROM 
    dim_shipments ss
JOIN 
    fact_sales fs ON ss.shipment_id = fs.shipment_id
JOIN 
    dim_warehouses dw ON fs.warehouse_id = dw.warehouse_id
WHERE 
    ss.actual_delivery_date > ss.expected_delivery_date 
GROUP BY 
    dw.warehouse_name, ss.carrier_name
ORDER BY 
    ss.carrier_name, avg_delay_days DESC; 




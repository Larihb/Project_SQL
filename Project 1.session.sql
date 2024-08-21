
-- INVENTORY OPTIMIZATION FOR MINT CLASSICS COMPANY 
/* Project Objective: The goal is to analyze Mint Classics Company's warehouse inventory and sales data to identify patterns, inefficiencies, and opportunities for optimization.
The main focus is to determine which warehouse should be closed and suggestions for reorganizing or reducing inventory, while still maintaining timely service to their customers. 

Database importation: The database was imported using MySQL Workbench's data import feature. This method ensured that all sample tables, relationships, and data were accurately imported to match the provided EER diagram.
*/
-- First to identify relevant tables for the problem: 
/* Description of Data: The data includes information on warehouses, product lines, products, orders, order details, customers, employess and offices.
The data is crucial for understanding inventory distribution, sales performance, and potential areas for optimization.*/

-- Warehouses / productlines / products / orders / orderdetail 
SELECT * FROM warehouses;
SELECT * FROM productlines;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM orderdetails;
SELECT * FROM customers;
SELECT * FROM offices;


-- SQL queries were used to explore the data and generate summary statistics to identify key patterns.

-- Products distibrution by warehouse and warehouse location
SELECT products.productName, warehouses.warehouseCode, warehouses.warehouseName
FROM products
JOIN warehouses ON products.warehouseCode = warehouses.warehouseCode;

/* Warehouse Utilization to see the number of products stored in them
warehouse D has the least amount of products.*/
SELECT warehouses.warehouseCode, warehouses.warehouseName,
	SUM(products.quantityInStock) AS totalProductsInWarehouse
FROM products
JOIN warehouses ON warehouses.warehouseCode = products.warehouseCode
GROUP BY warehouses.warehouseCode, warehouses.warehouseName;

-- Now I want to see the name of the products as well. For this I'm goin to use subqueries. Note that in this, it is impossible to see the total number of products, but I can see the warehouses and products's name.
SELECT warehouses.warehouseCode, 
    warehouses.warehouseName, 
    products.productName,
    products.quantityInStock
FROM products
JOIN warehouses ON warehouses.warehouseCode = products.warehouseCode
JOIN (
	SELECT warehouseCode,
		SUM(products.quantityInStock) AS numberOfProducts
	FROM products
    GROUP BY warehouseCode) counts ON products.warehouseCode = counts.warehouseCode;
    
    
-- The following exploration helped to understand the relationship between inventory levels and sales performance, especially in different warehouses. 
	
-- Sales Performance by Product. This can help to identify products that may be slow-moving // The one least sold is 1957 Ford Thunderbird
SELECT products.productCode, products.productName,
	SUM(orderdetails.quantityOrdered) AS totalQuantitySold
FROM products 
JOIN orderdetails ON orderdetails.productCode = products.productCode
GROUP BY products.productCode, products.productName
ORDER BY totalQuantitySold ASC
LIMIT 5;

-- Lets locate where is the least sold product is stored. It is in warehouse B 
SELECT products.productCode, products.productName, warehouses.warehouseName, warehouses.warehouseCode
FROM products 
JOIN warehouses ON warehouses.warehouseCode = products.warehouseCode
WHERE products.productCode = 'S18_4933';

-- Lets locate where is the most sold product is stored. It is in warehouse B 
SELECT products.productCode, products.productName, warehouses.warehouseName, warehouses.warehouseCode
FROM products 
JOIN warehouses ON warehouses.warehouseCode = products.warehouseCode
WHERE products.productCode = 'S18_3232';

-- Now I want to see where are the least 5 items sold. For this I'm goin to use a subquery. 3 out of 5 are from warehouse B 
SELECT products.productCode, products.productName, warehouses.warehouseName, warehouses.warehouseCode
FROM products 
JOIN warehouses ON warehouses.warehouseCode = products.warehouseCode
JOIN (
	SELECT products.productCode
    FROM products
    JOIN orderdetails ON orderdetails.productCode = products.productCode
    GROUP BY products.productCode
    ORDER BY SUM(orderdetails.quantityOrdered) ASC
    LIMIT 5
) AS least_sold_products ON products.productCode = least_sold_products.productCode;

-- Let's investigate the sales, are there stored itens that are not moving? This query is to find products with low or no sales. 
SELECT products.productCode, products.productName, products.quantityInStock,
	SUM(orderdetails.quantityOrdered) AS totalSold
FROM products
LEFT JOIN orderdetails ON orderdetails.productCode = products.productCode
GROUP BY products.productCode, products.productName
HAVING totalSold <= 850 OR totalSold IS NULL;

-- Inventory numbers relate to sales? Let's compare inventory levels to sales data to see if there's excess stock of certain products
SELECT products.productCode, products.productName, products.quantityInStock,
	SUM(orderdetails.quantityOrdered) AS totalSold
FROM products
LEFT JOIN orderdetails ON orderdetails.productCode = products.productCode
GROUP BY products.productCode, products.productName
ORDER BY totalSold DESC;
	-- With this we can identify products with high inventory but low sales. 

-- Lets locate where is the product with no sale stored // warehouse b.
SELECT products.productCode, products.productName, warehouses.warehouseName, warehouses.warehouseCode
FROM products 
JOIN warehouses ON warehouses.warehouseCode = products.warehouseCode
WHERE products.productCode = 'S18_3233';


-- Warehouse Utilization: Analysis of product distribution across warehouses to identify underperforming locations.
-- Sales Performance: Evaluation of total sales by warehouse and by product to identify slow-moving inventory and sales efficiency.

-- Identify Slow-Moving Inventory so it is possible to identify which warehouse can be a candidate to elimination.
/* Here we can see that Warehouse D has the shortest inventory, which can be cause of the low quantity sold.
Let's investigate more. */
SELECT warehouses.warehouseCode, warehouses.warehouseName,
	SUM(products.quantityInStock) AS totalInventory, 
    SUM(orderdetails.quantityOrdered) AS totalQuantitySold
FROM warehouses
JOIN products ON products.warehouseCode = warehouses.warehouseCode
LEFT JOIN orderdetails ON products.productCode = orderdetails.productCode
GROUP BY warehouses.warehouseCode, warehouses.warehouseName
ORDER BY totalQuantitySold ASC;

-- Let's see each warehouse sell the most products // It is the warehouse B. warehouse D is the one who don't sells much
SELECT warehouses.warehouseCode, warehouses.warehouseName, 
	SUM(orderdetails.quantityOrdered) AS totalQuantitySold
FROM warehouses
JOIN products ON products.warehouseCode = warehouses.warehouseCode
JOIN orderdetails ON orderdetails.productCode = products.productCode
GROUP BY warehouses.warehouseCode, warehouses.warehouseName
ORDER BY totalQuantitySold DESC;

-- Price vs. Sales
SELECT products.productCode, products.productName, products.MSRP,
	SUM(orderdetails.quantityOrdered) AS totalSold
FROM products
LEFT JOIN orderdetails ON orderdetails.productCode = products.productCode
GROUP BY products.productCode, products.productName, products.MSRP
ORDER BY products.MSRP DESC;


/* To the final analysis let's investigate de procentage of inventory and sell.
This way it is possible to analyze the performance of each warehouse. 
The warehouse that has the lowst performance is the warehouse B.
*/

-- 1. Warehouse performance, total sales.
SELECT warehouses.warehouseCode, warehouses.warehouseName,
	SUM(orderdetails.quantityOrdered) AS totalSold,
    SUM(products.quantityInStock) AS totalInventory
FROM warehouses
LEFT JOIN products ON products.warehouseCode = warehouses.warehouseCode
LEFT JOIN orderdetails ON orderdetails.productCode = products.productCode
GROUP BY warehouses.warehouseCode, warehouses.warehouseName
ORDER BY totalSold ASC;

-- 2. Percentage of inventory sold for each warehouse // With this we can see that warehouse D has a good performance. But warehouse B doesn't. 
SELECT 
    warehouses.warehouseCode, 
    warehouses.warehouseName, 
    SUM(products.quantityInStock) AS totalInventory,
    COALESCE(SUM(orderdetails.quantityOrdered), 0) AS totalSold,
    ROUND((COALESCE(SUM(orderdetails.quantityOrdered), 0) / SUM(products.quantityInStock)) * 100, 2) AS percentageSold
FROM 
    warehouses
LEFT JOIN 
    products ON warehouses.warehouseCode = products.warehouseCode
LEFT JOIN 
    orderdetails ON products.productCode = orderdetails.productCode
GROUP BY 
    warehouses.warehouseCode, 
    warehouses.warehouseName
HAVING totalInventory > 0;


-- What-If Analysis: Simulating the impact of a 5% inventory reduction across the board to observe changes in sales efficiency.

-- 1. What would be the impact of reducing inventory by 5%. Warehouse b still has a low performance
SELECT 
    warehouses.warehouseCode, 
    warehouses.warehouseName, 
    SUM(products.quantityInStock) AS originalInventory,
    ROUND(SUM(products.quantityInStock) * 0.95, 2) AS reducedInventory,
    COALESCE(SUM(orderdetails.quantityOrdered), 0) AS totalSold,
    ROUND((COALESCE(SUM(orderdetails.quantityOrdered), 0) / (SUM(products.quantityInStock) * 0.95)) * 100, 2) AS newPercentageSold
FROM 
    warehouses 
LEFT JOIN 
    products ON warehouses.warehouseCode = products.warehouseCode
LEFT JOIN 
    orderdetails ON products.productCode = orderdetails.productCode
GROUP BY 
    warehouses.warehouseCode, 
    warehouses.warehouseName
HAVING 
    originalInventory > 0;

/* Statistical Considerations:
* The analysis focused on comparing sales efficiency with inventory levels to identify potential warehouses for closure.
* Limitations included potential external factors influencing sales, which were not accounted for in the data. */

/* Conclusions:
* Warehouse D (warehouseCode: d):
Although it has the least inventory and sales, it performs efficiently. Closing it might not be advisable due to its high performance.
* Warehouse B (warehouseCode: b):
This warehouse holds the most inventory but has the lowest sales efficiency. Closing it and redistributing its stock to more efficient 
warehouses could reduce costs and improve overall inventory management.
Product Discontinuation:
The 1985 Toyota Supra shows very low sales and should be considered for discontinuation to free up space and reduce holding costs.


Recommendations:
* Closing the East Warehouse (Warehouse B):
Based on the analysis, closing warehouse B seems the most logical choice. The high inventory levels combined with low sales efficiency 
make it a prime candidate for closure. Redistributing its inventory could maintain or even improve overall sales efficiency and reduce storage costs.
* Product Discontinuation:
Consider discontinuing products with consistently low or no sales, like the 1985 Toyota Supra, to streamline inventory and reduce excess stock.
*/


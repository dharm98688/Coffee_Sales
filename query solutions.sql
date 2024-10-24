DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

CREATE TABLE city
(
	city_id INT PRIMARY KEY,
	city_name VARCHAR(50),
	population BIGINT,
	estimated_rent FLOAT,
	city_rank INT

);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,
	customer_name VARCHAR(70),
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
)
CREATE TABLE products
(
	product_id INT PRIMARY KEY,
	product_name VARCHAR(50),
	price INT
)
ALTER TABLE products
ADD CONSTRAINT product_id PRIMARY KEY(product_id)
CREATE TABLE sales
(
	sale_id INT PRIMARY KEY,
	sale_date DATE,
	product_id INT,	
	customer_id INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY(product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customer_id FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
)
select * from sales;
select * from products;
select * from city;
select * from customers;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select 
	city_name,
	ROUND(population * 0.25/100000,2),
	city_rank
from city
ORDER BY 2 DESC

--2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	SUM(total) AS total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM sale_date) = 4;

SELECT 
	ci.city_name,
	SUM(total) as total_revenue
FROM sales AS s
JOIN customers as c
ON s.customer_id = c.customer_id

JOIN city as ci
ON ci.city_id = c.city_id

WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC

--3. Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT
	product_name,
	SUM(s.sale_id) as total_orders
FROM products as p
LEFT JOIN sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

--4.Average Sales Amount per City-SALES,CITY AND CUSTOMER
-- What is the average sales amount per customer in each city?
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customers,
	ROUND(
		SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2
	) as avg_sale_per_customer	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC

--5.City Population and Coffee Consumers (25%)--city=cityname and population,
--sales=salesrecords and customer information and customers=customer ids hain
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
WITH city_table AS
(
SELECT
	city_name,
	ROUND(population * 0.25)as coffee_consumers
FROM city
),
customer_table
AS
(
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY 1
)
SELECT 
	customer_table.city_name,
	city_table.coffee_consumers AS coffee_consumers_in_millions,
	customer_table.unique_customer
FROM city_table
JOIN customer_table
ON city_table.city_name = customer_table.city_name

--Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
SELECT * 
FROM --table
(
SELECT 
	ci.city_name,
	p.product_name,
	COUNT(s.sale_id) as total_orders,
	DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2
--ORDER BY 1,2,3 DESC
)
AS T1
WHERE rank<=3
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT * FROM products
SELECT 
	ci.city_name,
	COUNT (DISTINCT c.customer_id) AS unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1

--8.Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
WITH city_table
AS
(SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(distinct s.customer_id) as total_cx,
		ROUND(
			SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2)
			 AS avg_sale_pr_cx
FROM
sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name,  ---CITY NAME AND RENT
	estimated_rent
FROM city
)

SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/ct.total_cx::numeric, 2
			) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC


-- 9.Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
WITH
monthly_sales
AS
(
SELECT
	ci.city_name,
	EXTRACT(MONTH FROM sale_date) as month,
	EXTRACT(YEAR FROM sale_date) as year,
	SUM(s.total) as total_sales
FROM sales AS s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio
AS
(
	SELECT
		city_name,
		month,
		year,
		total_sales as cr_month_sale,
		LAG(total_sales, 1)OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
	FROM monthly_sales 
	
)
SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100, 2
	) as growth_percentage
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC


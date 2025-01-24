--Monday Coffee --Data Analysis
select * from city;
select * from products;
select * from customers;
select * from sales;

--Reports and Data analysis
--Q1 Coffee Consumers Count 
--how many in each are estimated to consume coffee given that 25% of the population does
select 
     city_name,
	 ROUND(
	 (population * 0.25)/1000000,
	 2) as coffee_consumers_in_millions,
	 city_rank
from city
order by  2 desc;

--Q2 Total revenue from coffee sales
--what is the total revenue generated from coffee sales across all cites in the last quatre 2023

select *,

     extract (YEAR   FROM sale_date)as year,
     extract (quarter  FROM sale_date)as qtr
	 
from sales
where
     extract (YEAR   FROM sale_date)=2023
	 and
	 extract (quarter from sale_date)=4;

-- total revenue
select 
      ci.city_name,
      sum(total)as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where
     extract(year from s.sale_date)=2023
	 and 
	 extract (quarter from s.sale_date)=4
group by 1
order by 2 desc;

-- Q3 sales count for each product
-- how many units of each coffee 

select 
      p.product_name,
	  count(s.sale_id) as total_orders
from
     products as p
left join 
     sales as s
 on  s.product_id = p.product_id
 group by 1
 order by 2 desc;


 -- Q3 Average sales Amount per customer in each city
 -- what is the average sales amount per customer in each city
-- city total sales
-- no of customer each these city 

 select 
       ci.city_name,
	   sum(s.total)as total_revenue,
	   count(distinct s.customer_id)as total_cs,
	   ROUND(
	         sum(s.total)::numeric/
			 count(distinct s.customer_id)::numeric
			 ,2)as avg_sale_per_cs
 from sales as s
 join customers as c
 on s.customer_id = c.customer_id
 join city as ci
 on ci.city_id = c.city_id
 group by 1
 order by 2 desc;

 -- Q.5 
 -- city population and coffee consumers 25%
 -- provies a list of cites along  with number populations and estimated and consumers
-- return city_name cuurent cs estimated coffee conssumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name =customers_table.city_name;

-- Q6 
-- top salling product  by city
-- what are the top 3 selling products in each city based on sales volume?

select * from --table name
	(select 
	     ci.city_name,
		 p.product_name,
		 count(s.sale_id)as total_orders,
		 dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc)as rank
	from sales as s
	join  products as p
	on s.product_id = p.product_id
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1,2
	)as t1
	where rank<=3;


-- Q7 
-- customer segmentation by city
-- how many customer are unique there in each who have purchsed coffee product

select 
	   ci.city_name,
	   count(distinct c.customer_id) as unique_cs
	from city as ci
	left join 
	     customers as c
	on c.city_id = ci.city_id
	join sales as s
	on s.customer_id = c.customer_id
	where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
	group by 1;


-- Q8 
-- Average sale vs rent 
-- find each city and thire  average sale per customer and avg rent per customer


WITH city_table AS 
(
   SELECT 
      ci.city_name,
      SUM(s.total) AS total_revenue,
      COUNT(DISTINCT s.customer_id) AS total_cs,
      ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) AS avg_sale_pr_cs
   FROM sales AS s
   JOIN customers AS c
      ON s.customer_id = c.customer_id
   JOIN city AS ci
      ON ci.city_id = c.city_id
   GROUP BY ci.city_name
),
city_rent AS (
   SELECT 
      city_name,
      estimated_rent
   FROM city
)
SELECT
   cr.city_name,
   cr.estimated_rent,
   ct.total_cs,
   ct.avg_sale_pr_cs,
   ROUND(cr.estimated_rent::numeric / ct.total_cs::numeric, 2) AS avg_rent_pr_cs
FROM city_rent AS cr
JOIN city_table AS ct
   ON cr.city_name = ct.city_name
ORDER BY avg_rent_pr_cs DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULl;



-- Q10
-- market potential analysis
-- Identify top city based on highest sales return city name total sale total rent total customers estimated coffee
-- consumer

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

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.

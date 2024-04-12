-- Resume Project Challenge 4 Codebasics

-- Q1 Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region

select distinct market, region from dim_customer 
where customer like "%Atliq Exclusive%" and region like "%APAC%";


-- Q2  What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg
 

with cte21 as(
	select count(distinct product_code) as Unique_Product_2021 from fact_sales_monthly where Fiscal_year =2021),
cte20 as(
	select count(distinct product_code) as unique_Product_2020 from fact_sales_monthly where Fiscal_year =2020
)
select * , round(((Unique_Product_2021 -unique_Product_2020)/unique_Product_2020) * 100,2) as Pct_Product_change from cte21 cross join	 cte20;


-- Q3 
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,segment, product_count

select 
	segment, count(distinct product_code) as Product_count
 from dim_product
 group by segment
 order by Product_count desc;
 

 -- Q4 Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021 difference

-- Method 1 

WITH cte21 as (
    select 
        p.segment, COUNT(DISTINCT product_code) AS Product_count_21
    from dim_product AS p
    join fact_sales_monthly AS f USING (product_code)
    where f.Fiscal_year = 2021
    Group by  p.segment
),
cte20 AS (
    select 
        p.segment, COUNT(DISTINCT product_code) AS Product_count_20
    from dim_product AS p
    join fact_sales_monthly AS f USING (product_code)
    where f.Fiscal_year = 2020
    group  BY p.segment
),
cte_table as (
SELECT 
    c20.segment,
    c20.Product_count_20,
    c21.Product_count_21,
    (c21.Product_count_21-c20.Product_count_20)  as difference_in_Product
from cte20 c20
JOIN cte21 c21 ON c20.segment = c21.segment)

select * from cte_table
    where difference_in_product = (select max(difference_in_product) from cte_table);
    
    
-- method 2

CREATE VIEW product_counts_comparison AS
with cte21 as (
    select 
        p.segment, COUNT(DISTINCT product_code) AS Product_count_21
    from dim_product AS p
    join fact_sales_monthly AS f USING (product_code)
    where f.Fiscal_year = 2021
    group BY p.segment
),
cte20 as (
    select 
        p.segment, COUNT(DISTINCT product_code) AS Product_count_20
    from dim_product AS p
    join fact_sales_monthly AS f USING (product_code)
    Where f.Fiscal_year = 2020
    group  BY p.segment
)
select
    c20.segment,
    c20.Product_count_20,
    c21.Product_count_21
from cte20 c20
join cte21 c21 ON c20.segment = c21.segment;


with cte_max_difference as (
select *, (Product_count_21 - Product_count_20) as Difference from product_counts_comparison)

select* from cte_max_difference where difference = (select max(difference)from cte_max_difference);


-- 5  Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

    
select  max(manufacturing_cost) from fact_manufacturing_cost;
 
select  min(manufacturing_cost) from fact_manufacturing_cost;
 

select 
	p.product_code,
	p.product,
	m.manufacturing_cost
from dim_product as p
join fact_manufacturing_cost as m
using(product_code)
where 
	manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost) or 
	manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;


-- 2nd method

select
    p.product_code,
    p.product,
    m.manufacturing_cost
from
    dim_product AS p
join 
    fact_manufacturing_cost AS m
using (product_code)
where 
    m.manufacturing_cost IN (
        select
            MAX(manufacturing_cost) AS max_cost
        from
            fact_manufacturing_cost
        union
        select 
            MIN(manufacturing_cost) AS min_cost
        from
            fact_manufacturing_cost
    )
order by 
    m.manufacturing_cost DESC;
    
    -- 6
    -- . Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

Select
	c.customer_code,
    c.customer,
    CONCAT(ROUND(AVG(f.pre_invoice_discount_pct)*100,2),"%") as average_discount_percentage
From dim_customer as c
Join fact_pre_invoice_deductions as f
USING(customer_code)
Where fiscal_year=2021 AND market="India"
Group BY c.customer,c.customer_code
order  BY AVG(f.pre_invoice_discount_pct) desc
limit 5;


-- 7
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select
    Monthname(s.date) as Month_Name,
    Year(s.date) as Year,
    round(sum(g.gross_price*s.sold_quantity)/1000000,2) as gross_sales_price_mlm
from fact_sales_monthly as s
join fact_gross_price as g
on 
	s.product_code=g.product_code and
    s.fiscal_year=g.fiscal_year
join dim_customer as c
on
	s.customer_code=c.customer_code

where
	customer="Atliq Exclusive"

group by date
order by date,gross_sales_price_mlm desc;


-- Q8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity,
-- Quarter 
-- total_sold_quantity


select*,
	case
		when month(s.date) in (9,10,11) then "Q1"
		when month(s.date) in (12,1,2) then "Q2"
        when month(s.date) in (3,4,5) then "Q3"
		else "Q4"
	end as Quarters
from fact_sales_monthly as s
where s.Fiscal_year = 2020;

with cte(date, Fiscal_year, Product_code, Customer_code,Sold_Quantity,Quarters) as
(
select*,
	case
		when month(s.date) in (9,10,11) then "Q1"
		when month(s.date) in (12,1,2) then "Q2"
        when month(s.date) in (3,4,5) then "Q3"
		else "Q4"
	end as Quarters
from fact_sales_monthly as s
where s.Fiscal_year = 2020
)
select Quarters, sum(Sold_Quantity) as Quantity from cte
group by Quarters
order by Quantity desc;

-- Q9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage
with cte1(Channel, Gross_sales_mlm) as (

select
    c.channel,
    round(sum(g.gross_price*s.sold_quantity)/1000000,2) as gross_sales_mlm
from fact_sales_monthly as s
join fact_gross_price as g
on 
	s.product_code=g.product_code and
    s.fiscal_year=g.fiscal_year
join dim_customer as c
on
	s.customer_code=c.customer_code
where
	s.fiscal_year= 2021
Group by  c.channel
order by gross_sales_mlm desc)

select *, 
	CONCAT(round(Gross_sales_mlm*100/sum(Gross_sales_mlm) over(),2),"%")as percentage from cte1
group by channel;

-- Q10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, 
-- division 
-- product_code


select 
	d.division, d.product_code, sum(s.sold_quantity) as total_qty
from fact_sales_monthly as s
join dim_product as d 
	on s.product_code = d.product_code
where s.Fiscal_year = 2021
group by d.division, d.product_code
order by total_qty desc;

-- to Perform rank we need to use cte 

with cte1(Division,Product_code,Total_qty) as
(select 
	d.division, d.product_code, sum(s.sold_quantity) as total_qty
from fact_sales_monthly as s
join dim_product as d 
	on s.product_code = d.product_code
where s.Fiscal_year = 2021
group by d.division, d.product_code
order by total_qty desc),

cte2 as (

select *, dense_rank() over(partition by Division Order by Total_qty desc) as rnk from cte1)

select Division, Product_code, Total_qty from cte2 where  rnk<=3;





































    







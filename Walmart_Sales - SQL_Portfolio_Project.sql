set SQL_SAFE_UPDATES = 0;

/* 12th Jan, 2025 7:15pm
Walmart Sales Data Analysis With MySQL | MySQL Protfolio Project
YT Source : https://www.youtube.com/watch?v=Qr1Go2gP8fo&ab_channel=CodeWithPrince
Dataset : https://github.com/Princekrampah/WalmartSalesAnalysis/blob/master/SQL_queries.sql
*/

show tables;

CREATE TABLE IF NOT EXISTS walmart_sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct decimal(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    purchase_date DATETIME NOT NULL,
    purchase_time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,  -- cost of goods sold
    gross_margin_pct decimal(11,9),
    gross_income DECIMAL(12, 4),
    rating decimal(2, 1)
);

-- 1). Feature Engineering : Add columns to the table showing the "time_of_day" , "week_of_day" and "month_name"
select *,
case
	when purchase_time between "00:00:00" and "11:59:59" then "Morning"
    when purchase_time between "12:00:00" and "15:59:59" then "Afternoon"
    else "Evening"
    end as time_of_day,
case
    when weekday(walmart_sales.purchase_date)=0 then 'Mon'
    when weekday(walmart_sales.purchase_date)=1 then 'Tue'
    when weekday(walmart_sales.purchase_date)=2 then 'Wed'
    when weekday(walmart_sales.purchase_date)=3 then 'Thu'
    when weekday(walmart_sales.purchase_date)=4 then 'Fri'
    when weekday(walmart_sales.purchase_date)=5 then 'Sat'
    when weekday(walmart_sales.purchase_date)=6 then 'Sun'
    end as week_of_day,
monthname(purchase_date) month_name
from walmart_sales;

alter table walmart_sales
add time_of_day varchar(10),
add column week_of_day varchar(10),  -- you can add column using either of the "add column column_name" or "add column_name" statement
add month_name varchar(10);

Update walmart_sales
set time_of_day = (case
	when purchase_time between "00:00:00" and "11:59:59" then "Morning"
    when purchase_time between "12:00:00" and "15:59:59" then "Afternoon"
    else "Evening"
    end),
week_of_day = (case
    when weekday(walmart_sales.purchase_date)=0 then 'Mon'
    when weekday(walmart_sales.purchase_date)=1 then 'Tue'
    when weekday(walmart_sales.purchase_date)=2 then 'Wed'
    when weekday(walmart_sales.purchase_date)=3 then 'Thu'
    when weekday(walmart_sales.purchase_date)=4 then 'Fri'
    when weekday(walmart_sales.purchase_date)=5 then 'Sat'
    when weekday(walmart_sales.purchase_date)=6 then 'Sun'
    end),
month_name = monthname(purchase_date);

select time_of_day, week_of_day, month_name
from walmart_sales
where time_of_day is null or week_of_day is null or month_name is null;  -- confirmed that there are no nulls in either of the columns.

-- 2). EDA : Exploratory data analysis - Answering questions based on the dataset/table.
/*
Generic Question :
	How many unique cities does the data have?
	In which city is each branch?

Product :
	How many unique product lines does the data have?
	What is the most common payment method?
	What is the most selling product line?
	What is the total revenue by month?
	What month had the largest COGS?
	What product line had the largest revenue?
	What is the city with the largest revenue?
	What product line had the largest VAT?
	Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
	Which branch sold more products than average product sold?
	What is the most common product line by gender?
	What is the average rating of each product line?
Sales :
	Number of sales made in each time of the day per weekday
	Which of the customer types brings the most revenue?
	Which city has the largest tax percent/ VAT (Value Added Tax)?
	Which customer type pays the most in VAT?
Customer :
	How many unique customer types does the data have?
	How many unique payment methods does the data have?
	What is the most common customer type?
	Which customer type buys the most?
	What is the gender of most of the customers?
	What is the gender distribution per branch?
	Which time of the day do customers give most ratings?
	Which time of the day do customers give most ratings per branch?
	Which day fo the week has the best avg ratings?
	Which day of the week has the best average ratings per branch?
*/

-- Q1). How many unique cities does the data have?
select distinct(city)
from walmart_Sales;

-- Q2). In which city is each branch?
select distinct(branch), city
from walmart_sales
order by branch;

-- Q3). How many unique product lines does the data have?
select distinct(product_line)
from walmart_sales;

-- Q4).	What is the most common payment method?
select payment, count(*) total_transactions
from walmart_sales
group by payment
order by total_transactions desc;

-- Q5).	What is the most selling product line?
select product_line, count(*) total_transactions
from walmart_sales
group by product_line
order by total_transactions desc;

-- Q6).	What is the total revenue by month? Note : Total Revenue = Gross Income + Cogs
select month_name, sum(gross_income+cogs) total_revenue
from walmart_sales
group by month_name
order by total_revenue desc;

-- Q7). What month had the largest COGS?
select month_name, max(cogs) total_cogs
from walmart_sales
group by month_name
order by total_cogs desc
limit 1;

-- Q8). What product line had the largest revenue? Note : Revenue = Gross Income + Cogs
select product_line, sum(gross_income + cogs) revenue
from walmart_sales
group by product_line
order by revenue desc
limit 1;


-- Q9).	What is the city with the largest revenue? Note : Revenue = Gross Income + Cogs
select city, sum(gross_income+cogs) revenue
from walmart_sales
group by city
order by revenue desc
limit 1;

-- Q10). What product line had the largest VAT? Note : 'tax_pct' is the VAT and it is set to 5% of cogs
select product_line, sum(tax_pct) total_VAT
from walmart_sales
group by product_line
order by total_VAT desc
limit 1;

-- Q11). Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales. Note : Sales = Quantity
select avg(quantity)
from walmart_sales;  -- 5.499

select product_line, avg(quantity) avg_sales,
case
	when avg(quantity) > 5.499 then 'Good'
    else 'Bad'
    end sale_type
from walmart_sales
group by product_line;

-- Q12). Which branch sold more products than average product sold? Note : Product Sold = Quantity
select branch, sum(quantity) total_prod_sold
from walmart_sales
group by branch
having total_prod_sold > (select avg(quantity) from walmart_sales)
order by total_prod_sold desc;


-- Q13). What is the most common product line by gender?
select gender, product_line, count(*) total_transactions
from walmart_sales
group by gender, product_line
order by total_transactions desc;

-- Q14). What is the average rating of each product line?
select product_line, round(avg(rating),2) avg_rating
from walmart_sales
group by product_line
order by avg_rating desc;

-- Q15). Number of sales made in each time of the day per weekday
select time_of_day, count(quantity) total_sales
from walmart_sales
where week_of_day = "Sun"
group by time_of_day
order by total_Sales desc;
-- Bonus Question : Find the total sales for all week_of_day along with time_of_day?
select week_of_day, time_of_day, count(quantity) total_sales
from walmart_sales
group by week_of_day, time_of_day
order by total_Sales desc;

-- Q16). Which of the customer types brings the most revenue? Note : Revenue = Gross Income + Cogs
select customer_type, sum(gross_income+cogs) revenue
from walmart_sales
group by customer_type
order by revenue desc;

-- Q17). Which city has the largest tax percent/ VAT (Value Added Tax)?
select city, avg(tax_pct) largest_VAT
from walmart_sales
group by city
order by largest_VAT desc
limit 1;

-- Q18). Which customer type pays the most in VAT?
select customer_type, avg(tax_pct) most_VAT
from walmart_sales
group by customer_type
order by most_VAT desc
limit 1;

-- Q19). How many unique customer types does the data have?
select distinct(customer_type)
from walmart_sales;

-- Q20). How many unique payment methods does the data have?
select distinct(payment)
from walmart_sales;

-- Q21). What is the most common customer type?
select customer_type, count(customer_type) count_cx_type
from walmart_sales
group by customer_type
order by count_cx_type desc
limit 1;

-- Q22). What is the gender of most of the customers?
select gender, count(gender) count_of_gender
from walmart_sales
group by gender
order by count_of_gender desc
limit 1;

-- Q24). What is the gender distribution per branch?
select gender, branch, (count(gender)/995)*100 distribution
from walmart_sales
group by gender, branch
order by distribution desc;

-- Q25). Which time of the day do customers give most ratings?
select time_of_day, avg(rating) avg_ratings
from walmart_sales
group by time_of_day
order by avg_ratings desc;

-- Q26). Which time of the day do customers give most ratings per branch?
select branch, time_of_day, round(avg(rating),2) avg_ratings
from walmart_sales
group by branch, time_of_day
order by avg_ratings desc;

-- Q27). Which day of the week has the best avg ratings?
select week_of_day, avg(rating) avg_ratings
from walmart_sales
group by week_of_day
order by avg_ratings desc;


-- Q28). Which day of the week has the best average ratings per branch?
select branch, week_of_day, avg(rating) avg_ratings
from walmart_sales
group by branch, week_of_day
order by avg_ratings desc;

-- *******************************************************************END**********************************************************************************
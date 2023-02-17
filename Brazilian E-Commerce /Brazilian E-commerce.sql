-- This document outlines the objective of the analysis and provides the SQL query used to obtain the desired results. 
-- The focus of the query is to extract insights from a Brazilian e-commerce dataset.


-- 1.Time period of the given data.
SELECT
MIN(order_purchase_timestamp) AS min_date, MAX(order_purchase_timestamp) AS max_date
FROM
`target.orders`

-- 2.To get orders in specific period.
SELECT
* FROM (
SELECT
customer_city, customer_state, EXTRACT (year FROM
order_purchase_timestamp) AS ordyear FROM
`target.customers` AS tc LEFT JOIN
`target.orders` AS tod ON
tc.customer_id=tod.customer_id) WHERE
ordyear>2016
AND ordyear<2018;
-- Note: need to provide time period here.

-- 3.To get month wise orders from the complete given dataset.
select ordyear,ordmonth,count(order_id) as no_oforders from
(select order_id,customer_id,order_purchase_timestamp,
EXTRACT(YEAR FROM order_purchase_timestamp) AS ordyear,
EXTRACT(Month FROM order_purchase_timestamp) AS ordmonth from `target.orders`
order by ordyear,ordmonth)
group by ordyear,ordmonth
order by ordyear,ordmonth;

-- 4. What time do Brazilian customers tend to buy (Dawn, Morning, Afternoon or Night)?
select order_id,customer_id,order_purchase_timestamp,ordyear,ordmonth,ordtime, case
when ordtime<6 then 'Dawn'
when ordtime<12 then 'Morning'
when ordtime<18 then 'Afternoon' else "Night"
end as timing
from(select order_id,customer_id,order_purchase_timestamp, EXTRACT(YEAR FROM
order_purchase_timestamp) AS ordyear,
EXTRACT(Month FROM
order_purchase_timestamp) AS ordmonth,
extract (hour from order_purchase_timestamp) as ordtime from `target.orders`
order by ordyear,ordmonth,ordtime);

-- 5.Get month on month orders by each states
SELECT
COUNT(order_id) as nooforders, EXTRACT(YEAR
FROM
order_purchase_timestamp) AS ordyear, EXTRACT(month
FROM
order_purchase_timestamp) AS ordmonth, customer_state
FROM ( SELECT
order_id, order_purchase_timestamp, customer_state
FROM
`target.orders` AS tord
LEFT JOIN `target.customers`AS tc
ON
tc.customer_id=tord.customer_id) GROUP BY
ordyear, ordmonth, customer_state order by Ordyear,ordmonth;

-- 6.How many Customers in each state.
select customer_state ,count(customer_id) as no_Customer from `target.customers`
group by customer_state
order by no_Customer desc;
-- 7.% change in cost of orders 2017 to 2018 example
WITH data AS ( SELECT
ordyear,
ordmonth,
round(sum(payment_value ),2) as payment_sum
FROM ( SELECT
tp.order_id,
tp.payment_value, tor.order_purchase_timestamp, EXTRACT(YEAR
FROM
order_purchase_timestamp) AS ordyear,
EXTRACT(month FROM
order_purchase_timestamp) AS ordmonth FROM
`target.payments` AS tp LEFT JOIN
`target.orders` AS tor ON
tp.order_id=tor.order_id) WHERE
ordmonth BETWEEN 1 and 8 group by ordyear,ordmonth ORDER BY
1,
2
),
base_2017 AS ( SELECT
ordyear, ordmonth, payment_sum
FROM data WHERE
ordyear = 2017 ),
base_2018 AS ( SELECT
ordyear,
ordmonth, payment_sum as pay2018
FROM data WHERE
ordyear = 2018 ),
result AS ( SELECT
 
base_2017.ordmonth,
base_2017.ordyear,
payment_sum,
round((((pay2018 * 100) / payment_sum )/100),2) AS percent_change
FROM
base_2017,base_2018
)
SELECT
ordmonth,
round(avg(percent_change),2) as change_per FROM
result
group by ordyear,
ordmonth
order by 1,2;
-- 8.Calculate Mean & Sum of price and freight value by customer state.
select customer_state, round(avg(freight_value)) as freight_value, round(sum(toi.price),2) as sum_price,
round(avg(toi.price),2) as Mean_price
from `target.orders` as tord
left join `target.order_items` as toi on toi.order_id=tord.order_id LEFT JOIN
`target.customers`AS tc ON
tc.customer_id=tord.customer_id group by customer_state;
-- 9.Calculate days between purchasing, delivering and estimated delivery.
select (delivered_date-purchase_date)as T_del_days,(est_del_date-delivered_date) as D_need_del from (select EXTRACT(day
FROM
order_purchase_timestamp) AS purchase_date, EXTRACT(day
FROM
order_delivered_carrier_date) AS delivered_date, EXTRACT(day
FROM
order_estimated_delivery_date) AS est_del_date
from `target.orders`);
-- 10.Find time_to_delivery & diff_estimated_delivery. Formula for the same given below:
--  time_to_delivery = order_purchase_timestamp-order_delivered_customer_date 
--  diff_estimated_delivery = order_estimated_delivery_date-order_delivered_customer_date
select timestamp_diff(order_purchase_timestamp,order_delivered_customer_date,day) as time_to_delivery, 
date_diff(order_estimated_delivery_date,order_delivered_customer_date,day) as diff_estimated_delivery 
from `target.orders`

-- 11.Group data by state, take mean of freight_value, time_to_delivery, diff_estimated_delivery.
select customer_state, round(avg(freight_value)) as freight_value, round(avg(timestamp_diff(order_delivered_customer_date,order_purchase_timestamp,day)),2) as time_to_delivery, round(avg(date_diff(order_estimated_delivery_date,order_delivered_customer_date,day)),2) as diff_estimated_delivery
from `target.orders` as tord
left join `target.order_items` as toi on toi.order_id=tord.order_id
LEFT JOIN
`target.customers`AS tc ON
tc.customer_id=tord.customer_id group by customer_state;

-- 12.Top 5 states with highest/lowest average freight value - sort in desc/asc limiting to 5.
SELECT
customer_state,round(avg(freight_value),2) as freight_value
FROM
`target.orders` AS tord
LEFT JOIN `target.customers`AS tc
ON
tc.customer_id=tord.customer_id
left join `target.order_items` as toi on tord.order_id =toi.order_id GROUP BY
customer_state
order by freight_value desc
--Note: order the freight value by asc order to get lowest limit 5


-- 13.Top 5 states with highest/lowest average time to delivery.
SELECT customer_state,round(avg(timestamp_diff(order_delivered_customer_date,order_purchase_timestamp,day)),2)
as time_to_delivery FROM
`target.orders` AS tord LEFT JOIN
`target.customers`AS tc ON
tc.customer_id=tord.customer_id
left join `target.order_items` as toi on tord.order_id =toi.order_id GROUP BY
customer_state
order by time_to_delivery desc
--Note:to get lowest order by the time_to_delivery by asc order limit 5

-- 14.Top 5 states where delivery is really fast/ not so fast compared to estimated date
select customer_state, round(avg(timestamp_diff(order_delivered_customer_date,order_purchase_timestamp,day)),2) as time_to_delivery, round(avg(date_diff(order_estimated_delivery_date,order_delivered_customer_date,day)),2) as diff_estimated_delivery
from `target.orders` as tord
left join `target.order_items` as toi on toi.order_id=tord.order_id
LEFT JOIN
`target.customers`AS tc ON
tc.customer_id=tord.customer_id group by customer_state
order by 2 asc,3 desc
limit 5
-- 15 Month over Month count of orders for different payment types.
select EXTRACT(YEAR FROM
order_purchase_timestamp) AS ordyear, EXTRACT(month
FROM
order_purchase_timestamp) AS ordmonth,payment_type,count(order_id) as no_orders
from(
select tor.order_id,order_purchase_timestamp,payment_type
from `target.payments` as tp
left join `target.orders` as tor on tp.order_id=tor.order_id) group by ordyear,ordmonth,payment_type
order by ordyear,ordmonth;
-- 16.Count of orders based on the no. of payment instalments.
select payment_installments,count(order_id) as no_orders 
from `target.payments`
group by payment_installments;





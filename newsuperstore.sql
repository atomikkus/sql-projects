

-- Find the number of orders that have small, medium or large order value (small:0-10 dollars, medium:10-20 dollars, large:20+)

select h.order_size, count(*) as count
from
(select 
case
  when p.order_value between 0 and 10 then 'small'
  when p.order_value between 10 and 20 then 'medium'
  when p.order_value > 20 then 'large'
end as order_size
from
(select BASKET_ID, sum(SALES_VALUE) as order_value
from `newSuperStore.transactions`
group by BASKET_ID) as p) as h
group by h.order_size



--Find the number of orders that are small, medium or large order value(small:0-5 dollars, medium:5-10 dollars, large:10+)

select h.order_size, count(*) as count
from
(select 
case
  when p.order_value between 0 and 5 then 'small'
  when p.order_value between 5 and 10 then 'medium'
  when p.order_value > 10 then 'large'
end as order_size
from
(select BASKET_ID, sum(SALES_VALUE) as order_value
from `newSuperStore.transactions`
group by BASKET_ID) as p) as h
group by h.order_size



-- Find top 3 stores with highest foot traffic for each week (Foot traffic: number of customers transacting )
select *
from
(select f.WEEK_NO, f.STORE_ID,f.foot_traffic,round(f.total_sales,2) as weekly_sales, DENSE_RANK() OVER (PARTITION BY WEEK_NO ORDER BY f.foot_traffic DESC, f.total_sales DESC ) AS ranks
from
(select WEEK_NO,STORE_ID, count(DISTINCT(household_key)) as foot_traffic, sum(SALES_VALUE) as total_sales 
from `newSuperStore.transactions`
group by STORE_ID, WEEK_NO
order by WEEK_NO ASC, foot_traffic DESC) as f
ORDER BY f.WEEK_NO) as w
where w.ranks <= 3


-- Create a basic customer profiling with first, last visit, number of visits, average money spent per visit and total money spent order by highest avg money
select cp.household_key, count(*) as Visits, min(cp.trans_timer) as first_visit, max(cp.trans_timer) as last_visit, round(avg(cp.order_value),2) as AOV, round(sum(cp.order_value),2) as total_spent
from
(select C.household_key,C.BASKET_ID, C.trans_timer,round(SUM(C.SALES_VALUE),2) as order_value from (select household_key, BASKET_ID,(DAY*10000+TRANS_TIME)/10000 as trans_timer, SALES_VALUE from `newSuperStore.transactions`) as C
group by C.household_key, C.BASKET_ID, C.trans_timer) as cp 
group by cp.household_key
order by AOV DESC


-- Find products(product table : SUB_COMMODITY_DESC) which are most frequently bought together and the count of each combination bought together. do not print a combination twice ( A-B / B-A)

WITH tp AS (
    SELECT T.BASKET_ID, T.PRODUCT_ID, P.SUB_COMMODITY_DESC
    FROM (
        SELECT BASKET_ID, PRODUCT_ID
        FROM `newSuperStore.transactions`
    ) AS T
    JOIN (
        SELECT PRODUCT_ID, SUB_COMMODITY_DESC
        FROM `newSuperStore.Product`
    ) AS P
    ON T.PRODUCT_ID = P.PRODUCT_ID
)

SELECT CP.OG, CP.PAIR, COUNT(*) AS frequency
FROM (
    SELECT A.BASKET_ID, LEAST(A.SUB_COMMODITY_DESC, B.SUB_COMMODITY_DESC) AS OG,
           GREATEST(A.SUB_COMMODITY_DESC, B.SUB_COMMODITY_DESC) AS PAIR
    FROM tp AS A
    JOIN tp AS B ON A.BASKET_ID = B.BASKET_ID
    WHERE A.SUB_COMMODITY_DESC <> B.SUB_COMMODITY_DESC
) AS CP
GROUP BY CP.OG, CP.PAIR
ORDER BY frequency DESC


-- Find the weekly change in Revenue Per Account (RPA) (difference in spending by each customer compared to last week)(use lag function)

WITH W AS (
    SELECT
        household_key,
        WEEK_NO,
        ROUND(SUM(SALES_VALUE), 2) AS REVENUE
    FROM
        `newSuperStore.transactions`
    GROUP BY
        household_key, WEEK_NO
    ORDER BY
        WEEK_NO
)

SELECT
    household_key,
    WEEK_NO,
    REVENUE,
    ROUND(revenue - LAG(revenue, 1) OVER (PARTITION BY household_key ORDER BY WEEK_NO), 2) AS weekly_change_in_RPA
FROM
    W
ORDER BY
    household_key, WEEK_NO;


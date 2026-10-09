CREATE DATABASE ecommerce_project;
USE ecommerce_project;

SELECT * FROM user_data;
SELECT MIN(event_date) FROM user_data AS earliest_dates;
SELECT MAX(event_date) FROM user_data AS latest_dates;

-- define sales funnel and different stages --

WITH funnel_stages AS(
  SELECT
  COUNT(DISTINCT CASE WHEN event_type= 'page_view' THEN user_id END) AS stage1_pageview,
  COUNT(DISTINCT CASE WHEN event_type= 'add_to_cart' THEN user_id ENd) AS stage2_addToCart,
  COUNT(DISTINCT CASE WHEN event_type= 'checkout_start' THEN user_id END) AS stage3_checkout,
  COUNT(DISTINCT CASE WHEN event_type= 'payment_info' THEN user_id END) AS stage4_payment,
  COUNT(DISTINCT CASE WHEN event_type= 'purchase' THEN user_id END) AS stage5_purchase
  From user_data
  WHERE event_date <= '2026-02-03'
 )
 
 #SELECT * From funnel_stages;
 
 SELECT 
 stage1_pageview,
 ROUND(stage2_addToCart * 100 / stage1_pageview) AS viewTOcart,
 ROUND(stage3_checkout * 100 / stage2_addToCart) AS cartTocheckout,
 ROUND(stage4_payment * 100 / stage3_checkout) AS checkoutTOpayment,
 ROUND(stage5_purchase * 100 / stage4_payment) AS paymentTOpurchase,
 
ROUND(stage5_purchase * 100 / stage1_pageview) AS pageviewTOpurchase
FROM funnel_stages;

#the above calculation results are percentage and not number of users only.

-- Analyzing Marketing Channels and traffic sources. --

WITH source_funnel AS(
SELECT
 traffic_source,
 COUNT(DISTINCT CASE
   WHEN event_type= 'page_view'
   THEN user_id 
   END) AS PageView,
 
 COUNT(DISTINCT CASE
   WHEN event_type= 'add_to_cart'
   THEN user_id
   END) AS Cart,
 
 COUNT(DISTINCT CASE
   WHEN event_type= 'purchase'
   THEN user_id
   END) AS Purchases
 
 FROM user_data
 WHERE event_date <= '2026-02-03'
 GROUP BY traffic_source
 )
#SELECT * FROM source_funnel;

SELECT
 traffic_source,
 Pageview,
 Cart, 
 Purchases,
 
 Round(Cart * 100 / PageView) AS cart_conversion_rate,
 Round(Purchases * 100 / Cart) AS cart_to_purchase_conversion_rate,
 Round(Purchases * 100/ PageView) AS purchase_conversion_rate
 
 FROM source_funnel
 ORDER BY Purchases DESC;
 
 -- Time to Conversion Analysis --
 
 WITH user_journey AS(
  SELECT
  user_id,
  MIN(CASE WHEN event_type= 'page_view' THEN event_date END) as viewed_time,
  MIN(CASE WHEN event_type= 'add_to_cart' THEN event_date END) as addedToCart_time,
  MIN(CASE WHEN event_type= 'purchase' THEN event_date END) as purchased_time
  
  FROM user_data
  WHERE event_date <= '2026-02-03'
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type= 'purchase' THEN event_date END) IS NOT NULL
  )
  
  #SELECT * FROM user_journey;
  
  SELECT 
   COUNT(*) AS purchased_users,
   ROUND(AVG(TIMESTAMPDIFF(MINUTE, viewed_time, addedToCart_time)), 2) AS avgViewToCart_mins,
   ROUND(AVG(TIMESTAMPDIFF(MINUTE, addedToCart_time, purchased_time)), 2) AS avgCartToPurchase_mins,
   ROUND(AVG(TIMESTAMPDIFF(MINUTE, viewed_time, purchased_time)), 2) AS avgTotalJourney_mins
   
  FROM user_journey;
  
  -- Revenue funnel analysis and Financial Metrics --
  
  WITH funnel_revenue AS(
   SELECT
    COUNT(DISTINCT CASE WHEN event_type= 'page_view' THEN user_id END) as total_visitors,   #how many people visited the site?
    COUNT(DISTINCT CASE WHEN event_type= 'purchase' THEN user_id END) as total_purchases,   #how many customer actually purchased something?
    SUM(CASE WHEN event_type= 'purchase' THEN amount END) as total_revenue,                 #total amount of purchased items
    COUNT(CASE WHEN event_type= 'purchase' THEN 1 END) as total_orders                      #how many purchase events occurred, meaning it counts every purchase made by all customers combined.
     
     #example
     #Customer 101 → 3 purchases
     #Customer 102 → 2 purchases
	 #Customer 103 → 4 purchases
	 #Total = 9 purchase events.
     
	FROM user_data
    WHERE event_date <= '2026-02-03'
)

SELECT
 total_visitors,
 total_purchases,
 total_revenue,
 total_orders
FROM funnel_revenue;

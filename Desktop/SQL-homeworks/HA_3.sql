-- HA 3
-- Author: Elena Ibraeva
-- Topics: WITH, TIMEZONE, CTE, JOIN, AGGREGATION

WITH march_2017_flights AS (
  SELECT
    f.*,
    a.timezone,
    (f.actual_departure AT TIME ZONE a.timezone)::time AS local_time
  FROM flights f
  LEFT JOIN airports a ON f.departure_airport = a.airport_code
  WHERE (f.actual_departure AT TIME ZONE a.timezone)::date >= '2017-03-01'
    AND (f.actual_departure AT TIME ZONE a.timezone)::date < '2017-04-01'
)
SELECT
  (SELECT COUNT(*) FROM march_2017_flights WHERE local_time >= '21:00' OR local_time <= '01:00') AS night_flights,
  (SELECT departure_airport || ' - ' || arrival_airport
   FROM march_2017_flights
   WHERE local_time >= '21:00' OR local_time <= '01:00'
   GROUP BY departure_airport, arrival_airport
   ORDER BY COUNT(*) DESC LIMIT 1) AS most_popular_night_dir,
  (SELECT COUNT(*) FROM march_2017_flights WHERE local_time BETWEEN '06:00' AND '09:00') AS morning_flights,
  (SELECT departure_airport || ' - ' || arrival_airport
   FROM march_2017_flights
   WHERE local_time BETWEEN '06:00' AND '09:00'
   GROUP BY departure_airport, arrival_airport
   ORDER BY COUNT(*) DESC LIMIT 1) AS most_popular_morning_dir;

-- Task 2: Revenue by fare class in March 2017 (Europe/Moscow time)
SELECT
  (f.actual_departure AT TIME ZONE 'Europe/Moscow')::date AS actual_departure_msk,
  tf.fare_conditions,
  SUM(tf.amount) AS total_revenue
FROM flights f
LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
WHERE f.actual_departure >= '2017-03-01' AND f.actual_departure < '2017-04-01'
GROUP BY actual_departure_msk, tf.fare_conditions
ORDER BY actual_departure_msk, tf.fare_conditions;

-- Task 3: Top product categories sold together with wheels
WITH orders_with_wheels AS (
  SELECT DISTINCT so.salesorderid
  FROM salesorderdetail so
  JOIN product p ON so.productid = p.productid
  JOIN productsubcategory ps ON p.productsubcategoryid = ps.productsubcategoryid
  WHERE ps.name = 'Wheels'
),
all_subcategories AS (
  SELECT DISTINCT
    so.salesorderid,
    ps.productsubcategoryid,
    ps.name
  FROM salesorderdetail so
  JOIN product p ON so.productid = p.productid
  JOIN productsubcategory ps ON p.productsubcategoryid = ps.productsubcategoryid
  WHERE so.salesorderid IN (SELECT salesorderid FROM orders_with_wheels)
    AND ps.name != 'Wheels'
)
SELECT
  all_subcategories.productsubcategoryid AS product_subcategory_id,
  all_subcategories.name,
  COUNT(DISTINCT all_subcategories.salesorderid) AS cnt
FROM all_subcategories
GROUP BY product_subcategory_id, name
ORDER BY cnt DESC
LIMIT 5;

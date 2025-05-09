-- HA 4
-- Author: Elena Ibraeva
-- Topics: CTE, WINDOW FUNCTIONS, MOVING AVERAGE, RANKING, PERCENT CHANGE

-- Task 1: Monthly sales count and percent change by product category
WITH sales_data AS (
  SELECT
    sh.salesorderid,
    EXTRACT(YEAR FROM sh.orderdate) AS year,
    EXTRACT(MONTH FROM sh.orderdate) AS month_number,
    TO_CHAR(sh.orderdate, 'Month') AS month,
    pc.name AS category_name
  FROM salesorderheader sh
  JOIN salesorderdetail sd ON sh.salesorderid = sd.salesorderid
  JOIN product p ON sd.productid = p.productid
  JOIN productsubcategory ps ON p.productsubcategoryid = ps.productsubcategoryid
  JOIN productcategory pc ON ps.productcategoryid = pc.productcategoryid
  WHERE sh.orderdate BETWEEN '2013-01-01' AND '2013-04-30'
),
aggregated_sales AS (
  SELECT
    year, month, month_number, category_name,
    COUNT(DISTINCT salesorderid) AS total_orders
  FROM sales_data
  GROUP BY year, month, category_name, month_number
),
final_report AS (
  SELECT a.*,
    ROUND(
      COALESCE((a.total_orders * 1.0 / LAG(a.total_orders)
        OVER (PARTITION BY a.category_name ORDER BY a.year, a.month_number) - 1) * 100, 0), 2
    ) AS percent_change
  FROM aggregated_sales a
)
SELECT * FROM final_report WHERE month_number != 1
ORDER BY year, category_name, month_number;

-- Task 2: Top 10 most sold products and share of total
WITH most_popular_products AS (
  SELECT p.name AS product_name,
         SUM(sd.linetotal) AS sales_total
  FROM salesorderdetail sd
  JOIN salesorderheader sh ON sh.salesorderid = sd.salesorderid
  JOIN product p ON p.productid = sd.productid
  WHERE EXTRACT(YEAR FROM sh.orderdate) = 2013
  GROUP BY sd.productid, p.name
)
SELECT *,
  ROUND(sales_total * 100.0 / SUM(sales_total) OVER (), 2) AS percent_of_total
FROM most_popular_products
ORDER BY sales_total DESC
LIMIT 10;

-- Task 3: Most expensive product per order (May 2013)
WITH sales_data AS (
  SELECT
    sh.salesorderid, sh.totaldue, sd.productid, sd.unitprice,
    a.city AS delivery_city,
    p.productnumber, p.name AS product_name,
    ROW_NUMBER() OVER (PARTITION BY sh.salesorderid ORDER BY sd.unitprice DESC) AS price_category
  FROM salesorderdetail sd
  JOIN salesorderheader sh ON sh.salesorderid = sd.salesorderid
  JOIN address a ON a.addressid = sh.shiptoaddressid
  JOIN product p ON sd.productid = p.productid
  WHERE sh.orderdate BETWEEN '2013-05-01' AND '2013-05-31'
),
sales_data_aggregated AS (
  SELECT
    salesorderid, delivery_city, totaldue,
    MAX(CASE WHEN price_category = 1 THEN product_name END) AS most_expensive_product_name,
    COUNT(DISTINCT productid) AS number_of_products,
    STRING_AGG(productnumber, ', ') AS list_of_product_numbers
  FROM sales_data
  GROUP BY salesorderid, delivery_city, totaldue
)
SELECT
  salesorderid, number_of_products, delivery_city,
  ROUND(totaldue * 100.0 / SUM(totaldue) OVER (PARTITION BY delivery_city), 2) AS share_of_order_in_city,
  most_expensive_product_name, list_of_product_numbers
FROM sales_data_aggregated;

-- Task 4: ABC classification of products based on total sales
WITH sales_data AS (
  SELECT p.name AS product_name,
         SUM(sd.linetotal) AS sales_total
  FROM salesorderdetail sd
  JOIN salesorderheader sh ON sd.salesorderid = sh.salesorderid
  JOIN product p ON p.productid = sd.productid
  WHERE EXTRACT(YEAR FROM sh.orderdate) = 2013
  GROUP BY p.productid, p.name
),
total_sales AS (SELECT SUM(sales_total) AS S FROM sales_data),
sales_class AS (
  SELECT ps.product_name, ps.sales_total,
         SUM(ps.sales_total) OVER (ORDER BY ps.sales_total DESC) AS srti
  FROM sales_data ps
),
sales_limits AS (
  SELECT 0.8 * S AS sa, 0.95 * S AS sb
  FROM total_sales
)
SELECT rs.product_name, rs.sales_total,
  CASE
    WHEN rs.srti <= sl.sa THEN 'A'
    WHEN rs.srti <= sl.sb THEN 'B'
    ELSE 'C'
  END AS product_class
FROM sales_class rs, sales_limits sl
ORDER BY rs.sales_total DESC;

-- Task 5: Simple and weighted moving averages
WITH sales_data AS (
  SELECT orderdate::date AS order_date,
         SUM(totaldue) AS totaldue
  FROM salesorderheader
  WHERE orderdate::date BETWEEN '2013-05-01' AND '2013-05-31'
  GROUP BY order_date
)
SELECT order_date,
  ROUND(AVG(totaldue) OVER (ORDER BY order_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS simple_moving,
  ROUND(
    CASE
      WHEN COUNT(*) OVER (ORDER BY order_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) = 1 THEN COALESCE(totaldue, 0)
      WHEN COUNT(*) = 2 THEN (2 * COALESCE(totaldue, 0) + 1 * LAG(totaldue, 1, 0) OVER (ORDER BY order_date)) / 3
      WHEN COUNT(*) = 3 THEN (3 * COALESCE(totaldue, 0) + 2 * LAG(totaldue, 1, 0) + 1 * LAG(totaldue, 2, 0)) / 6
      WHEN COUNT(*) = 4 THEN (4 * COALESCE(totaldue, 0) + 3 * LAG(totaldue, 1, 0) + 2 * LAG(totaldue, 2, 0) + 1 * LAG(totaldue, 3, 0)) / 10
      ELSE (5 * COALESCE(totaldue, 0) + 4 * LAG(totaldue, 1, 0) + 3 * LAG(totaldue, 2, 0) + 2 * LAG(totaldue, 3, 0) + 1 * LAG(totaldue, 4, 0)) / 15
    END, 2
  ) AS weighted_moving
FROM sales_data
ORDER BY

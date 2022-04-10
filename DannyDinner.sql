-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS amount_spent
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
GROUP BY 1;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS visit_number
FROM sales
GROUP BY 1;

-- 3. What was the first item from the menu purchased by each customer?
WITH ranked AS (SELECT s.customer_id, m.product_name, s.order_date, 
RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as purchase_order
FROM sales s
JOIN menu m
ON s.product_id=m.product_id)
SELECT customer_id, product_name 
FROM ranked
WHERE purchase_order = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) purchase_number
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- number of purchase by each customer
SELECT s.customer_id, m.product_name, COUNT(s.product_id) frequency
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
WHERE m.product_name LIKE '%ramen%'
GROUP BY 1
ORDER BY 3;

-- 5. Which item was the most popular for each customer?
WITH ranking_table AS (SELECT s.customer_id, m.product_name, COUNT(s.product_id),
RANK () OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranking
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
GROUP BY 1,2)
SELECT customer_id, product_name, ranking 
FROM ranking_table
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH purchase_table AS (SELECT m1.product_name, s.*, m2.join_date
FROM sales s
LEFT JOIN menu m1
ON s.product_id=m1.product_id
LEFT JOIN members m2
ON s.customer_id=m2.customer_id)
SELECT customer_id, product_name, order_date, join_date
FROM purchase_table
WHERE order_date >= join_date
ORDER BY 1;

-- 7. Which item was purchased just before the customer became a member?

WITH purchase_table AS (SELECT product_name, s.customer_id, join_date, order_date,
RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) ranking
FROM sales s
LEFT JOIN menu m1
ON s.product_id=m1.product_id
LEFT JOIN members m2
ON s.customer_id=m2.customer_id
WHERE order_date < join_date)
SELECT customer_id, product_name, order_date, join_date
FROM purchase_table
WHERE ranking = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH cte AS (SELECT m.product_name, s.*, m.price, m2.join_date
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members m2 
ON s.customer_id=m2.customer_id
WHERE order_date < join_date)
SELECT customer_id, COUNT(product_id), SUM(price) 
FROM cte
GROUP BY 1;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH sales_menu AS (SELECT s.*, m.product_name, m.price
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id),
point_table AS (SELECT customer_id, product_name, product_id,
CASE product_name WHEN 'sushi' THEN price * 2 * 10
ELSE price * 10 
END points
FROM sales_menu)
SELECT customer_id, SUM(points) AS total_points
FROM point_table
GROUP BY 1;

/* 10. In the first week after a customer joins the program (including their join date) they 
earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */

SELECT * FROM members;
-- This showed that only A and B are menbers and they joined on 2021-01-07 and 2021-01-09 respectively

WITH member_rewards AS ( SELECT s.*, m.product_name, m.price, m2.join_date, date_add(m2.join_date, interval 6 day) Oneweek
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members m2
ON s.customer_id=m2.customer_id
WHERE s.customer_id=m2.customer_id),
jan_rewards AS (SELECT customer_id, product_name, order_date,
CASE WHEN product_name = 'sushi' THEN price *2 * 10
WHEN order_date BETWEEN join_date AND Oneweek THEN price *2 * 10
ELSE price * 10
END week1_reward
FROM member_rewards
WHERE order_date < '2021-01-31')
SELECT customer_id, SUM(week1_reward) jan_total_reward
FROM jan_rewards
GROUP BY 1;

-- Bonus Questions
-- 1. Recreate table with available data

WITH full_table AS (SELECT s.*, m.product_name, m.price, m2.join_date
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members m2
ON s.customer_id=m2.customer_id)
SELECT customer_id, order_date, product_name, price,
CASE WHEN order_date < join_date THEN 'N'
WHEN order_date >= join_date THEN 'Y'
ELSE 'N'
END AS member_status
FROM full_table
ORDER BY 1,2,4 DESC;

-- 2. Rank all things
WITH rank_table AS (SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN s.order_date < m2.join_date THEN 'N'
WHEN s.order_date >= m2.join_date THEN 'Y'
ELSE 'N'
END AS member_status
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members m2
ON s.customer_id=m2.customer_id)
SELECT *, CASE WHEN member_status = 'N' THEN 'Null'
	WHEN member_status = 'Y' THEN RANK() OVER (PARTITION BY customer_id,member_status ORDER BY order_date)
    END ranking
    FROM rank_table;
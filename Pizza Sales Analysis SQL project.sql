show databases;
create database pizzahut;
use pizzahut;
show tables;

SELECT * FROM pizza_types;

SELECT * FROM pizzas;

CREATE TABLE orders (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

SELECT * FROM orders;

CREATE TABLE order_details (
    order_details_id INT NOT NULL,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (order_details_id)
);

SELECT * FROM orders;

SELECT * FROM order_details;

SELECT * FROM pizzas;

SELECT * FROM pizza_types;

-- 1. Retrieve total numbers of orders placed

SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;

 -- 2. Calculate total revenue generated from pizza sales. 

SELECT 
    ROUND(SUM(total_cost), 2) AS total_revenue
FROM
    (SELECT 
        ord.order_id, SUM(p.price * ord.quantity) AS total_cost
    FROM
        order_details ord
    LEFT JOIN pizzas p ON ord.pizza_id = p.pizza_id
    GROUP BY ord.order_id) po;
    
    -- alternate query to get the desired output

SELECT 
    ROUND(SUM(ord.quantity * p.price), 2) AS total_revenue
FROM
    order_details ord
        JOIN
    pizzas p ON ord.pizza_id = p.pizza_id;

-- 3. Identify the highest priced pizza

SELECT * FROM pizzas;

SELECT * FROM pizza_types;

SELECT 
    pt.name as Pizza_Name, p.price as Pizza_Price
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- 4. Identify the most common pizza size orderd 

SELECT 
    size as Pizza_Size, COUNT(order_id) AS total_orders
FROM
    pizzas p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY Pizza_Size
ORDER BY total_orders DESC
LIMIT 1;

-- 5. List the top 5 most ordered pizza types along with their quantities

SELECT * FROM pizzas;

SELECT * FROM pizza_types;

SELECT * FROM order_details;

SELECT 
    pizza_type_id as Pizza_Type,
    COUNT(order_id) AS Total_Order_Placed,
    SUM(quantity) AS Total_Quantities_Ordered
FROM
    pizzas p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY Pizza_Type
ORDER BY Total_Order_Placed DESC
LIMIT 5;

-- 6. Join the necessary tables to find the quantity of each pizza ordered

SELECT 
    name AS Pizza_Name,
    p.pizza_id,
    size,
    SUM(quantity) AS Total_qty_ordered
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.pizza_id , p.size , Pizza_Name;

-- 7. Join the necessary tables to find the quantity of each pizza category ordered

SELECT 
    category AS Pizza_Category,
    SUM(quantity) AS Total_qty_ordered
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY Pizza_Category
ORDER BY Total_qty_ordered DESC;

-- 8. Determine the distribution of orders by the hours of the day

SELECT * FROM orders;

SELECT HOUR(order_time) AS hour 
FROM orders;

SELECT 
    HOUR(order_time) AS Hour_of_day,
    COUNT(order_id) AS Order_Count
FROM
    orders
GROUP BY Hour_of_day
ORDER BY Order_Count DESC;

-- 9. Join relevant tables to find the category wise distribution of pizzas

SELECT 
    category AS Pizza_Category,
    COUNT(pizza_type_id) AS Pizza_type_count
FROM
    pizza_types
GROUP BY Pizza_Category;

-- 10. Group the orders by date and calculate the average number of orders per day

SELECT 
    order_date, SUM(quantity) AS total_pizzas_ordered
FROM
    orders o
        JOIN
    order_details od ON o.order_id = od.order_id
GROUP BY order_date;

-- Using the output table of above query as subquery in next

SELECT 
    ROUND(AVG(total_pizzas_ordered), 0) AS avg_orders_per_day
FROM
    (SELECT 
        order_date, SUM(quantity) AS total_pizzas_ordered
    FROM
        orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY order_date) AS orders_per_day;

-- 11. Determine the top 3 most ordered pizza types based on revenue

SELECT 
    pt.name AS Pizza_Name, SUM(od.quantity * p.price) AS Revenue
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY Pizza_Name
ORDER BY revenue DESC
LIMIT 3;

-- 12 Calculate the percentage contribution of each pizza category to total revenue

-- total revenue count

SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM
    pizzas p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id;

SELECT 
    pt.category AS Pizza_Category,
    ROUND((SUM(od.quantity * p.price) / (SELECT 
                    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
                FROM
                    pizzas p
                        JOIN
                    order_details od ON p.pizza_id = od.pizza_id)) * 100,
            2) AS Percentage_Contribution
FROM
    pizza_types pt
        JOIN
    pizzas p ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY Pizza_Category
ORDER BY Percentage_Contribution DESC;

-- 13. Analyse the cumulative revenue generated over time

SELECT * FROM orders;

-- per order revenue

SELECT 
    o.order_id, SUM(p.price * od.quantity) AS order_revenue
FROM
    orders o
        JOIN
    order_details od ON o.order_id = od.order_id
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY order_id;

-- per day revenue

SELECT 
    o.order_date,
    ROUND(SUM(p.price * od.quantity), 2) AS per_day_revenue
FROM
    orders o
        JOIN
    order_details od ON o.order_id = od.order_id
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY order_date;

-- cumulative revenue by day

select order_date, per_day_revenue, 
round(sum(per_day_revenue) over(order by order_date),2) 
as Cumulative_Revenue
from
(select o.order_date, round(sum(p.price*od.quantity),2) 
as per_day_revenue
from orders o join order_details od
on o.order_id = od.order_id
join pizzas p on od.pizza_id = p.pizza_id
group by order_date) as day_rev;

-- 14. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

select category, name, revenue
from
(select category, name, total_ordered, revenue, 
rank() over (partition by category order by revenue desc) 
as rn
from
(select pt.category, pt.name, sum(quantity) as total_ordered, 
round(sum(p.price*od.quantity),2) as revenue
from pizza_types pt join pizzas p 
on pt.pizza_type_id = p.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by category, pt.name) as a) as b
where rn <=3;

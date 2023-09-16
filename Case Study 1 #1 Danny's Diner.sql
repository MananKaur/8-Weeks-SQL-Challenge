--1. What is the total amount each customer spent at the restaurant?
SELECT A.customer_id, sum(B.price) FROM dannys_diner.sales A
left join dannys_diner.menu B on
A.product_id = B.product_id
group by A.customer_id;

--2. How many days has each customer visited the restaurant?
SELECT customer_id, count(distinct order_date) FROM dannys_diner.sales 
group by customer_id;

--3. What was the first item from the menu purchased by each customer?

Select distinct first_order.customer_id, first_order.order_date, C.product_name from 
(SELECT distinct A.customer_id, min(A.order_date) as order_date FROM dannys_diner.sales A
group by customer_id order by 1) first_order left join dannys_diner.sales B on
first_order.customer_id = B.customer_id and
first_order.order_date = B.order_date
left join dannys_diner.menu C on
B.product_id = C.product_id
order by 2;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
Select menu.product_name, count as order_counts from (
  Select distinct product_id, count(customer_id) as count from dannys_diner.sales
group by product_id order by 2 desc limit 1) bestseller left join dannys_diner.menu on
bestseller.product_id = menu.product_id;

--5. Which item was the most popular for each customer?
Select customer_id, product_name, count from (
  Select distinct sales.customer_id, menu.product_name, count(sales.order_date) as count,
  dense_rank() over (partition by customer_id order by count(order_date) desc) order_rank 
  from dannys_diner.sales
  left join dannys_diner.menu on
  sales.product_id = menu.product_id 
  group by sales.customer_id, menu.product_name
  order by 1 ) subquery
where order_rank = 1;

--6. Which item was purchased first by the customer after they became a member?
Select customer_id, order_date, product_name from (
  Select sales.customer_id, sales.order_date, menu.product_name, 
  dense_rank() over (partition by sales.customer_id order by sales.order_date) as min_order_date
  from dannys_diner.sales left join dannys_diner.menu on
  sales.product_id = menu.product_id
  left join dannys_diner.members on 
  sales.customer_id = members.customer_id
  where sales.order_date >= members.join_date) subquery
where min_order_date = 1 ;

--7. Which item was purchased just before the customer became a member?
Select customer_id, order_date, product_name from (
  Select sales.customer_id, sales.order_date, menu.product_name, 
  row_number() over (partition by sales.customer_id order by sales.order_date desc) as order_rank
  from dannys_diner.sales left join dannys_diner.menu on
  sales.product_id = menu.product_id
  left join dannys_diner.members on 
  sales.customer_id = members.customer_id
  where sales.order_date < members.join_date) subquery
where order_rank = 1 ;
 
 --8. What is the total items and amount spent for each member before they became a member?
 
 --8.1 Results for just before they became a member
Select customer_id, order_date, count(product_name),  sum(price) from (
  Select sales.customer_id, sales.order_date, menu.product_name, menu.price,
  dense_rank() over (partition by sales.customer_id order by sales.order_date desc) as order_rank
  from dannys_diner.sales left join dannys_diner.menu on
  sales.product_id = menu.product_id
  left join dannys_diner.members on 
  sales.customer_id = members.customer_id
  where sales.order_date < members.join_date) subquery
where order_rank = 1 
group by customer_id, order_date;

--8.2 Results for before they became a member
Select customer_id, count(product_name),  sum(price) from (
  Select sales.customer_id, menu.product_name, menu.price
  from dannys_diner.sales left join dannys_diner.menu on
  sales.product_id = menu.product_id
  left join dannys_diner.members on 
  sales.customer_id = members.customer_id
  where sales.order_date < members.join_date) subquery
group by customer_id
order by 1;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
Select customer_id, sum(points) from (
  	Select sales.customer_id, sales.product_id, 
	case when sales.product_id = 1 then 20*menu.price else 10*menu.price end as points
	from dannys_diner.sales left join dannys_diner.menu on
	sales.product_id = menu.product_id) subquery
group by customer_id
order by customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
Select customer_id, sum(points) from (
  	Select sales.customer_id, sales.product_id, 
	case when sales.product_id = 1 OR 
  	(sales.order_date >= members.join_date AND 
   	sales.order_date < (members.join_date + INTERVAL '7 days')) then 20*menu.price 
		else 10*menu.price end as points
	from dannys_diner.sales left join dannys_diner.menu on
	sales.product_id = menu.product_id
	left join dannys_diner.members on
	sales.customer_id = members.customer_id

	where sales.order_date < '2021-02-01' and sales.customer_id in ('A', 'B')) subquery
group by customer_id
order by customer_id;

--Bonus Question 
Select *, case when member = 'N' then null
else rank() over (partition by customer_id, member order by order_date) end as rank from (
  Select sales.customer_id, sales.order_date, menu.product_name, menu.price, 
  case when sales.order_date >= members.join_date then 'Y' else 'N' end as member 
  from dannys_diner.sales 
  left join dannys_diner.menu on 
  sales.product_id = menu.product_id
  left join dannys_diner.members on
  sales.customer_id = members.customer_id) subquery


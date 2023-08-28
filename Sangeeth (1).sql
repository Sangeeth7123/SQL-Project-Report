select * from shipper;
select * from order_header;
select * from product_class;
select * from order_items;
select * from online_customer;
select * from carton;
select * from address;

-- Question_1 Write a query to display customer full name with their title (Mr/Ms), both first name and last name are in upper case, 
-- customer email id, customer creation date and display customer’s category after applying below categorization rules:
SELECT CONCAT ( ( CASE WHEN oc.customer_gender = 'M' THEN 'Mr. ' ELSE 'Ms. ' END ),
CONCAT ( " " ,UPPER(oc.customer_fname) ," " ,UPPER(oc.customer_lname) ) )
AS NAME ,oc.customer_email ,YEAR(oc.customer_creation_date) AS creation_year ,
CASE WHEN YEAR(oc.customer_creation_date) < 2005 THEN 'A' 
WHEN YEAR(oc.customer_creation_date) < 2011 THEN 'B' 
ELSE 'C' END AS category FROM online_customer oc;


-- Question 2 -Write a query to display the following information for the products, which have not been sold: product_id, 
-- product_desc, product_quantity_avail, product_price, inventory values (product_quantity_avail*product_price), 
-- New_Price after applying discount as per below criteria. Sort the output with respect to decreasing value of Inventory_Value.
SELECT 
    p.product_id, 
    p.product_desc, 
    p.product_quantity_avail, 
    p.product_price,
    (p.product_quantity_avail * p.product_price) AS inventory_value,
    CASE 
        WHEN p.product_price > 20000 THEN p.product_price * 0.8
        WHEN p.product_price > 10000 THEN p.product_price * 0.85
        ELSE p.product_price * 0.9
    END AS new_price
FROM product p LEFT JOIN order_items o on 
p.product_id  = o.order_id
WHERE product_quantity IS NULL ORDER BY inventory_value desc;

    
-- Question 3 Write a query to display Product_class_code, Product_class_description, Count of Product type in each product class, 
-- Inventory Value (product_quantity_avail*product_price).  Information should be displayed for only those 
-- product_class_code which have more than  1,00,000. Inventory Value. Sort the output with respect to decreasing value of Inventory_Value
SELECT p.product_class_code,
pc.product_class_desc, count(p.product_desc) OVER(PARTITION BY 
p.product_class_code) AS product_count, 
(p.product_quantity_avail*p.product_price) inventory_value FROM product p JOIN product_class pc USING(product_class_code)
 WHERE (p.product_quantity_avail*p.product_price) > 100000 
 ORDER BY inventory_value DESC;


-- Question 4 Write a query to display customer_id, full name, customer_email, customer_phone and country of customers who have cancelled 
-- all the orders placed by them (USE SUB-QUERY)
SELECT CUSTOMER_ID, concat(CASE customer_gender WHEN 'M' THEN 'Mr.' WHEN 'F' THEN 'Ms.'END," ", customer_fname," " ,customer_lname) 
AS FULL_NAME , CUSTOMER_EMAIL,CUSTOMER_PHONE, ad.COUNTRY
FROM online_customer oc JOIN address ad USING(address_id)
WHERE customer_id IN (SELECT customer_id FROM order_header WHERE order_status ="CANCELLED");


-- Question 5 - Write a query to display Shipper name, City to which it is catering, number of customer catered by the shipper in the city 
-- and number of consignments delivered to that city for  Shipper DHL
SELECT 
  s.shipper_name, 
  a.City, 
  count(DISTINCT o.customer_id) AS No_of_customers,
  COUNT(*) AS num_of_orders
FROM online_customer o
INNER JOIN order_header oh ON o.customer_id=oh.customer_id
INNER JOIN shipper s ON oh.shipper_id=s.shipper_id
JOIN address a ON a.address_id=o.address_id
WHERE s.shipper_name='DHL'
GROUP BY 1,2
ORDER BY No_of_customers DESC;


-- Question 6 
SELECT pro.PRODUCT_ID,
       pro.PRODUCT_DESC,
       SUM(pro.PRODUCT_QUANTITY_AVAIL) AS PRODUCT_QUANTITY_AVAIL,
       ord.PRODUCT_QUANTITY AS QUANTITY_SOLD,
	CASE
           WHEN pro_c.product_class_desc IN ('Electronics', 'Computer') THEN
               CASE
                   WHEN ord.PRODUCT_QUANTITY = 0 OR ord.PRODUCT_QUANTITY IS NULL THEN 'No Sales in past, give discount to reduce inventory'
                   WHEN pro.PRODUCT_QUANTITY_AVAIL < 0.1 * ord.PRODUCT_QUANTITY THEN 'Low inventory, need to add inventory'
                   WHEN pro.PRODUCT_QUANTITY_AVAIL < 0.5 * ord.PRODUCT_QUANTITY THEN 'Medium inventory, need to add some inventory'
                   ELSE 'Sufficient inventory'
               END
           WHEN pro_c.product_class_desc IN ('Mobiles', 'Watches') THEN
               CASE
                   WHEN ord.PRODUCT_QUANTITY = 0 OR ord.PRODUCT_QUANTITY IS NULL THEN 'No Sales in past, give discount to reduce inventory'
                   WHEN pro.PRODUCT_QUANTITY_AVAIL < 0.2 * ord.PRODUCT_QUANTITY THEN 'Low inventory, need to add inventory'
                   WHEN pro.PRODUCT_QUANTITY_AVAIL < 0.6 * ord.PRODUCT_QUANTITY THEN 'Medium inventory, need to add some inventory'
                   ELSE 'Sufficient inventory'
               END
           ELSE
               CASE
                   WHEN ord.PRODUCT_QUANTITY = 0 OR ord.PRODUCT_QUANTITY IS NULL THEN 'No Sales in past, give discount to reduce inventory'
                   WHEN pro.PRODUCT_QUANTITY_AVAIL < 0.3 * ord.PRODUCT_QUANTITY THEN 'Low inventory, need to add inventory'
				   WHEN pro.PRODUCT_QUANTITY_AVAIL < 0.7 * ord.PRODUCT_QUANTITY THEN 'Medium inventory, need to add some inventory'
                   ELSE 'Sufficient inventory'
               END
       END AS INVENTORY_STATUS
FROM product pro
INNER JOIN product_class pro_c ON pro.product_class_code = pro_c.product_class_code
INNER JOIN order_items ord ON pro.PRODUCT_ID = ord.PRODUCT_ID
GROUP BY pro.PRODUCT_ID, pro.PRODUCT_DESC, ord.PRODUCT_QUANTITY;

-- Question 7 Write a query to display order_id and volume of the biggest order (in terms of volume) that can fit in carton id 10
SELECT 
ord.ORDER_ID, 
(p.LEN*p.WIDTH*p.HEIGHT) PRODUCT_VOLUME
FROM product p JOIN order_items ord USING(PRODUCT_ID) 
WHERE (p.LEN*p.WIDTH*p.HEIGHT) <= (SELECT (c.LEN*c.WIDTH*c.HEIGHT)CARTON_VOLUME 
FROM carton c 
WHERE CARTON_ID=10)
ORDER BY PRODUCT_VOLUME DESC LIMIT 1;


-- Question 8 Write a query to display customer id, customer full name, total quantity and total value  (quantity*price) 
-- shipped where mode of payment is Cash and customer last name starts with 'G' 
SELECT c.CUSTOMER_ID, 
CONCAT(customer_fname,' ',customer_lname) AS 'NAME',
SUM(o.product_quantity) AS TOTAL_QUANTITY,
SUM(o.product_quantity*p.product_price) AS TOTAL_VALUE
FROM online_customer c 
JOIN order_header oh ON c.CUSTOMER_ID=oh.CUSTOMER_ID 
JOIN order_items o ON oh.ORDER_ID=o.ORDER_ID 
JOIN product p ON o.PRODUCT_ID=p.PRODUCT_ID 
WHERE PAYMENT_MODE='cash' AND CUSTOMER_LNAME LIKE 'G%'GROUP BY CUSTOMER_ID;


-- Question 9 Write a query to display product_id, product_desc and total quantity of products which are sold together 
-- with product id 201 and are not shipped to city Bangalore and New Delhi. Display the output in descending order with respect to the tot_qty.
SELECT 
p.PRODUCT_ID,
p.PRODUCT_DESC,
SUM(o.PRODUCT_QUANTITY) AS total_quantity 
FROM product p 
JOIN order_items o ON p.PRODUCT_ID=o.PRODUCT_ID 
JOIN order_header oh ON o.ORDER_ID=oh.ORDER_ID 
JOIN online_customer oc ON oh.CUSTOMER_ID=oc.CUSTOMER_ID 
JOIN address a ON oc.ADDRESS_ID=a.ADDRESS_ID 
WHERE o.ORDER_ID IN (SELECT o.ORDER_ID FROM order_items 
WHERE PRODUCT_ID='201' AND oh.ORDER_STATUS='shipped' AND a.CITY NOT IN ('Bangalore','New Delhi') )
GROUP BY p.PRODUCT_ID,p.PRODUCT_DESC 
ORDER BY total_quantity DESC;


-- Question 10 - Write a query to display the order_id,customer_id and customer fullname, total quantity of 
-- products shipped for order ids which are even and shipped to address where pincode is not starting with "5" 
SELECT
oh.ORDER_ID, 
oc.CUSTOMER_ID, 
concat(CUSTOMER_FNAME,' ',CUSTOMER_LNAME) AS FULL_NAME,
sum(o.PRODUCT_QUANTITY) AS TOTAL_QUANTITY 
FROM online_customer oc 
JOIN order_header oh ON oc.CUSTOMER_ID=oh.CUSTOMER_ID 
JOIN order_items o ON oh.ORDER_ID=o.ORDER_ID 
JOIN address a ON oc.ADDRESS_ID=a.ADDRESS_ID 
WHERE o.ORDER_ID %2= 0 AND a.PINCODE NOT LIKE '5%' GROUP BY 1,2;



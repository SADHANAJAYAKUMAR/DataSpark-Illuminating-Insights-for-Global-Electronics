use global_electronics
select * from  customer_data
select * from  exchange_rates_data
select * from  product_data
select * from  sales_data
select * from  stores_data

-- 1// overall gender counts;

SELECT 
    COUNT(CASE WHEN Gender = 'Female' THEN 1 END) AS Female_count,
    COUNT(CASE WHEN Gender = 'Male' THEN 1 END) AS Male_count
FROM customer_data;

-- overall counts form State,County ,Continent

SELECT 
    State,
    Country,
    Continent,
    COUNT(*) AS customer_count
FROM Customer_data
GROUP BY 
	State,Country,Continent;

--  overall age counts like minor,adult,old 

SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, Birthday, CURDATE()) BETWEEN 20 AND 39 THEN '20-39'
        WHEN TIMESTAMPDIFF(YEAR, Birthday, CURDATE()) BETWEEN 40 AND 59 THEN '40-59'
        WHEN TIMESTAMPDIFF(YEAR, Birthday, CURDATE()) BETWEEN 60 AND 79 THEN '60-79'
        WHEN TIMESTAMPDIFF(YEAR, Birthday, CURDATE()) >= 80 THEN '80 and above'
    END AS Age_Group,
    COUNT(*) AS Count_Age_Customers
FROM customer_data
GROUP BY Age_Group;

-- 2 //average order value, frequency of purchases, and preferred products.
SELECT c.CustomerKey,
       c.Gender,
       AVG(sd.Quantity * p.Unit_Price_USD) AS Avg_Order_Value,
       COUNT(DISTINCT sd.Order_Number) AS Purchase_Frequency,
       GROUP_CONCAT(DISTINCT p.Product_Name) AS Preferred_Products
FROM sales_data sd
JOIN customer_data c ON sd.CustomerKey = c.CustomerKey
JOIN product_data p ON sd.ProductKey = p.ProductKey
GROUP BY c.CustomerKey, c.Gender;

-- 3//  customers based on demographics and purchasing behavior based on customer group
SELECT 
    c.CustomerKey,
    c.Gender,
    FLOOR(DATEDIFF(CURDATE(), c.Birthday) / 365) AS Age,
    c.City, 
    c.Country,
    AVG(sd.Quantity * p.Unit_Price_USD) AS Avg_Order_Value,
    COUNT(DISTINCT sd.Order_Number) AS Purchase_Frequency
FROM 
    customer_data c
JOIN 
    sales_data sd ON c.CustomerKey = sd.CustomerKey
JOIN 
    product_data p ON sd.ProductKey = p.ProductKey
GROUP BY 
    c.CustomerKey, c.Gender, Age, c.City, c.Country;

-- 4// Overall sales in year
SELECT 
    YEAR(Order_Date) AS year,                 
    SUM(Quantity) AS total_quantity           
FROM 
    sales_data                                  
GROUP BY 
    year                                       
ORDER BY 
    year; 
    
-- 5// Brands sales analyze
SELECT 
    Brand,                                      
    SUM(Unit_Price_USD) AS total_sales,          
    COUNT(*) AS product_count                  
FROM 
    product_data                                
GROUP BY 
    Brand                                     
ORDER BY 
    total_sales DESC
LIMIT 5;
 
 -- 6//performance of different stores based on sales data
SELECT 
Storekey as storekey,
SUM(Quantity) AS total_quantity,
COUNT(*) AS Storecount
FROM sales_data
GROUP BY 
StoreKey 
ORDER BY
total_quantity DESC;

-- 7// currencycode contribution 
SELECT 
    Currency_Code, 
    SUM(Exchange) AS Total_Contribution
FROM exchange_rates_data
GROUP BY
 Currency_Code
ORDER BY 
Total_Contribution DESC;

-- 8// Counts Product Name, and Product						
Create Table joined_sales_product_data
SELECT 
    sd.Order_Number,
    sd.Line_Item,
    sd.Order_Date,
    sd.CustomerKey,
    sd.StoreKey,
    sd.ProductKey,
    pd.Product_Name,
    pd.Brand,
    pd.Color,
    pd.Unit_Cost_USD,
    pd.Unit_Price_USD,
    sd.Quantity,
    sd.Currency_Code,
    pd.Subcategory,
    pd.Category
FROM 
    sales_data sd
JOIN 
    product_data pd
ON 
    sd.ProductKey = pd.ProductKey;

SELECT 
    Product_Name,
    SUM(Quantity) AS Total_Sales
FROM 
    joined_sales_product_data
GROUP BY 
    Product_Name
ORDER BY 
    Total_Sales DESC
LIMIT 5;

SELECT 
    Product_Name,
    SUM(Quantity) AS Total_Sales
FROM 
    joined_sales_product_data
GROUP BY 
    Product_Name
ORDER BY 
    Total_Sales ASC
LIMIT 5;

-- 9//profit margins for products by comparing unit cost and unit price
SELECT 
    Product_Name,
    Unit_Cost_USD,
    Unit_Price_USD,
    (Unit_Price_USD - Unit_Cost_USD) AS Profit,
    ROUND(((Unit_Price_USD - Unit_Cost_USD) / Unit_Price_USD) * 100, 2) AS Profit_Margin_Percentage
FROM 
    product_data
ORDER BY 
    Profit_Margin_Percentage DESC;


-- 10// sales performance across different product categories and subcategories
SELECT 
    Category AS Product_Category,
    COUNT(Product_Name) AS Total_Products,
    SUM(Unit_Price_USD) AS Total_Sales_Revenue
FROM 
    product_data
GROUP BY 
    Category
ORDER BY 
    Total_Sales_Revenue DESC;
    
SELECT 
    Subcategory AS Product_Subcategory,
    COUNT(Product_Name) AS Total_Products,
    SUM(Unit_Price_USD) AS Total_Sales_Revenue
FROM 
    product_data
GROUP BY 
    Subcategory
ORDER BY 
    Total_Sales_Revenue DESC;
    
-- 11//store performance based on sales, size (square meters), and operational data (open date)
CREATE TABLE joined_sales_stores_data AS
SELECT 
    s.StoreKey,
    s.Country,
    s.State,
    s.Square_Meters,
    s.Open_Date,
    sd.Order_Number,
    sd.Line_Item,
    sd.Order_Date,
    sd.CustomerKey,
    sd.ProductKey,
    sd.Quantity,
    sd.Currency_Code
FROM 
    sales_data sd
JOIN 
    stores_data s
ON 
    sd.StoreKey = s.StoreKey;

SELECT 
    s.StoreKey,
    s.Country,
    s.State,
    s.Square_Meters,
    SUM(sd.Quantity) AS Total_Sales_Quantity,  -- Total quantity sold
    (SUM(sd.Quantity) / s.Square_Meters) AS Sales_Per_Square_Meter  -- Sales per square meter
FROM 
    joined_sales_product_data sd
JOIN 
    stores_data s
ON 
    sd.StoreKey = s.StoreKey
GROUP BY 
    s.StoreKey, s.Country, s.State, s.Square_Meters
ORDER BY 
    Sales_Per_Square_Meter DESC;

SELECT 
    s.StoreKey,
    s.Country,
    s.State,
    s.Open_Date,
    DATEDIFF(CURDATE(), s.Open_Date) AS Days_Opened,  -- Days since store opened
    SUM(sd.Quantity) AS Total_Sales_Quantity,  -- Total quantity sold
    (SUM(sd.Quantity) / DATEDIFF(CURDATE(), s.Open_Date)) AS Sales_Per_Day  -- Sales per day since opening
FROM 
    joined_sales_product_data sd
JOIN 
    stores_data s
ON 
    sd.StoreKey = s.StoreKey
GROUP BY 
    s.StoreKey, s.Country, s.State, s.Open_Date
HAVING 
    Days_Opened > 0  -- Only include stores that have been open for at least one day
ORDER BY 
    Sales_Per_Day DESC;  -- Order by sales per day in descending order


-- 12//	Total Counts of Stores by Square Meter
SELECT 
    s.Country, 
    s.State, 
    COUNT(DISTINCT sd.Order_Number) AS Total_Orders,
    SUM(sd.Quantity) AS Total_Quantity,
    AVG(s.Square_Meters) AS Avg_Store_Size,
    MIN(s.Open_Date) AS Earliest_Store_Open_Date
FROM 
    sales_data sd
JOIN 
    stores_data s 
    ON sd.StoreKey = s.StoreKey
GROUP BY 
    s.Country, 
    s.State
ORDER BY 
    Total_Quantity DESC;




    


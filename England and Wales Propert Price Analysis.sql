-- DATA PREPARATION -- 

SELECT *
FROM price_paid_property_data_uk;

-- -- Select the Dataset -- --
CREATE TABLE property_price_uk AS
SELECT *
FROM price_paid_property_data_uk
WHERE Date_of_Transfer > 2014;

SELECT *
FROM property_price_uk;



-- DATA CLEANING AND STANDARDIZE THE DATA --

-- -- Add the name of Property Type -- --
UPDATE property_price_uk
SET Property_Type =  CASE
	WHEN Property_Type = 'S' THEN 'Semi Detached'
    WHEN Property_Type = 'D' THEN 'Detached'
    WHEN Property_Type = 'F' THEN 'Flat'
    WHEN Property_Type = 'T' THEN 'Terrace'
    WHEN Property_Type = 'O' THEN 'Other'
    ELSE 'Unknown'
END;  

-- -- Add the name of Tenure Type -- --
UPDATE property_price_uk
SET Tenure = CASE
	WHEN Tenure = 'F' THEN 'Freehold'
    WHEN Tenure = 'L' THEN 'Leasehold'
    ELSE 'Unknown'
END 
;

-- -- Update the Building Status -- --
UPDATE price_paid_property_data_uk
SET New_Build_Flag = CASE
	WHEN New_Build_Flag = 'Y' THEN 'New'
    ELSE 'Existing'
END
;

-- -- Convert Date column to DATE format -- --
UPDATE property_price_uk
SET Date_of_Transfer = DATE(STR_TO_DATE(Date_of_Transfer, '%d/%m/%Y %H:%i'));

-- -- Add Rrgion Group column to separate London and Outside London -- --
ALTER TABLE property_price_uk 
ADD COLUMN Region_Group VARCHAR(50);

UPDATE property_price_uk
SET Region_Group = CASE
	WHEN County = 'GREATER LONDON' THEN 'London'
    ELSE 'Outside London'
END
;

-- DESCRIPTIVE ANALYSIS --

-- -- Average Property Price by Region and New Build Flag -- --
SELECT Region_Group,
	   New_Build_Flag,
	   Round(AVG(Price),2) AS Avg_House_Price
FROM property_price_uk
GROUP BY Region_Group, New_Build_Flag;

-- -- Average Price by Property Type -- --

SELECT Region_Group,
		Property_Type, 
		COUNT(*) AS Num_Transactions,
		ROUND(AVG(price),2) AS Avg_House_Price
FROM property_price_uk
GROUP BY Property_Type, Region_Group;

-- -- Quarterly Transactions by Tenure -- --
SELECT CONCAT(YEAR(Date_of_Transfer), '-Q', QUARTER(Date_of_Transfer)) AS Quarter,
		Tenure,
		ROUND(AVG(price),2) AS Avg_Price,
		COUNT(*) AS Num_Transactions
FROM property_price_uk
WHERE Date_of_Transfer > 2014
GROUP BY Quarter, Tenure
ORDER BY Quarter;

-- -- Price Trend Over Years by Property Type -- --
SELECT YEAR(Date_of_Transfer) AS Year,
		Property_Type,
		COUNT(*) AS Num_Transaction,
		ROUND(AVG(price),2) AS Avg_Price
FROM property_price_uk
GROUP BY Year, Property_Type;

-- -- Property Breakdown by Region -- --
WITH transaction_total
AS
(
SELECT Region_Group,
		COUNT(*) AS Transaction_count
FROM property_price_uk
GROUP BY Region_Group
)
SELECT YEAR(p.Date_of_Transfer),
		p.Region_Group,
		p.New_Build_Flag,
		p.Property_Type,
		p.County,
		p.Tenure,
		ROUND(AVG(p.Price),2) AS Avg_Price,
		COUNT(*) AS Transaction_Count,
		ROUND(((COUNT(*)/t.Transaction_count)*100),4) AS Property_Percentage
		FROM property_price_uk p
JOIN transaction_total t
	ON p.Region_Group = t.Region_Group
GROUP BY p.Region_Group, t.Transaction_count, p.New_Build_Flag, 
p.County, p.Tenure, p.Property_Type, YEAR(p.Date_of_Transfer)
ORDER BY p.Region_Group, Property_Percentage DESC
;

-- -- Top 10 Most and Least Expensive Counties -- --
SELECT County, 
		ROUND(Avg_Price,2) AS Avg_Price,
		'Most Expensive' AS Category
FROM 
	(SELECT County, 
			AVG(Price) AS Avg_Price
	FROM property_price_uk
	GROUP BY County
	ORDER BY AVG(Price) DESC
	LIMIT 10) AS Top_10
    
UNION ALL

SELECT County, 
		ROUND(Avg_Price,2) AS Avg_Price,
		'Least Expensive' AS Category
FROM (SELECT County, 
			AVG(Price) AS Avg_Price
FROM property_price_uk
GROUP BY County
ORDER BY AVG(Price) ASC
LIMIT 10) AS Bottom_10;
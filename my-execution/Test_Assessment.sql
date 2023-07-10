USE Class2_Descriptive_Analytics
GO

IF OBJECT_ID('fn_GetTransaction2Items') IS NOT NULL 
	DROP FUNCTION fn_GetTransaction2Items
GO

CREATE FUNCTION fn_GetTransaction2Items(@min INT, @max int)
RETURNS TABLE
AS
RETURN
(
	SELECT COUNT(*) AS [Transactions with >2 items]
	FROM
	(
		SELECT Invoice
		FROM RawData
		GROUP BY [Member Account Code], Invoice
		HAVING SUM([Sales Amt]) / 23000 >= @min AND SUM([Sales Amt]) / 23000 < @max AND SUM([Sales Qty]) > 1--BETWEEN AND TTVTT
	) Tmp
)
GO

IF OBJECT_ID('fn_GetResult') IS NOT NULL 
	DROP FUNCTION fn_GetResult
GO

CREATE FUNCTION fn_GetResult(@min INT, @max int)
RETURNS TABLE
AS
RETURN
(
	SELECT CASE
	 WHEN @min >= 50000 THEN 'PLATINUM'
	 WHEN @min>= 25000  THEN 'GOLD'
	 WHEN @min >= 10000  THEN 'SILVER'
	 WHEN @min >= 3000 THEN 'CLIENTING OR CT'
	 ELSE 'OTHERS'
	 END AS 'Segmentation',
	 A.*, B.*,
	 ROUND(A.[Total Sales] / A.[Total No.of Transactions], 2) AS ATV,
	 ROUND(A.[Total Items Sold] / A.[Total No.of Transactions], 2) AS UPT 
	FROM
	(
		SELECT COUNT(client_id) AS [Total no.of clients],
		   SUM(client_sale) AS  [Total Sales],
		   SUM(client_transaction)  AS [Total No.of Transactions],
		   SUM(client_item) AS [Total Items Sold]
		FROM
		(
			SELECT [Member Account Code] AS client_id,
			   ROUND(SUM([Sales Amt]) / 23000, 2) AS client_sale,
			   COUNT(DISTINCT Invoice) AS client_transaction,
			   SUM([Sales Qty]) AS client_item
		FROM RawData
		GROUP BY [Member Account Code]
		HAVING  SUM([Sales Amt]) / 23000 >= @min AND SUM([Sales Amt]) / 23000 < @max
		) Tmp
		) A CROSS APPLY fn_GetTransaction2Items(@min, @max) B	
)
GO

--My table result
SELECT *, 1 AS Rnk  FROM fn_GetResult(50000, 2147483647)
UNION
SELECT *, 2 AS Rnk FROM fn_GetResult(25000, 50000)
UNION
SELECT *, 3 AS Rnk  FROM fn_GetResult(10000, 25000)
UNION
SELECT *, 4 AS Rnk  FROM fn_GetResult(3000, 10000)
UNION
SELECT *, 5 AS Rnk  FROM fn_GetResult(-2147483648, 3000)
ORDER BY Rnk

--Question 1: Top 10 Member Account Code:
	--1.1. By Sales Quantity
		SELECT TOP 10 [Member Account Code] AS [Top 10 Member Account By Sales Quantity], 
			   SUM([Sales Qty]) AS [Total Sales Quantity] 
		FROM RawData 
		GROUP BY [Member Account Code] 
		ORDER BY SUM([Sales Qty]) DESC

	--1.2. By Sales Amount
		SELECT TOP 10 [Member Account Code] AS [Top 10 Member Account By Sales Amount], 
			   SUM([Sales Amt]) AS [Total Sales Quantity] 
		FROM RawData 
		GROUP BY [Member Account Code] 
		ORDER BY SUM([Sales Amt]) DESC

--Question 2:Analyze by Scheme Name
	--2.1. By Sales Quantity
		SELECT  [Scheme Name], SUM([Sales Qty]) AS [Total Sales Quantity], 
				AVG([Sales Qty]) AS [Average Sales Quantity Per Transaction] 
		FROM RawData 
		GROUP BY [Scheme Name]

	--2.1. By Sales Amount
		SELECT  [Scheme Name], SUM([Sales Amt]) AS [Total Sales Amount], 
				ROUND(AVG([Sales Amt]), 2) AS [Average Sales Amount Per Transaction] 
		FROM RawData 
		GROUP BY [Scheme Name]



--Q1a Determine the top 3 products in Dec 2014 in terms of total sales
SELECT * FROM(SELECT A.PRODUCT_ID AS "PRODUCT ID",B.PRODUCT_NAME AS "PRODUCT NAME", SUM(A.SALES) AS "SUM OF SALES" ,
DENSE_RANK() OVER (PARTITION BY EXTRACT(MONTH FROM T_DATE) ORDER BY SUM(SALES)DESC) AS "DRANK" 
FROM SALES_FACT A,TR_PRODUCT B WHERE T_DATE LIKE '%/12/14' AND A.PRODUCT_ID=B.PRODUCT_ID GROUP BY B.PRODUCT_NAME,A.PRODUCT_ID,EXTRACT(MONTH FROM A.T_DATE)) WHERE DRANK <4 ;
--Q1b Determine the top 3 stores in Dec 2014 in terms of total sales
SELECT * FROM(SELECT A.STORE_ID AS "STORE ID",B.STORE_NAME AS "STORE NAME" ,SUM(A.SALES) AS "SUM" FROM SALES_FACT A,TR_STORE B 
WHERE A.STORE_ID=B.STORE_ID AND A.T_DATE LIKE '%/12/14' GROUP BY A.STORE_ID,B.STORE_NAME  ORDER BY SUM(A.SALES) DESC) WHERE ROWNUM<4;
--Q2 Determine which store produced highest sales in the whole year?
SELECT * FROM(SELECT A.STORE_ID AS "STORE ID",B.STORE_NAME AS "STORE NAME",SUM(A.SALES) AS "SUM" FROM SALES_FACT A, TR_STORE B
WHERE A.STORE_ID=B.STORE_ID AND A.T_DATE LIKE '%/14' GROUP BY A.STORE_ID,B.STORE_NAME  ORDER BY SUM(SALES) DESC) WHERE ROWNUM<2;
--Q3 How many sales transactions were there for the product that generated maximum sales revenue in 2014? Also identify the a) product quantity sold and b) supplier name
SELECT NUM_SALES AS "NUMBER OF SALES",QUANTITY,SUPPLIER_NAME AS "SUPPLIER NAME"
FROM (SELECT ROWNUM AS ID,SUPPLIER_NAME FROM(SELECT SUPPLIER_NAME FROM SALES_FACT A,TR_SUPPLIER B
WHERE A.PRODUCT_ID=(SELECT * FROM(SELECT PRODUCT_ID FROM SALES_FACT GROUP BY PRODUCT_ID ORDER BY SUM(SALES) DESC) WHERE ROWNUM<2) 
AND A.SUPPLIER_ID=B.SUPPLIER_ID) WHERE ROWNUM<2)T1,
(SELECT ROWNUM AS ID,NUM_SALES,QUANTITY FROM(SELECT COUNT(*) AS "NUM_SALES",SUM(QUANTITY) AS "QUANTITY" FROM SALES_FACT
WHERE PRODUCT_ID=(SELECT * FROM(SELECT PRODUCT_ID FROM SALES_FACT GROUP BY PRODUCT_ID ORDER BY SUM(SALES) DESC) WHERE ROWNUM<2)) WHERE ROWNUM<2)T2
WHERE T1.ID=T2.ID;
--Q4 Present the quarterly sales analysis for all stores using drill down query concepts, resulting in a report
SELECT STORE_NAME AS "STORE NAME", Q1_2014,Q2_2014,Q3_2014,Q4_2014 FROM TR_STORE A,
(SELECT * FROM (SELECT STORE_ID, SUM(SALES) AS Q1_2014 FROM SALES_FACT WHERE T_DATE >='01/01/14' AND T_DATE <'01/04/14' GROUP BY STORE_ID))T1,
(SELECT * FROM (SELECT STORE_ID, SUM(SALES) AS Q2_2014 FROM SALES_FACT WHERE T_DATE >='01/04/14' AND T_DATE <'01/07/14' GROUP BY STORE_ID))T2,
(SELECT * FROM (SELECT STORE_ID, SUM(SALES) AS Q3_2014 FROM SALES_FACT WHERE T_DATE >='01/07/14' AND T_DATE <'01/10/14' GROUP BY STORE_ID))T3,
(SELECT * FROM (SELECT STORE_ID, SUM(SALES) AS Q4_2014 FROM SALES_FACT WHERE T_DATE >='01/10/14' AND T_DATE <'01/01/15' GROUP BY STORE_ID))T4
WHERE A.STORE_ID=T1.STORE_ID AND A.STORE_ID=T2.STORE_ID AND A.STORE_ID=T3.STORE_ID AND A.STORE_ID=T4.STORE_ID;
--Q5 Determine the top 3 products for a particular month (say Dec 2014), and for each of the 2 months before that, in terms of total sales
VAR MONTH VARCHAR2(20);
EXEC :MONTH := &INPUT_YOUR_MONTH;
SELECT T1.T_MONTH AS "MONTH", T1.PRODUCT_ID AS "PRODUCT ID",T1.PRODUCT_NAME AS "PRODUCT NAME",T1.SUM1 AS "SUM OF SALES", 
T2.T_MONTH AS"MONTH",T2.PRODUCT_ID AS "PRODUCT ID",T2.PRODUCT_NAME AS "PRODUCT NAME",T2.SUM2 AS " SUM OF SALES", 
T3.T_MONTH AS"MONTH",T3.PRODUCT_ID AS "PRODUCT ID",T3.PRODUCT_NAME AS "PRODUCT NAME",T3.SUM3 AS "SUM OF SALES" FROM
(SELECT ROWNUM AS ID,PRODUCT_ID, PRODUCT_NAME, SUM1,T_MONTH FROM(SELECT EXTRACT(MONTH FROM A.T_DATE) AS "T_MONTH", A.PRODUCT_ID,B.PRODUCT_NAME ,SUM(A.SALES) AS "SUM1" FROM SALES_FACT A, TR_PRODUCT B  
WHERE A.PRODUCT_ID=B.PRODUCT_ID AND EXTRACT(MONTH FROM A.T_DATE)=:MONTH  GROUP BY A.PRODUCT_ID,B.PRODUCT_NAME,EXTRACT(MONTH FROM A.T_DATE)  ORDER BY SUM(SALES) DESC) WHERE ROWNUM<4)T1 
LEFT OUTER JOIN
(SELECT ROWNUM AS ID,PRODUCT_ID, PRODUCT_NAME, SUM2,T_MONTH FROM(SELECT EXTRACT(MONTH FROM A.T_DATE) AS "T_MONTH",A.PRODUCT_ID,B.PRODUCT_NAME ,SUM(A.SALES) AS "SUM2" FROM SALES_FACT A, TR_PRODUCT B  
WHERE :MONTH-1>0 AND A.PRODUCT_ID=B.PRODUCT_ID AND EXTRACT(MONTH FROM A.T_DATE)=:MONTH-1  GROUP BY A.PRODUCT_ID,B.PRODUCT_NAME ,EXTRACT(MONTH FROM A.T_DATE) ORDER BY SUM(SALES) DESC) WHERE ROWNUM<4)T2 
ON (T1.ID=T2.ID)
LEFT OUTER JOIN 
(SELECT ROWNUM AS ID,PRODUCT_ID, PRODUCT_NAME, SUM3,T_MONTH FROM(SELECT EXTRACT(MONTH FROM A.T_DATE) AS "T_MONTH",A.PRODUCT_ID,B.PRODUCT_NAME ,SUM(A.SALES) AS "SUM3" FROM SALES_FACT A, TR_PRODUCT B  
WHERE :MONTH> 2 AND A.PRODUCT_ID=B.PRODUCT_ID AND EXTRACT(MONTH FROM A.T_DATE)=:MONTH-2  GROUP BY A.PRODUCT_ID,B.PRODUCT_NAME,EXTRACT(MONTH FROM A.T_DATE)  ORDER BY SUM(SALES) DESC) WHERE ROWNUM<4)T3
ON (T1.ID=T3.ID);


--Q6 Create a materialised view with name “STOREANALYSIS” that presents the productwise sales analysis for each store
DROP MATERIALIZED VIEW STOREANALYSIS;
CREATE MATERIALIZED VIEW STOREANALYSIS(STORE_ID,STORE_NAME,PRODUCT_QUANTITY,PRODUCT_SALES) 
AS SELECT A.STORE_ID,B.STORE_NAME,SUM(A.QUANTITY),SUM(A.SALES)
FROM SALES_FACT A,TR_STORE B WHERE A.STORE_ID=B.STORE_ID GROUP BY A.STORE_ID,B.STORE_NAME ORDER BY SUM(A.SALES) DESC;

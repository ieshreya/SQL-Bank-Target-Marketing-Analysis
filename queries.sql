-- SQL Bank Target Marketing Analysis

-- Schema Table
DROP TABLE IF EXISTS bank_df;

CREATE TABLE bank_df (
	age INT, 
	job VARCHAR(20), 
	marital VARCHAR(20), 
	education VARCHAR(20), 
	credit_default VARCHAR(10), 
	balance FLOAT, 
	housing VARCHAR(10),
  loan VARCHAR(10), 
  contact_type VARCHAR(20), 
  contact_day INT, 
  contact_month VARCHAR(10), 
  duration INT, 
  contact_count INT,
  pdays INT,
  previous INT, 
  poutcome VARCHAR(20), 
  deposit VARCHAR(10)
);


-- Descriptive Statistics
-- 1. What is the age distribution of customers?
SELECT MIN(age), MAX(age), AVG(age) 
FROM bank_df;

-- 2. What is the average yearly balance of customers in the dataset?
SELECT MIN(balance), MAX(balance), AVG(balance) 
FROM bank_df;

-- 3. What impact does the frequency of prior contact (pdays) have on customer engagement in the campaign?
SELECT pdays, COUNT(*) count
FROM bank_df
GROUP BY pdays
ORDER BY count DESC;


-- Categorical Data Analysis
-- 1. Job Distribution:  
SELECT job, COUNT(*) count
FROM bank_df
GROUP BY job
ORDER BY count DESC;

-- 2. Marital Status:  
SELECT marital, 
       COUNT(*) AS count, 
       ROUND((COUNT(*) / (SELECT COUNT(*) FROM bank_df)) * 100, 2) AS percentage
FROM bank_df
GROUP BY marital
ORDER BY count DESC;

-- 3. Education:  
SELECT education, COUNT(*) count
FROM bank_df
GROUP BY education
ORDER BY count DESC;

-- 4. Communication:  
SELECT contact_type, COUNT(*) count
FROM bank_df
GROUP BY contact_type 
ORDER BY count DESC;

-- 5. Monthly Trends: 
SELECT contact_month, COUNT(*) count
FROM bank_df
GROUP BY contact_month 
ORDER BY count DESC;


--  Data Transformation
-- 1. Adding a Primary Key column
ALTER TABLE bank_df
ADD client_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- 2. Combining columns
ALTER TABLE bank_df
ADD loan_type VARCHAR(20);
UPDATE bank_df
SET loan_type = 
  CASE 
    WHEN housing = 'yes' THEN 'housing-loan' 
    WHEN loan = 'yes' THEN 'personal-loan' 
    ELSE 'no loan' 
  END;


-- 3. Splitting columns
-- BY AGE
ALTER TABLE bank_df
ADD age_group VARCHAR(20);
UPDATE bank_df
SET age_group =
	CASE 
    WHEN age >= 18 AND age <= 25 THEN 'Young Adult'
    WHEN age > 25 AND age <= 34 THEN 'Early Career'
    WHEN age > 34 AND age <= 54 THEN 'Mid Career'
    WHEN age > 54 AND age <= 64 THEN 'Pre-Retirement'
    WHEN age > 64 THEN 'Retirement'
  END;


-- BY QUARTER
ALTER TABLE bank_df
ADD quarter VARCHAR(20);
UPDATE bank_df
SET quarter =
  CASE 
    WHEN contact_month IN ('jan', 'feb', 'mar') THEN 'Q1'
    WHEN contact_month IN ('apr', 'may', 'jun') THEN 'Q2'
    WHEN contact_month IN ('jul', 'aug', 'sep') THEN 'Q3'
    WHEN contact_month IN ('oct', 'nov', 'dec') THEN 'Q4'
  END;


-- SQL Data Analysis

-- 1. How many customers subscribed to a term deposit after the campaign? 
SELECT deposit, COUNT(*) AS total_subscribed 
FROM bank_df
GROUP BY deposit

-- 2. What percentage of customers subscribed to a term deposit after the marketing campaign?
SELECT COUNT(*) AS total_subscribed, 
       (COUNT(*) / (SELECT COUNT(*) FROM bank_df)) * 100 AS percent_subscribed
FROM bank_df
WHERE deposit = 'yes';

-- Subscribers with a balance above 0:
SELECT 
  SUM(CASE WHEN balance > 0 THEN 1 ELSE 0 END) AS positive_bal,
  SUM(CASE WHEN balance <= 0 THEN 1 ELSE 0 END) AS negative_bal 
FROM bank_df;


-- 3. What is the distribution of customers who subscribed to the term deposit based on their balance?
SELECT
  SUM(CASE WHEN deposit = 'yes' AND balance > 0 THEN 1 ELSE 0 END) AS positive_subscribed,
  SUM(CASE WHEN deposit = 'no' AND balance > 0 THEN 1 ELSE 0 END) AS positive_not_subscribed,
  SUM(CASE WHEN deposit = 'yes' AND balance <= 0 THEN 1 ELSE 0 END) AS negative_subscribed,
  SUM(CASE WHEN deposit = 'no' AND balance <= 0 THEN 1 ELSE 0 END) AS negative_not_subscribed
FROM bank_df;

-- Banks targeting customers with low balance: 
SELECT 
  COUNT(contact_count) AS times_called, 
  balance
FROM bank_df
WHERE deposit = 'yes'
GROUP BY balance
ORDER BY times_called DESC;


--  4. What are the demographic statistics of customers who subscribed to the term deposit despite having a negative balance?
-- Job Demographics:
SELECT job, COUNT(*) AS count
FROM bank_df
WHERE balance <= 0
  AND deposit = 'yes'
GROUP BY job
ORDER BY count DESC;

-- Age Demographics:
SELECT age_group, COUNT(*) count 
FROM bank_df
WHERE balance <= 0
AND deposit = 'yes'
GROUP BY age_group
ORDER BY count DESC;

--  5. Is there any impact of loan status on the subscription rates for term deposits?
SELECT 
  loan_type, 
  COUNT(*) AS count, 
  ROUND(COUNT(*) / 
    (SELECT COUNT(*) 
    FROM bank_df 
    WHERE deposit = 'yes' 
      AND balance > 0) * 100, 2) AS percent_subscribed
FROM bank_df
WHERE balance > 0
  AND deposit = 'yes'
GROUP BY loan_type
ORDER BY count;


--  6. Are there any seasonal trends for customer subscriptions?
-- Is there a correlation between the frequency of customer contacts and their subscription rate?
WITH cte AS (
  SELECT
    contact_month,
    COUNT(*) AS contact_count,
    SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS subscribed,
    SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS not_subscribed
  FROM bank_df
  GROUP BY contact_month
)
SELECT
  contact_month,
  contact_count,
  subscribed,
  not_subscribed,
  subscribed / contact_count call_to_subscriber_ratio
FROM cte
ORDER BY call_to_subscriber_ratio DESC;



--  7. Are there significant variations in the subscription ratio among customers?
WITH cte AS (
  SELECT
    job,
    SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS subscribed,
    SUM(CASE WHEN deposit = 'no' THEN 1 ELSE 0 END) AS not_subscribed
  FROM bank_df
  GROUP BY job
)
SELECT
  job,
  subscribed,
  not_subscribed,
  (subscribed / not_subscribed)*100 AS ratio
FROM cte
ORDER BY ratio DESC;


-- Are these preferred customers (students and retirees) reliable choices for term deposits?
SELECT job, credit_default, COUNT(*) AS count
FROM bank_df
WHERE deposit = 'yes'
  AND job IN ('student', 'retired')
GROUP BY job, credit_default
ORDER BY job, count DESC;


--  8. Are there any returning subscribers from previous campaigns?
-- Is there any relationship between the average yearly balance and the loan status of subscribers?
SELECT 
  loan_type, 
  MIN(balance), 
  MAX(balance)
FROM bank_df
WHERE deposit='yes'
GROUP BY loan_type
ORDER BY MAX(balance) DESC


--  9. How do past customer interactions affect the campaign outcomes?
WITH cte AS (
  SELECT DISTINCT poutcome, pdays
  FROM bank_df
)
SELECT 
  poutcome, 
  AVG(pdays) AS avg_pdays
FROM cte
GROUP BY poutcome
ORDER BY AVG(pdays) DESC;


--  10. What are the conversion rates across different customer segments by age group and quarter?
SELECT 
    quarter, 
    age_group,
    ROUND(AVG(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100, 2) AS success_conversion_rate,
    ROUND(AVG(CASE WHEN deposit = 'yes' AND pdays = -1 THEN 1 ELSE 0 END) * 100, 2) AS new_customer_conversion_rate,
    ROUND(AVG(CASE WHEN deposit = 'yes' AND poutcome LIKE '%failure%' THEN 1 ELSE 0 END) * 100, 2) AS potential_customer_conversion_rate
FROM bank_df
GROUP BY age_group, quarter
ORDER BY success_conversion_rate DESC;
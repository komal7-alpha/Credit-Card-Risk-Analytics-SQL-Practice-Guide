/* ============================================================
   SQL PRACTICE SET – PART 1 (FOUNDATION)
   Goal:
   - Basic to strong SQL for risk analytics
   - All explanations are comments only
   - Queries are runnable in SSMS
   ============================================================ */
   
/* ============================================================
   END OF PART 1
   Skills covered:
   - Basic joins
   - Filters
   - Aggregations
   - Risk behaviour logic
   - Credit card life cycle
   - Applications analysis
   - Portfolio exposure
   - Utilization
   - Delinquency
   - Monthly MIS
   - Customer, card, branch hierarchy
   - Exposure and utilization
   - Delinquency basics
   - Portfolio MIS
   - Risk hygiene checks
   - Credit card life cycle
   - Customers, cards, limits, billing, payments
   - Portfolio exposure and utilization
   - Delinquency basics
   - Monthly MIS
   - Application analysis
   - Attrition proxy
   - Data quality and sanity checks
   - End-to-end join confidence

   ============================================================ */

/* ============================================================
   QUESTION 1
   Show all active credit cards with customer name
   ============================================================ */

-- SQL QUESTION:
-- Show customer name, card id, card type, and card status for all active cards

SELECT
    c.customer_name,
    cc.card_id,
    cc.card_type,
    cc.card_status
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
WHERE cc.card_status = 'Active';

-- ENGLISH INTERVIEW ANSWER:
-- This query retrieves all active credit cards along with the associated customer
-- details by joining customer and card tables using the customer identifier.

-- HINGLISH EXPLANATION:
-- Pehle socha card ka data kaha hai → CREDIT_CARDS
-- Customer ka naam kaha hai → CUSTOMERS
-- Card customer se customer_id se linked hai
-- Active cards chahiye the isliye WHERE condition lagayi

-- HOW TO THINK ANALYTICALLY:
-- Business entity kya hai → Card
-- Extra attribute kya chahiye → Customer name
-- Relationship identify karo → customer_id
-- Filter hamesha end me lagta hai



/* ============================================================
   QUESTION 2
   Branch-wise number of customers
   ============================================================ */

-- SQL QUESTION:
-- Display each branch and the total number of customers associated with it

SELECT
    b.branch_name,
    COUNT(c.customer_id) AS total_customers
FROM BRANCHES b
JOIN CUSTOMERS c
    ON b.branch_id = c.branch_id
GROUP BY b.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the number of customers per branch by grouping
-- customer records at the branch level.

-- HINGLISH EXPLANATION:
-- Customer table me branch_id hota hai
-- Branch table lookup hai
-- Isliye branch aur customer ko join kiya
-- COUNT customers nikala aur branch ke level pe GROUP BY kiya

-- HOW TO THINK ANALYTICALLY:
-- Count kis cheez ka chahiye → Customers
-- Breakdown kis level pe → Branch
-- GROUP BY hamesha breakdown column pe hota hai



/* ============================================================
   QUESTION 3
   Total credit exposure (portfolio size)
   ============================================================ */

-- SQL QUESTION:
-- Calculate the total credit limit across all cards

SELECT
    SUM(credit_limit) AS total_credit_exposure
FROM CREDIT_LIMITS;

-- ENGLISH INTERVIEW ANSWER:
-- This query computes the total credit exposure by summing the credit
-- limits across all cards.

-- HINGLISH EXPLANATION:
-- Risk me exposure ka matlab hota hai maximum possible loss
-- Ye directly credit_limit se aata hai
-- Isliye kisi join ki zarurat nahi

-- HOW TO THINK ANALYTICALLY:
-- Exposure spend nahi hota, limit hota hai
-- Simple requirement → simple table
-- Join sirf tab jab value dusre table me ho



/* ============================================================
   QUESTION 4
   Identify high utilization risk cards
   ============================================================ */

-- SQL QUESTION:
-- Show cards where billed amount is greater than 90% of credit limit

SELECT
    b.card_id,
    b.billed_amount,
    l.credit_limit
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
WHERE b.billed_amount >= 0.9 * l.credit_limit;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards with high utilization by comparing billed
-- amounts against assigned credit limits.

-- HINGLISH EXPLANATION:
-- Billing aur limit alag tables me hain
-- Isliye card_id pe join kiya
-- 90% ek business threshold hai jo stress show karta hai

-- HOW TO THINK ANALYTICALLY:
-- Ratio based logic → comparison
-- Numerator kaha hai → billed_amount
-- Denominator kaha hai → credit_limit
-- Dono alag tables me ho toh join mandatory



/* ============================================================
   QUESTION 5
   Identify delinquent cards
   ============================================================ */

-- SQL QUESTION:
-- List all cards that have payment delays

SELECT DISTINCT
    card_id
FROM CARD_PAYMENTS
WHERE delay_months > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies delinquent cards by filtering payment records
-- where delay months are greater than zero.

-- HINGLISH EXPLANATION:
-- delay_months > 0 ka matlab late payment
-- Multiple months ho sakte hain isliye DISTINCT use kiya

-- HOW TO THINK ANALYTICALLY:
-- Risk ka sabse basic indicator → Delay
-- Delay data kaha hai → CARD_PAYMENTS
-- Duplicate avoid karne ke liye DISTINCT



/* ============================================================
   QUESTION 6
   Customers who are suddenly bad
   ============================================================ */

-- SQL QUESTION:
-- Identify cards that were on time earlier but delayed recently

SELECT
    card_id
FROM CARD_PAYMENTS
GROUP BY card_id
HAVING
    MAX(delay_months) > 0
    AND MIN(delay_months) = 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards that show recent delinquency after a
-- history of timely payments.

-- HINGLISH EXPLANATION:
-- Pehle delay nahi tha → MIN = 0
-- Ab delay aa gaya → MAX > 0
-- Ye pattern suddenly bad behaviour show karta hai

-- HOW TO THINK ANALYTICALLY:
-- Behaviour over time dekhna ho → GROUP BY
-- History analyse karni ho → aggregates
-- MIN aur MAX se behaviour pattern samajh aata hai



/* ============================================================
   QUESTION 7
   Always risky customers
   ============================================================ */

-- SQL QUESTION:
-- Identify cards that are consistently delinquent

SELECT
    card_id
FROM CARD_PAYMENTS
GROUP BY card_id
HAVING MIN(delay_months) > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards that have consistently exhibited
-- delinquent payment behavior.

-- HINGLISH EXPLANATION:
-- Agar har month delay hai
-- Toh minimum delay bhi zero se bada hoga
-- Matlab customer kabhi clean nahi tha

-- HOW TO THINK ANALYTICALLY:
-- Consistency check karni ho → MIN / MAX
-- Time-based behaviour SQL me aggregates se aata hai




   /* ============================================================
   SQL PRACTICE SET – PART 1 (FOUNDATION) – EXTENSION
   Purpose:
   - Cover remaining BASIC topics
   - Credit card life cycle
   - Applications analysis
   - Monthly portfolio reporting
   ============================================================ */


/* ============================================================
   QUESTION 8
   Credit card product life cycle – card vintage
   ============================================================ */

-- SQL QUESTION:
-- Show card id, card type and number of years since card was opened

SELECT
    card_id,
    card_type,
    DATEDIFF(YEAR, open_date, GETDATE()) AS card_age_years
FROM CREDIT_CARDS;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates card vintage by computing the number of years
-- since each credit card was opened.

-- HINGLISH EXPLANATION:
-- open_date se pata chalta hai card kitna purana hai
-- DATEDIFF use karke years nikal liye
-- Vintage analysis risk aur behaviour samajhne ke liye hota hai

-- HOW TO THINK ANALYTICALLY:
-- Life cycle ka matlab time dimension
-- Time calculate karna ho → DATEDIFF
-- Base table wahi hoti hai jisme date stored ho



/* ============================================================
   QUESTION 9
   New vs old cards distribution
   ============================================================ */

-- SQL QUESTION:
-- Classify cards as New or Old based on open date

SELECT
    card_id,
    CASE
        WHEN DATEDIFF(YEAR, open_date, GETDATE()) <= 2 THEN 'New Card'
        ELSE 'Old Card'
    END AS card_category
FROM CREDIT_CARDS;

-- ENGLISH INTERVIEW ANSWER:
-- This query classifies credit cards into new and old categories
-- based on their vintage.

-- HINGLISH EXPLANATION:
-- CASE WHEN ka use karke segmentation ki
-- 2 saal se kam → new
-- 2 saal se zyada → old
-- Ye segmentation risk models me common hoti hai

-- HOW TO THINK ANALYTICALLY:
-- Segmentation chahiye → CASE WHEN
-- Threshold business rule hota hai
-- Output simple labels me hona chahiye



/* ============================================================
   QUESTION 10
   Application approval vs rejection analysis
   ============================================================ */

-- SQL QUESTION:
-- Show count of approved and rejected applications

SELECT
    application_status,
    COUNT(application_id) AS total_applications
FROM CREDIT_APPLICATIONS
GROUP BY application_status;

-- ENGLISH INTERVIEW ANSWER:
-- This query summarizes application outcomes by counting approved
-- and rejected applications.

-- HINGLISH EXPLANATION:
-- application_status decision batata hai
-- Group by karke count nikal liya
-- Ye policy strictness aur portfolio quality dikhata hai

-- HOW TO THINK ANALYTICALLY:
-- Outcome analysis chahiye → GROUP BY status
-- Count use hota hai volume dekhne ke liye
-- Simple aggregation se MIS banta hai



/* ============================================================
   QUESTION 11
   Customer-wise application activity
   ============================================================ */

-- SQL QUESTION:
-- Show customers who have applied more than once

SELECT
    customer_id,
    COUNT(application_id) AS application_count
FROM CREDIT_APPLICATIONS
GROUP BY customer_id
HAVING COUNT(application_id) > 1;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies customers with multiple credit applications.

-- HINGLISH EXPLANATION:
-- Multiple applications financial stress ka signal ho sakta hai
-- Isliye customer level pe count kiya
-- HAVING use hota hai aggregate filter ke liye

-- HOW TO THINK ANALYTICALLY:
-- Repeat behaviour check karna ho → GROUP BY entity
-- Aggregate pe condition ho → HAVING
-- WHERE kabhi aggregate ke saath use nahi hota



/* ============================================================
   QUESTION 12
   Monthly portfolio billing report (basic MIS)
   ============================================================ */

-- SQL QUESTION:
-- Show total billed amount per month

SELECT
    billing_month,
    SUM(billed_amount) AS total_billed_amount
FROM CARD_BILLING
GROUP BY billing_month
ORDER BY billing_month;

-- ENGLISH INTERVIEW ANSWER:
-- This query produces a monthly portfolio billing summary
-- by aggregating billed amounts by month.

-- HINGLISH EXPLANATION:
-- Monthly report chahiye tha
-- billing_month pe group kiya
-- SUM se total portfolio spend nikala
-- ORDER BY se timeline clear hoti hai

-- HOW TO THINK ANALYTICALLY:
-- MIS ka matlab aggregation + time
-- Month-wise trend chahiye → GROUP BY date
-- ORDER BY timeline dikhane ke liye



/* ============================================================
   QUESTION 13
   Average billing per card
   ============================================================ */

-- SQL QUESTION:
-- Calculate average billed amount per card

SELECT
    card_id,
    AVG(billed_amount) AS avg_billed_amount
FROM CARD_BILLING
GROUP BY card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the average monthly spending per card.

-- HINGLISH EXPLANATION:
-- Har card ka spending behaviour samajhna tha
-- Isliye card_id pe group kiya
-- AVG spending pattern dikhata hai

-- HOW TO THINK ANALYTICALLY:
-- Behaviour analysis ho → AVG useful hota hai
-- Entity level pe group karna hota hai
-- Simple metric se insight milta hai

/* ============================================================
   SQL PRACTICE SET – PART 1 (FOUNDATION) – FINAL BASIC EXTENSION
   Purpose:
   - Close all remaining BASIC topics from JD
   - Portfolio, exposure, variance, hygiene checks
   ============================================================ */


/* ============================================================
   QUESTION 14
   Customer-level portfolio exposure
   ============================================================ */

-- SQL QUESTION:
-- Show total credit limit per customer

SELECT
    c.customer_id,
    c.customer_name,
    SUM(l.credit_limit) AS total_customer_exposure
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
GROUP BY
    c.customer_id,
    c.customer_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates total credit exposure at the customer level
-- by summing credit limits across all cards owned by the customer.

-- HINGLISH EXPLANATION:
-- Customer ke paas multiple cards ho sakte hain
-- Exposure card level pe hota hai
-- Customer view chahiye tha isliye SUM + GROUP BY customer

-- HOW TO THINK ANALYTICALLY:
-- Exposure kis level pe chahiye → Customer
-- Exposure kaha stored hai → Credit limit
-- Multiple rows ko ek banana ho → GROUP BY



/* ============================================================
   QUESTION 15
   Branch-wise credit exposure
   ============================================================ */

-- SQL QUESTION:
-- Show total credit limit exposure per branch

SELECT
    b.branch_name,
    SUM(l.credit_limit) AS branch_credit_exposure
FROM BRANCHES b
JOIN CUSTOMERS c
    ON b.branch_id = c.branch_id
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
GROUP BY b.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query summarizes credit exposure at the branch level by
-- aggregating credit limits of all cards issued under each branch.

-- HINGLISH EXPLANATION:
-- Risk kabhi bhi sirf individual nahi hota
-- Branch concentration bhi important hota hai
-- Isliye branch → customer → card → limit join flow use kiya

-- HOW TO THINK ANALYTICALLY:
-- Geography wise risk chahiye → Branch
-- Exposure metric chahiye → Limit
-- Natural hierarchy follow karo joins me



/* ============================================================
   QUESTION 16
   Basic delinquency ratio (proxy default view)
   ============================================================ */

-- SQL QUESTION:
-- Show total cards and number of delinquent cards

SELECT
    COUNT(DISTINCT card_id) AS total_cards,
    COUNT(DISTINCT CASE WHEN delay_months > 0 THEN card_id END)
        AS delinquent_cards
FROM CARD_PAYMENTS;

-- ENGLISH INTERVIEW ANSWER:
-- This query provides a high-level delinquency view by comparing
-- delinquent cards against the total card base.

-- HINGLISH EXPLANATION:
-- Written test me direct default rate nahi hota
-- Delay ko proxy bana ke delinquency nikala jata hai
-- CASE WHEN se conditional count kiya

-- HOW TO THINK ANALYTICALLY:
-- Ratio banana ho → numerator + denominator
-- Condition count karni ho → CASE WHEN
-- DISTINCT duplicates avoid karta hai



/* ============================================================
   QUESTION 17
   Identify inactive or non-performing cards
   ============================================================ */

-- SQL QUESTION:
-- List cards that have no billing records

SELECT
    cc.card_id
FROM CREDIT_CARDS cc
LEFT JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
WHERE b.card_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies inactive cards by checking for cards
-- with no associated billing activity.

-- HINGLISH EXPLANATION:
-- Agar card hai but billing nahi
-- Matlab usage nahi ho raha
-- LEFT JOIN + NULL check classic pattern hai

-- HOW TO THINK ANALYTICALLY:
-- Missing activity check karni ho → LEFT JOIN
-- NULL ka matlab no match
-- Hygiene / monitoring questions me ye common hai



/* ============================================================
   QUESTION 18
   Billing vs limit variance (basic risk signal)
   ============================================================ */

-- SQL QUESTION:
-- Show difference between credit limit and billed amount

SELECT
    b.card_id,
    l.credit_limit,
    b.billed_amount,
    (l.credit_limit - b.billed_amount) AS available_limit
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the remaining available credit by comparing
-- billed amounts with assigned credit limits.

-- HINGLISH EXPLANATION:
-- Limit aur spend ka gap important hota hai
-- Gap kam hota ja raha hai → stress badh raha hai
-- Simple subtraction se insight milta hai

-- HOW TO THINK ANALYTICALLY:
-- Variance matlab difference
-- Values alag tables me ho → join
-- Derived column se signal banta hai

/* ============================================================
   SQL PRACTICE SET – PART 1 (FOUNDATION)
   FINAL BASIC ADD-ON (LAST)
   Purpose:
   - Data sanity
   - Attrition basics
   - End-to-end join confidence
   ============================================================ */


/* ============================================================
   QUESTION 19
   Data sanity check – cards without customers
   ============================================================ */

-- SQL QUESTION:
-- Check if any credit cards exist without a valid customer

SELECT
    cc.card_id
FROM CREDIT_CARDS cc
LEFT JOIN CUSTOMERS c
    ON cc.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query checks data integrity by identifying credit cards
-- that are not linked to any valid customer.

-- HINGLISH EXPLANATION:
-- Card bina customer ke hona possible nahi hona chahiye
-- LEFT JOIN + NULL check se data issue detect hota hai

-- HOW TO THINK ANALYTICALLY:
-- Foundation check chahiye → LEFT JOIN
-- NULL ka matlab orphan record
-- Interviewers data hygiene pe dhyan dete hain



/* ============================================================
   QUESTION 20
   Data sanity check – cards without credit limits
   ============================================================ */

-- SQL QUESTION:
-- Identify cards that do not have assigned credit limits

SELECT
    cc.card_id
FROM CREDIT_CARDS cc
LEFT JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
WHERE l.card_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies credit cards that do not have an assigned
-- credit limit, which represents a data or setup issue.

-- HINGLISH EXPLANATION:
-- Card hai lekin limit nahi hai → system issue
-- Risk system me ye allowed nahi hota

-- HOW TO THINK ANALYTICALLY:
-- Mandatory relationship verify karo
-- LEFT JOIN use karo
-- NULL ka matlab missing configuration



/* ============================================================
   QUESTION 21
   Inactive customers (attrition proxy – BASIC)
   ============================================================ */

-- SQL QUESTION:
-- Identify customers whose cards have no billing activity

SELECT DISTINCT
    c.customer_id,
    c.customer_name
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
LEFT JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
WHERE b.card_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies inactive customers whose credit cards
-- have no billing activity, serving as a basic attrition proxy.

-- HINGLISH EXPLANATION:
-- Customer hai, card hai
-- Lekin billing nahi ho rahi
-- Matlab customer disengaged ho sakta hai

-- HOW TO THINK ANALYTICALLY:
-- Attrition ka matlab usage band hona
-- Usage kaha dikhta hai → Billing
-- LEFT JOIN + NULL se inactivity detect hoti hai



/* ============================================================
   QUESTION 22
   End-to-end base portfolio view (confidence query)
   ============================================================ */

-- SQL QUESTION:
-- Show customer, card, and credit limit together

SELECT
    c.customer_name,
    cc.card_id,
    cc.card_type,
    l.credit_limit
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query creates a base portfolio view by combining customer,
-- card, and credit limit information.

-- HINGLISH EXPLANATION:
-- Ye query interview me confidence dikhati hai
-- Customer → Card → Limit ka complete flow clear hota hai

-- HOW TO THINK ANALYTICALLY:
-- Base portfolio ka grain → Card
-- Dimensions → Customer
-- Measures → Credit limit
-- Natural hierarchy follow karni hoti hai




 





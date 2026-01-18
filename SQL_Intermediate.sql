/* ============================================================
   SQL PRACTICE SET – PART 2 (INTERMEDIATE)
   Goal:
   - Trend analysis
   - Ratios & KPIs
   - Portfolio comparison
   - Risk interpretation
   - Trend Growth % calculation
   - Payment behaviour segmentation
   - Ratios comparing months
   - Branch exposure comparison
   - Mixed risk signals
   - Customer-level view
   - Action-oriented outputs
   ============================================================ */


/* ============================================================
   QUESTION 1
   Month-on-Month billing trend
   ============================================================ */

-- SQL QUESTION:
-- Show total billed amount month-wise and observe trend

SELECT
    billing_month,
    SUM(billed_amount) AS total_billed_amount
FROM CARD_BILLING
GROUP BY billing_month
ORDER BY billing_month;

-- ENGLISH INTERVIEW ANSWER:
-- This query analyzes month-on-month portfolio spending by aggregating
-- billed amounts for each billing month.

-- HINGLISH EXPLANATION:
-- Portfolio ka trend samajhne ke liye time dimension lagta hai
-- billing_month pe GROUP BY kiya
-- SUM se total spend nikala
-- ORDER BY se growth / decline dikhta hai

-- HOW TO THINK ANALYTICALLY:
-- Trend ka matlab time-> Value increase ho rahi hai ya decrease,Change slow hai ya sudden,Pattern consistent hai ya irregular
-- Time-based questions → GROUP BY date
-- ORDER BY hamesha trend clarity ke liye



/* ============================================================
   QUESTION 2
   Month-on-Month change (increase or decrease)
   ============================================================ */

-- SQL QUESTION:
-- Compare current month billing with previous month

SELECT
    b1.billing_month AS current_month,
    b1.total_billed_amount AS current_billing,
    b2.total_billed_amount AS previous_billing,
    (b1.total_billed_amount - b2.total_billed_amount) AS month_difference
FROM
(
    SELECT billing_month, SUM(billed_amount) AS total_billed_amount
    FROM CARD_BILLING
    GROUP BY billing_month
) b1
LEFT JOIN
(
    SELECT billing_month, SUM(billed_amount) AS total_billed_amount
    FROM CARD_BILLING
    GROUP BY billing_month
) b2
ON DATEADD(MONTH, -1, b1.billing_month) = b2.billing_month
ORDER BY b1.billing_month;

-- ENGLISH INTERVIEW ANSWER:
-- This query compares current month billing with the previous month
-- to identify increases or decreases in portfolio usage.

-- HINGLISH EXPLANATION:
-- Management ko sirf total nahi, change chahiye hota hai
-- Isliye same data ko self join kiya
-- DATEADD se previous month nikala

-- HOW TO THINK ANALYTICALLY:
-- Comparison chahiye → self join
-- Time shift chahiye → DATEADD
-- Difference se direction samajh aati hai



/* ============================================================
   QUESTION 3
   Average utilization ratio per card
   ============================================================ */

-- SQL QUESTION:
-- Calculate average utilization (billed amount / credit limit)

SELECT
    b.card_id,
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_utilization_ratio
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
GROUP BY b.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the average credit utilization ratio per card,
-- which is a key indicator of credit risk and spending behavior.

-- HINGLISH EXPLANATION:
-- Utilization = spend / limit
-- Risk analytics me ye sabse important ratio hota hai
-- CAST isliye use kiya taki integer division na ho

-- HOW TO THINK ANALYTICALLY:
-- Ratio question ho → numerator / denominator
-- Alag tables me ho → join
-- AVG lagake stable behaviour dekha jata hai



/* ============================================================
   QUESTION 4
   Branch-wise utilization comparison
   ============================================================ */

-- SQL QUESTION:
-- Show average utilization by branch

SELECT
    br.branch_name,
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_branch_utilization
FROM BRANCHES br
JOIN CUSTOMERS c
    ON br.branch_id = c.branch_id
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
GROUP BY br.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query compares average credit utilization across branches
-- to identify regional risk concentration.

-- HINGLISH EXPLANATION:
-- Utilization branch-wise dekhna concentration risk ke liye hota hai
-- Natural hierarchy follow ki:
-- Branch → Customer → Card → Billing → Limit

-- HOW TO THINK ANALYTICALLY:
-- Comparison kis level pe → Branch
-- Metric kya hai → Utilization
-- Hierarchy ke order me joins lagao



/* ============================================================
   QUESTION 5
   Delinquency rate (intermediate view)
   ============================================================ */

-- SQL QUESTION:
-- Calculate delinquency percentage at card level

SELECT
    COUNT(DISTINCT CASE WHEN delay_months > 0 THEN card_id END) * 100.0
    / COUNT(DISTINCT card_id) AS delinquency_percentage
FROM CARD_PAYMENTS;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the delinquency rate by dividing the number
-- of delinquent cards by the total number of cards.

-- HINGLISH EXPLANATION:
-- Rate banana ho toh percentage nikalna padta hai
-- CASE WHEN se delinquent cards count kiye
-- Total cards se divide kiya

-- HOW TO THINK ANALYTICALLY:
-- Rate = part / whole
-- Conditional count ke liye CASE WHEN
-- Percentage ke liye 100.0 multiply



/* ============================================================
   QUESTION 6
   Branch-wise delinquency comparison
   ============================================================ */

-- SQL QUESTION:
-- Show delinquent card count per branch

SELECT
    br.branch_name,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END)
        AS delinquent_cards
FROM BRANCHES br
JOIN CUSTOMERS c
    ON br.branch_id = c.branch_id
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY br.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query compares delinquent card counts across branches
-- to identify higher-risk regions.

-- HINGLISH EXPLANATION:
-- Risk ka distribution branch-wise samajhna zaroori hota hai
-- LEFT JOIN isliye kiya kyunki payment record missing ho sakta hai

-- HOW TO THINK ANALYTICALLY:
-- Risk comparison chahiye → GROUP BY branch
-- Conditional logic → CASE WHEN
-- Missing data ho sakta hai → LEFT JOIN



/* ============================================================
   QUESTION 7
   Portfolio optimization signal
   ============================================================ */

-- SQL QUESTION:
-- Identify cards eligible for limit increase
-- Condition: High utilization but no delinquency

SELECT DISTINCT
    b.card_id
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
GROUP BY b.card_id, l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8
    AND MAX(ISNULL(p.delay_months, 0)) = 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards with high utilization and clean payment
-- history, which are potential candidates for limit enhancement.

-- HINGLISH EXPLANATION:
-- Optimization ka matlab sirf risk kam karna nahi
-- Good customers ko reward karna bhi hota hai
-- High usage + no delay = positive signal

-- HOW TO THINK ANALYTICALLY:
-- Optimization questions me positive + negative dono signals dekho
-- Utilization se demand
-- Delay se risk
-- Dono combine karke decision nikalo


/* ============================================================
   QUESTION 8
   Compare billing trend for each card over months
   ============================================================ */

-- SQL QUESTION:
-- Show billing month and billed amount for each card,
-- ordered by card, then month.

SELECT
    card_id,
    billing_month,
    billed_amount
FROM CARD_BILLING
ORDER BY card_id, billing_month;

-- ENGLISH INTERVIEW ANSWER:
-- This query lists billing activity per card across months
-- so we can observe month-wise billing patterns for each card.

-- HINGLISH EXPLANATION:
-- Kabhi kabhi sirf aggregated value se kaam nahi chal pata.
-- Card ka individual month behaviour dekhna padta hai.
-- ORDER BY se pehle card aur phir month ka sequence clear hota hai.

-- HOW TO THINK ANALYTICALLY:
-- Trend analysis me detail level data chahiye.
-- Billing me month + entity (card) dono important.
-- ORDER BY se pattern dekhna easy hota hai.



/* ============================================================
   QUESTION 9
   Top 3 customers by total billed amount
   ============================================================ */

-- SQL QUESTION:
-- Find top 3 customers with highest total billed amounts.

SELECT TOP 3
    c.customer_id,
    c.customer_name,
    SUM(b.billed_amount) AS total_billed
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
GROUP BY c.customer_id, c.customer_name
ORDER BY SUM(b.billed_amount) DESC;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies the top 3 customers with the highest
-- aggregated spend on their credit cards.

-- HINGLISH EXPLANATION:
-- Customer ke total billing ko sum kiya,
-- phir descending order me top users nikal liye.
-- Ye portfolio ke big spenders ko highlight karta hai.

-- HOW TO THINK ANALYTICALLY:
-- Rank based questions me ORDER BY DESC aur TOP N use hota hai.
-- Entity level (customer) pe group karna hota hai.



/* ============================================================
   QUESTION 10
   Who has highest delinquency count?
   ============================================================ */

-- SQL QUESTION:
-- Find card with the most months of delay.

SELECT TOP 1
    card_id,
    COUNT(*) AS times_delayed
FROM CARD_PAYMENTS
WHERE delay_months > 0
GROUP BY card_id
ORDER BY COUNT(*) DESC;

-- ENGLISH INTERVIEW ANSWER:
-- This query finds the card that has been late on payment
-- most often — a basic indicator of risk concentration.

-- HINGLISH EXPLANATION:
-- delay_months > 0 filter lagaya,
-- phir count karke order kiya.
-- Top 1 se sabse risky behaviour wale card mil jate hain.

-- HOW TO THINK ANALYTICALLY:
-- Risk concentration dekhna ho → COUNT + ORDER BY
-- delay_months > 0 is core risk signal.



/* ============================================================
   QUESTION 11
   Simple branch-wise default heat (intermediate)
   ============================================================ */

-- SQL QUESTION:
-- For each branch, calculate the number of delinquent cards
-- and overall cards in that branch.

SELECT
    br.branch_name,
    COUNT(DISTINCT cc.card_id) AS total_cards,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END)
        AS delinquent_card_count
FROM BRANCHES br
JOIN CUSTOMERS c
    ON br.branch_id = c.branch_id
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY br.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query shows, for each branch, how many cards exist
-- and how many of them have shown payment delays.

-- HINGLISH EXPLANATION:
-- Branch ka perspective milta hai portfolio risk pe.
-- Total cards nikal ke, unme se delay wale ko conditional count kiya.

-- HOW TO THINK ANALYTICALLY:
-- Branch-wise comparison me GROUP BY branch_name,
-- Risk indicator p.delay_months > 0 ke liye conditional CASE.



/* ============================================================
   QUESTION 12
   Billing trend ratio month-over-month
   ============================================================ */

-- SQL QUESTION:
-- Calculate growth rate (%) of total billed amounts month-over-month.

SELECT
    b1.billing_month AS current_month,
    b1.total_billed AS current_total,
    b2.total_billed AS prev_total,
    CASE
        WHEN b2.total_billed = 0 THEN NULL
        ELSE ((b1.total_billed - b2.total_billed) * 1.0 / b2.total_billed) * 100
    END AS growth_percentage
FROM
(
    SELECT billing_month, SUM(billed_amount) AS total_billed
    FROM CARD_BILLING
    GROUP BY billing_month
) b1
LEFT JOIN
(
    SELECT billing_month, SUM(billed_amount) AS total_billed
    FROM CARD_BILLING
    GROUP BY billing_month
) b2
ON DATEADD(MONTH, -1, b1.billing_month) = b2.billing_month
ORDER BY b1.billing_month;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates month-over-month growth percentages for billing
-- which is a basic trend KPI used in portfolio monitoring.

-- HINGLISH EXPLANATION:
-- Prev month ka total b2 me join karke current se compare kiya.
-- Growth percent nikalna ho to difference / prev * 100 ka formula use hota hai.

-- HOW TO THINK ANALYTICALLY:
-- Trend % questions me self join aur CASE WHEN for division safely.



/* ============================================================
   QUESTION 13
   Payment behaviour segmentation
   ============================================================ */

-- SQL QUESTION:
-- Tag cards as good payers or bad payers based on delay history:
-- Good: no delays ever, Bad: at least one delay.

SELECT
    cc.card_id,
    CASE
        WHEN MIN(p.delay_months) = 0 AND MAX(p.delay_months) = 0
            THEN 'Good Payer'
        ELSE 'Bad Payer'
    END AS payment_behavior
FROM CREDIT_CARDS cc
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY cc.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query segments credit cards into good and bad payers based on
-- whether they have ever shown a payment delay.

-- HINGLISH EXPLANATION:
-- Agar min aur max both 0 hain → kabhi delay nahi hua → good.
-- Else → bad.
-- Simple victim / non-victim behavior categorization.

-- HOW TO THINK ANALYTICALLY:
-- Behavior based segmentation me MIN and MAX are key aggregates.



/* ============================================================
   QUESTION 14
   Monthly delinquency rate
   ============================================================ */

-- SQL QUESTION:
-- For each billing month, calculate the percentage of cards
-- that were delinquent in that month.

SELECT
    p.payment_month,
    CAST(
        COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN p.card_id END) * 100.0
        / COUNT(DISTINCT p.card_id)
        AS DECIMAL(5,2)
    ) AS delinquency_rate
FROM CARD_PAYMENTS p
GROUP BY p.payment_month
ORDER BY p.payment_month;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the delinquency rate by month, which
-- helps in understanding monthly risk trends.

-- HINGLISH EXPLANATION:
-- Month-wise delinquency ratio is a core KPI in risk MIS.
-- Distinct card count avoid duplicates.

-- HOW TO THINK ANALYTICALLY:
-- Month time dimension + percentage calculation required.
-- Distinct used to avoid counting card multiple times per month.

/* ============================================================
   QUESTION 15
   Customer-level risk summary
   ============================================================ */

-- SQL QUESTION:
-- Show customer-wise total cards, total limit, and delinquent cards count

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT cc.card_id) AS total_cards,
    SUM(l.credit_limit) AS total_credit_limit,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END)
        AS delinquent_cards
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY c.customer_id, c.customer_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query provides a consolidated customer-level risk view by
-- combining exposure and delinquency information.

-- HINGLISH EXPLANATION:
-- Manager customer ko ek row me dekhna chahta hai
-- Kitne cards, kitna limit, aur kitne problematic
-- Isliye sab metrics ek saath nikale

-- HOW TO THINK ANALYTICALLY:
-- Decision customer level pe hota hai
-- Card-level data ko aggregate karke customer view banao



/* ============================================================
   QUESTION 16
   Mixed signal analysis – high usage but delayed
   ============================================================ */

-- SQL QUESTION:
-- Identify cards with high utilization and payment delays

SELECT DISTINCT
    b.card_id
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
GROUP BY b.card_id, l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8
    AND MAX(p.delay_months) > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards showing both high utilization and
-- payment delays, which is a strong combined risk signal.

-- HINGLISH EXPLANATION:
-- High usage akela bura nahi
-- Delay akela bhi kabhi kabhi ho jata hai
-- Dono saath me ho → serious risk

-- HOW TO THINK ANALYTICALLY:
-- Risk assessment me signals combine hote hain
-- Single metric pe decision nahi hota



/* ============================================================
   QUESTION 17
   Limit increase eligibility – rule based
   ============================================================ */

-- SQL QUESTION:
-- Identify cards eligible for limit increase
-- Rule: High utilization AND no delinquency

SELECT
    b.card_id
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
GROUP BY b.card_id, l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) >= 0.75
    AND MAX(ISNULL(p.delay_months, 0)) = 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards that show strong usage demand
-- and clean payment behavior, making them suitable for limit enhancement.

-- HINGLISH EXPLANATION:
-- Good customer ka signal:
-- Use bhi karta hai
-- Delay bhi nahi karta
-- Business ko growth opportunity milti hai

-- HOW TO THINK ANALYTICALLY:
-- Optimization ka matlab sirf risk cut nahi
-- Good customers ko grow karna bhi hota hai



/* ============================================================
   QUESTION 18
   Limit reduction candidates
   ============================================================ */

-- SQL QUESTION:
-- Identify cards with low usage and repeated delinquency

SELECT
    b.card_id
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
GROUP BY b.card_id, l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) < 0.3
    AND COUNT(CASE WHEN p.delay_months > 0 THEN 1 END) >= 2;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards with low utilization and repeated delays,
-- which are candidates for credit limit reduction.

-- HINGLISH EXPLANATION:
-- Customer limit use bhi nahi karta
-- Upar se delay bhi karta hai
-- Exposure kam karna logical hota hai

-- HOW TO THINK ANALYTICALLY:
-- Negative behaviour + low business value
-- Risk-return balance dekhna hota hai



/* ============================================================
   QUESTION 19
   Early warning signal – first time delinquency
   ============================================================ */

-- SQL QUESTION:
-- Identify cards where first ever delay occurred recently

SELECT
    card_id
FROM CARD_PAYMENTS
GROUP BY card_id
HAVING
    MIN(delay_months) = 0
    AND MAX(delay_months) = 1;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards showing early signs of stress,
-- where the first payment delay has recently occurred.

-- HINGLISH EXPLANATION:
-- Ye customer abhi kharab nahi hua
-- Par signal aa gaya hai
-- Monitoring list ke liye perfect candidate

-- HOW TO THINK ANALYTICALLY:
-- Early warning me extreme values nahi hote
-- Pattern change important hota hai



/* ============================================================
   QUESTION 20
   Action list for monitoring
   ============================================================ */

-- SQL QUESTION:
-- Create a monitoring list of cards with any risk signal

SELECT DISTINCT
    cc.card_id,
    cc.card_type
FROM CREDIT_CARDS cc
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
LEFT JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
LEFT JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
WHERE
    p.delay_months > 0
    OR CAST(b.billed_amount AS FLOAT) / l.credit_limit > 0.9;

-- ENGLISH INTERVIEW ANSWER:
-- This query creates a monitoring list of cards that show
-- either delinquency or very high utilization.

-- HINGLISH EXPLANATION:
-- Real systems me ek monitoring bucket hota hai
-- Jahan risky cards ko daily / weekly dekha jata hai

-- HOW TO THINK ANALYTICALLY:
-- Action-oriented output banao
-- Sirf analysis nahi, list chahiye hoti hai




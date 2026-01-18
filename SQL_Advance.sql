/* ============================================================
   SQL PRACTICE SET – PART 3 (ADVANCED)
   Goal:
   - Case-style thinking
   - Multi-signal risk logic
   - Decision & recommendation outputs
   - Senior-level reasoning
   - Causality thinking
   - Scenario comparison
   - Policy-level logic
   - Interview-grade depth
   - Counterfactuals
   - Cohort comparison
   - Policy calibration
   - Interview-grade depth
   - Causality vs correlation
   - Control groups
   - Management-style “why” answers
   - Interview differentiation
   - Edge cases
   - Interview follow-ups
   - Decision defensibility
   - Interview pressure questions
   - Defensive reasoning
   - “Why this, not that?”
   ============================================================ */


/* ============================================================
   QUESTION 1
   End-to-end risk score per card (rule based)
   ============================================================ */

-- SQL QUESTION:
-- Create a simple risk score per card based on:
-- +2 if utilization > 80%
-- +2 if any payment delay
-- +1 if card age < 2 years

SELECT
    cc.card_id,
    (
        CASE
            WHEN AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8 THEN 2
            ELSE 0
        END
        +
        CASE
            WHEN MAX(p.delay_months) > 0 THEN 2
            ELSE 0
        END
        +
        CASE
            WHEN DATEDIFF(YEAR, cc.open_date, GETDATE()) < 2 THEN 1
            ELSE 0
        END
    ) AS risk_score
FROM CREDIT_CARDS cc
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY
    cc.card_id,
    cc.open_date,
    l.credit_limit;

-- ENGLISH INTERVIEW ANSWER:
-- This query builds a simple rule-based risk score by combining
-- utilization, delinquency, and card vintage signals.

-- HINGLISH EXPLANATION:
-- Real life me models ke pehle rule-based scoring hota hai
-- Har risk signal ko weight diya
-- Total score se card ka risk strength samajh aata hai

-- HOW TO THINK ANALYTICALLY:
-- Multiple signals ko ek decision me lana ho → scoring
-- CASE WHEN + arithmetic use karo
-- Grouping mandatory for aggregates



/* ============================================================
   QUESTION 2
   Risk band classification
   ============================================================ */

-- SQL QUESTION:
-- Classify cards into Low / Medium / High risk using risk score

WITH risk_scores AS (
    SELECT
        cc.card_id,
        (
            CASE
                WHEN AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8 THEN 2
                ELSE 0
            END
            +
            CASE
                WHEN MAX(p.delay_months) > 0 THEN 2
                ELSE 0
            END
            +
            CASE
                WHEN DATEDIFF(YEAR, cc.open_date, GETDATE()) < 2 THEN 1
                ELSE 0
            END
        ) AS risk_score
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY
        cc.card_id,
        cc.open_date,
        l.credit_limit
)

SELECT
    card_id,
    risk_score,
    CASE
        WHEN risk_score <= 1 THEN 'Low Risk'
        WHEN risk_score <= 3 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_band
FROM risk_scores;

-- ENGLISH INTERVIEW ANSWER:
-- This query converts a numeric risk score into interpretable
-- risk bands used for operational decision making.

-- HINGLISH EXPLANATION:
-- Management numbers nahi dekhna chahta
-- Unko labels chahiye
-- CASE WHEN se banding banayi

-- HOW TO THINK ANALYTICALLY:
-- Scores → Bands
-- Readability is key in senior reporting



/* ============================================================
   QUESTION 3
   Portfolio loss concentration (exposure at risk)
   ============================================================ */

-- SQL QUESTION:
-- Calculate total credit limit exposure for high-risk cards

WITH risk_scores AS (
    SELECT
        cc.card_id,
        (
            CASE
                WHEN AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8 THEN 2
                ELSE 0
            END
            +
            CASE
                WHEN MAX(p.delay_months) > 0 THEN 2
                ELSE 0
            END
        ) AS risk_score
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, l.credit_limit
)

SELECT
    SUM(l.credit_limit) AS high_risk_exposure
FROM risk_scores r
JOIN CREDIT_LIMITS l
    ON r.card_id = l.card_id
WHERE r.risk_score >= 3;

-- ENGLISH INTERVIEW ANSWER:
-- This query calculates the total credit exposure associated
-- with high-risk cards, indicating potential loss concentration.

-- HINGLISH EXPLANATION:
-- Risk ka matlab sirf count nahi hota
-- Paisa kaha at-risk hai wo zyada important hota hai
-- Isliye exposure sum kiya

-- HOW TO THINK ANALYTICALLY:
-- Senior management exposure poochta hai
-- Risk × Money = real concern



/* ============================================================
   QUESTION 4
   Early warning vs chronic risk separation
   ============================================================ */

-- SQL QUESTION:
-- Separate early-warning cards from chronic delinquent cards

SELECT
    card_id,
    CASE
        WHEN MIN(delay_months) = 0 AND MAX(delay_months) > 0
            THEN 'Early Warning'
        WHEN MIN(delay_months) > 0
            THEN 'Chronic Risk'
        ELSE 'Clean'
    END AS risk_stage
FROM CARD_PAYMENTS
GROUP BY card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query classifies cards into early warning, chronic risk,
-- and clean categories based on payment behavior history.

-- HINGLISH EXPLANATION:
-- Sab delinquent same nahi hote
-- Pehli baar late hua ≠ hamesha late
-- Strategy alag hoti hai

-- HOW TO THINK ANALYTICALLY:
-- Pattern matters more than one data point
-- MIN / MAX tells story over time



/* ============================================================
   QUESTION 5
   Action recommendation per card
   ============================================================ */

-- SQL QUESTION:
-- Generate action recommendation for each card

WITH risk_stage AS (
    SELECT
        card_id,
        CASE
            WHEN MIN(delay_months) = 0 AND MAX(delay_months) > 0
                THEN 'Monitor'
            WHEN MIN(delay_months) > 0
                THEN 'Reduce Limit'
            ELSE 'Grow'
        END AS action_flag
    FROM CARD_PAYMENTS
    GROUP BY card_id
)

SELECT
    cc.card_id,
    cc.card_type,
    r.action_flag
FROM CREDIT_CARDS cc
LEFT JOIN risk_stage r
    ON cc.card_id = r.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query converts analytical insights into actionable
-- recommendations for each card.

-- HINGLISH EXPLANATION:
-- Analysis ka final goal decision hota hai
-- Har card ke liye clear next step bataya

-- HOW TO THINK ANALYTICALLY:
-- Always ask: "So what?"
-- Analysis without action is incomplete

/* ============================================================
   QUESTION 6
   Customer-level risk band with exposure
   ============================================================ */

-- SQL QUESTION:
-- Create customer-wise risk band using card-level signals
-- and show total exposure per customer

WITH card_risk AS (
    SELECT
        cc.card_id,
        cc.customer_id,
        (
            CASE
                WHEN AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8 THEN 2
                ELSE 0
            END
            +
            CASE
                WHEN MAX(p.delay_months) > 0 THEN 2
                ELSE 0
            END
        ) AS risk_score
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, cc.customer_id, l.credit_limit
)
SELECT
    c.customer_id,
    c.customer_name,
    SUM(l.credit_limit) AS total_exposure,
    CASE
        WHEN MAX(cr.risk_score) >= 3 THEN 'High Risk'
        WHEN MAX(cr.risk_score) >= 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS customer_risk_band
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
JOIN card_risk cr
    ON cc.card_id = cr.card_id
GROUP BY c.customer_id, c.customer_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query aggregates card-level risk signals to classify customers
-- into risk bands while showing their total exposure.

-- HINGLISH EXPLANATION:
-- Decision customer pe hota hai, card pe nahi
-- Isliye card risks ko customer level pe roll-up kiya
-- Exposure saath me dikhaya taaki impact samajh aaye

-- HOW TO THINK ANALYTICALLY:
-- Grain decide karo (customer)
-- Card-level metrics ko aggregate karo
-- Banding se decision-friendly output banao



/* ============================================================
   QUESTION 7
   Vintage vs risk analysis
   ============================================================ */

-- SQL QUESTION:
-- Compare delinquency by card vintage buckets

SELECT
    CASE
        WHEN DATEDIFF(YEAR, cc.open_date, GETDATE()) < 1 THEN 'Vintage < 1Y'
        WHEN DATEDIFF(YEAR, cc.open_date, GETDATE()) BETWEEN 1 AND 2 THEN 'Vintage 1-2Y'
        ELSE 'Vintage > 2Y'
    END AS vintage_bucket,
    COUNT(DISTINCT cc.card_id) AS total_cards,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END)
        AS delinquent_cards
FROM CREDIT_CARDS cc
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY
    CASE
        WHEN DATEDIFF(YEAR, cc.open_date, GETDATE()) < 1 THEN 'Vintage < 1Y'
        WHEN DATEDIFF(YEAR, cc.open_date, GETDATE()) BETWEEN 1 AND 2 THEN 'Vintage 1-2Y'
        ELSE 'Vintage > 2Y'
    END;

-- ENGLISH INTERVIEW ANSWER:
-- This query analyzes delinquency across different card vintage
-- segments to understand how risk evolves over time.

-- HINGLISH EXPLANATION:
-- New cards ka risk alag hota hai, old cards ka alag
-- Vintage buckets bana ke delinquency compare ki

-- HOW TO THINK ANALYTICALLY:
-- Time-based segmentation → vintage
-- Risk comparison → conditional counts



/* ============================================================
   QUESTION 8
   Stress indicator: utilization spike with new delinquency
   ============================================================ */

-- SQL QUESTION:
-- Identify cards where utilization increased and first delay appeared

WITH util AS (
    SELECT
        b.card_id,
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_util
    FROM CARD_BILLING b
    JOIN CREDIT_LIMITS l
        ON b.card_id = l.card_id
    GROUP BY b.card_id
),
delinq AS (
    SELECT
        card_id,
        MIN(delay_months) AS min_delay,
        MAX(delay_months) AS max_delay
    FROM CARD_PAYMENTS
    GROUP BY card_id
)
SELECT
    u.card_id
FROM util u
JOIN delinq d
    ON u.card_id = d.card_id
WHERE
    u.avg_util > 0.75
    AND d.min_delay = 0
    AND d.max_delay > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query flags cards showing rising utilization alongside
-- the first occurrence of delinquency, indicating stress.

-- HINGLISH EXPLANATION:
-- Utilization badh rahi hai
-- Aur delay first time aaya
-- Ye classic stress signal hota hai

-- HOW TO THINK ANALYTICALLY:
-- Early stress = usage pressure + behaviour change
-- Signals ko combine karke identify karo



/* ============================================================
   QUESTION 9
   Portfolio what-if: exposure if high-risk cards are blocked
   ============================================================ */

-- SQL QUESTION:
-- Calculate remaining exposure after excluding high-risk cards

WITH risk_cards AS (
    SELECT
        cc.card_id,
        (
            CASE
                WHEN MAX(p.delay_months) > 0 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8 THEN 1
                ELSE 0
            END
        ) AS risk_flag
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, l.credit_limit
)
SELECT
    SUM(l.credit_limit) AS remaining_exposure
FROM CREDIT_LIMITS l
JOIN risk_cards r
    ON l.card_id = r.card_id
WHERE r.risk_flag < 2;

-- ENGLISH INTERVIEW ANSWER:
-- This query estimates remaining portfolio exposure if high-risk
-- cards are excluded, supporting what-if analysis.

-- HINGLISH EXPLANATION:
-- Management poochta hai: agar risky cards band kar dein toh?
-- Isliye exposure recalc kiya excluding risky set

-- HOW TO THINK ANALYTICALLY:
-- What-if questions → filter scenario
-- Exposure sum se impact measure hota hai



/* ============================================================
   QUESTION 10
   Final executive snapshot
   ============================================================ */

-- SQL QUESTION:
-- Create a one-row executive summary

SELECT
    COUNT(DISTINCT cc.card_id) AS total_cards,
    SUM(l.credit_limit) AS total_exposure,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END)
        AS delinquent_cards,
    CAST(
        COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) * 100.0
        / COUNT(DISTINCT cc.card_id)
        AS DECIMAL(5,2)
    ) AS delinquency_rate
FROM CREDIT_CARDS cc
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query provides a single executive-level snapshot of portfolio
-- size, exposure, and delinquency.

-- HINGLISH EXPLANATION:
-- Senior audience ko ek hi line me sab chahiye
-- Total cards, exposure, aur risk percentage

-- HOW TO THINK ANALYTICALLY:
-- Executive output = minimal rows, maximum signal
-- Ratios + totals ek saath dikhte hain



/* ============================================================
   QUESTION 11
   Customer stress escalation detection
   ============================================================ */

-- SQL QUESTION:
-- Identify customers whose cards show BOTH:
-- 1) Increasing utilization
-- 2) Recent payment delay
-- This indicates escalation, not static risk.

WITH util_trend AS (
    SELECT
        b.card_id,
        MAX(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS max_util,
        MIN(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS min_util
    FROM CARD_BILLING b
    JOIN CREDIT_LIMITS l
        ON b.card_id = l.card_id
    GROUP BY b.card_id
),
payment_signal AS (
    SELECT
        card_id,
        MIN(delay_months) AS min_delay,
        MAX(delay_months) AS max_delay
    FROM CARD_PAYMENTS
    GROUP BY card_id
)
SELECT DISTINCT
    c.customer_id,
    c.customer_name
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN util_trend u
    ON cc.card_id = u.card_id
JOIN payment_signal p
    ON cc.card_id = p.card_id
WHERE
    u.max_util > u.min_util
    AND p.min_delay = 0
    AND p.max_delay > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies customers whose usage is increasing and
-- who have recently started missing payments, indicating stress escalation.

-- HINGLISH EXPLANATION:
-- Static risk alag hota hai
-- Escalation ka matlab situation bigad rahi hai
-- Usage badh rahi hai + pehla delay aaya = warning sign

-- HOW TO THINK ANALYTICALLY:
-- Interviewer escalation pe focus karta hai
-- Trend + behaviour change combine karo
-- Single metric pe decision mat lo



/* ============================================================
   QUESTION 12
   Policy impact simulation – tightening credit limits
   ============================================================ */

-- SQL QUESTION:
-- Simulate impact if credit limits are reduced by 20% for delinquent cards

SELECT
    cc.card_id,
    l.credit_limit AS current_limit,
    CASE
        WHEN MAX(p.delay_months) > 0
            THEN CAST(l.credit_limit * 0.8 AS INT)
        ELSE l.credit_limit
    END AS simulated_new_limit
FROM CREDIT_CARDS cc
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY cc.card_id, l.credit_limit;

-- ENGLISH INTERVIEW ANSWER:
-- This query simulates the effect of reducing credit limits for
-- delinquent cards to assess policy impact.

-- HINGLISH EXPLANATION:
-- Real interview me “what if policy change ho” poocha jata hai
-- SQL me simulation CASE WHEN se hota hai
-- Data ko change nahi karte, sirf calculate karte hain

-- HOW TO THINK ANALYTICALLY:
-- Simulation ≠ update
-- CASE WHEN se hypothetical outcomes nikalo
-- Safe analysis approach



/* ============================================================
   QUESTION 13
   Exposure concentration – top 20% cards
   ============================================================ */

-- SQL QUESTION:
-- Identify cards contributing to top 20% of total exposure

WITH exposure_rank AS (
    SELECT
        card_id,
        credit_limit,
        SUM(credit_limit) OVER () AS total_exposure,
        SUM(credit_limit) OVER (ORDER BY credit_limit DESC) AS cumulative_exposure
    FROM CREDIT_LIMITS
)
SELECT
    card_id,
    credit_limit
FROM exposure_rank
WHERE cumulative_exposure <= total_exposure * 0.2;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards that contribute to the top 20% of
-- portfolio exposure, highlighting concentration risk.

-- HINGLISH EXPLANATION:
-- Portfolio ka zyada risk kuch hi cards me hota hai
-- Window function se cumulative exposure nikala
-- Top concentration identify ki

-- HOW TO THINK ANALYTICALLY:
-- Concentration questions → window functions
-- Pareto logic (80/20) common hai senior discussions me



/* ============================================================
   QUESTION 14
   Branch stress ranking
   ============================================================ */

-- SQL QUESTION:
-- Rank branches based on delinquency rate

SELECT
    br.branch_name,
    CAST(
        COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) * 100.0
        / COUNT(DISTINCT cc.card_id)
        AS DECIMAL(5,2)
    ) AS delinquency_rate,
    RANK() OVER (
        ORDER BY
            COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) * 1.0
            / COUNT(DISTINCT cc.card_id) DESC
    ) AS risk_rank
FROM BRANCHES br
JOIN CUSTOMERS c
    ON br.branch_id = c.branch_id
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY br.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query ranks branches based on delinquency rates to
-- identify high-risk regions.

-- HINGLISH EXPLANATION:
-- Management ranking samajhta hai easily
-- RANK() se relative position milti hai
-- Branch-wise strategy banane me kaam aata hai

-- HOW TO THINK ANALYTICALLY:
-- Comparison + ordering ho → window ranking
-- Ratios first, rank after



/* ============================================================
   QUESTION 15
   Final decision dashboard – card action mapping
   ============================================================ */

-- SQL QUESTION:
-- Assign final action per card:
-- Block / Monitor / Grow

WITH risk_eval AS (
    SELECT
        cc.card_id,
        MAX(p.delay_months) AS max_delay,
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_util
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, l.credit_limit
)
SELECT
    card_id,
    CASE
        WHEN max_delay >= 2 THEN 'Block'
        WHEN avg_util > 0.75 THEN 'Monitor'
        ELSE 'Grow'
    END AS final_action
FROM risk_eval;

-- ENGLISH INTERVIEW ANSWER:
-- This query converts multiple risk indicators into a single
-- operational action per card.

-- HINGLISH EXPLANATION:
-- Final output hamesha decision hota hai
-- Data → logic → action
-- Yehi maturity interviewer dekh raha hota hai

-- HOW TO THINK ANALYTICALLY:
-- Multiple signals ko simplify karo
-- Clear thresholds define karo
-- Decision-ready output banao


/* ============================================================
   ADVANCED – PART 3 (CONTINUED FURTHER)
   Focus:
   - Scenario-based reasoning
   - Portfolio impact analysis
   - Counterfactual thinking
   - Interview-grade depth
   ============================================================ */


/* ============================================================
   QUESTION 16
   Scenario analysis – delinquency impact on exposure
   ============================================================ */

-- SQL QUESTION:
-- Calculate exposure split between delinquent and non-delinquent cards

SELECT
    exposure_type,
    SUM(credit_limit) AS exposure_amount
FROM (
    SELECT
        cc.card_id,
        l.credit_limit,
        CASE
            WHEN MAX(p.delay_months) > 0 THEN 'Delinquent Exposure'
            ELSE 'Clean Exposure'
        END AS exposure_type
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY
        cc.card_id,
        l.credit_limit
) x
GROUP BY exposure_type;

-- ENGLISH INTERVIEW ANSWER:
-- This query splits total credit exposure into delinquent and
-- non-delinquent segments to assess portfolio risk.

-- HINGLISH EXPLANATION:
-- Pehle card level pe delinquency derive ki
-- Phir uske basis pe credit limit aggregate ki
-- SQL Server aggregate-based logic ko direct GROUP BY me allow nahi karta

-- HOW TO THINK ANALYTICALLY:
-- Delinquency ek card-level attribute hai
-- Exposure ek portfolio-level metric hai
-- Isliye derive first, aggregate later



/* ============================================================
   QUESTION 17
   Worst-case scenario – maximum potential loss proxy
   ============================================================ */

-- SQL QUESTION:
-- Estimate worst-case exposure assuming all delinquent cards default

SELECT
    SUM(l.credit_limit) AS potential_loss_exposure
FROM CREDIT_LIMITS l
JOIN CREDIT_CARDS cc
    ON l.card_id = cc.card_id
JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
WHERE p.delay_months > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query estimates a worst-case loss proxy by summing
-- credit limits of all delinquent cards.

-- HINGLISH EXPLANATION:
-- Default prediction nahi hai
-- Par stress scenario ka simple proxy hai
-- Interview me logic important hota hai, perfection nahi

-- HOW TO THINK ANALYTICALLY:
-- Worst case = assume maximum loss
-- Conservative assumption dikhao
-- Senior discussions me kaam aata hai



/* ============================================================
   QUESTION 18
   Stability check – customers with mixed card behaviour
   ============================================================ */

-- SQL QUESTION:
-- Identify customers having both clean and delinquent cards

SELECT
    c.customer_id,
    c.customer_name
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY c.customer_id, c.customer_name
HAVING
    MIN(p.delay_months) = 0
    AND MAX(p.delay_months) > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies customers who show mixed risk behavior
-- across different cards.

-- HINGLISH EXPLANATION:
-- Same customer ka ek card clean ho sakta hai
-- Aur doosra risky
-- Policy decisions customer level pe complex ho jaate hain

-- HOW TO THINK ANALYTICALLY:
-- Customer-level decisions me aggregation zaroori
-- MIN / MAX se behaviour diversity samajh aati hai



/* ============================================================
   QUESTION 19
   Pre-emptive control – cards nearing full utilization
   ============================================================ */

-- SQL QUESTION:
-- Identify cards where utilization is above 90% even without delays

SELECT DISTINCT
    b.card_id
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
GROUP BY b.card_id, l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.9
    AND MAX(ISNULL(p.delay_months, 0)) = 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies high-utilization cards without delinquency,
-- which are candidates for pre-emptive monitoring.

-- HINGLISH EXPLANATION:
-- Abhi late nahi hua
-- Par limit almost full hai
-- Aage jaake problem aa sakti hai

-- HOW TO THINK ANALYTICALLY:
-- Risk sirf delinquency nahi hota
-- Pressure signals pehle aate hain
-- Preventive thinking dikhao



/* ============================================================
   QUESTION 20
   Portfolio sensitivity – 10% utilization shock
   ============================================================ */

-- SQL QUESTION:
-- Simulate impact if billed amounts increase by 10% next month

SELECT
    b.card_id,
    b.billed_amount AS current_billing,
    CAST(b.billed_amount * 1.10 AS INT) AS shocked_billing,
    l.credit_limit
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query simulates a utilization shock by increasing billed
-- amounts by 10% to assess stress impact.

-- HINGLISH EXPLANATION:
-- Stress testing me assumptions lete hain
-- Actual data change nahi karte
-- Hypothetical impact nikalte hain

-- HOW TO THINK ANALYTICALLY:
-- Sensitivity analysis = small change impact
-- SQL me multiplication se simulate hota hai



/* ============================================================
   QUESTION 21
   Policy exception identification
   ============================================================ */

-- SQL QUESTION:
-- Identify delinquent cards that still have very high limits

SELECT
    cc.card_id,
    l.credit_limit
FROM CREDIT_CARDS cc
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
WHERE
    p.delay_months > 0
    AND l.credit_limit > 100000;

-- ENGLISH INTERVIEW ANSWER:
-- This query highlights policy exceptions where delinquent
-- cards still carry high credit limits.

-- HINGLISH EXPLANATION:
-- Risk policy ka violation yahin pakda jata hai
-- Delinquent + high limit = red flag

-- HOW TO THINK ANALYTICALLY:
-- Exception analysis interviewers ko pasand hota hai
-- Policy vs reality compare karo



/* ============================================================
   QUESTION 22
   Executive drill-down – branch risk with exposure
   ============================================================ */

SELECT
    br.branch_name,
    SUM(l.credit_limit) AS total_exposure,
    SUM(
        CASE WHEN p.delay_months > 0 THEN l.credit_limit ELSE 0 END
    ) AS delinquent_exposure
FROM BRANCHES br
JOIN CUSTOMERS c
    ON br.branch_id = c.branch_id
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY br.branch_name;

-- ENGLISH INTERVIEW ANSWER:
-- This query provides a branch-level breakdown of total
-- and delinquent exposure for executive review.

-- HINGLISH EXPLANATION:
-- Branch ka exposure aur risk ek saath dikhana padta hai
-- Decision geography ke hisaab se hota hai

-- HOW TO THINK ANALYTICALLY:
-- Drill-down capability important hoti hai
-- Exposure + risk side by side dikhao

/* ============================================================
   QUESTION 23
   Cohort analysis – cards opened in same year
   ============================================================ */

-- SQL QUESTION:
-- Compare delinquency across card open-year cohorts

SELECT
    YEAR(cc.open_date) AS open_year,
    COUNT(DISTINCT cc.card_id) AS total_cards,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END)
        AS delinquent_cards,
    CAST(
        COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) * 100.0
        / COUNT(DISTINCT cc.card_id)
        AS DECIMAL(5,2)
    ) AS delinquency_rate
FROM CREDIT_CARDS cc
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY YEAR(cc.open_date)
ORDER BY open_year;

-- ENGLISH INTERVIEW ANSWER:
-- This query compares delinquency rates across cohorts of cards
-- opened in the same year to understand vintage risk.

-- HINGLISH EXPLANATION:
-- Same time pe issue hue cards ka behaviour similar hota hai
-- Isliye open_date se cohort banaya
-- Vintage risk clearly dikhta hai

-- HOW TO THINK ANALYTICALLY:
-- Cohort analysis = group by start time
-- Time-based risk evolution samajhne ke liye useful



/* ============================================================
   QUESTION 24
   Limit utilization dispersion (risk variability)
   ============================================================ */

-- SQL QUESTION:
-- Measure utilization variability per card using max-min utilization

SELECT
    b.card_id,
    MAX(CAST(b.billed_amount AS FLOAT) / l.credit_limit)
      - MIN(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS utilization_dispersion
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
GROUP BY b.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query measures variability in utilization, indicating
-- unstable spending behavior.

-- HINGLISH EXPLANATION:
-- Stable customer ka utilization smooth hota hai
-- Zyada jump matlab volatility
-- Volatility risk ka early sign ho sakta hai

-- HOW TO THINK ANALYTICALLY:
-- Variability dekhni ho → max minus min
-- Stability is a hidden risk signal



/* ============================================================
   QUESTION 25
   Branch outlier detection (high-risk vs peers)
   ============================================================ */

-- SQL QUESTION:
-- Identify branches whose delinquency rate is above portfolio average

WITH branch_rates AS (
    SELECT
        br.branch_name,
        COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) * 1.0
        / COUNT(DISTINCT cc.card_id) AS branch_rate
    FROM BRANCHES br
    JOIN CUSTOMERS c
        ON br.branch_id = c.branch_id
    JOIN CREDIT_CARDS cc
        ON c.customer_id = cc.customer_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY br.branch_name
),
portfolio_avg AS (
    SELECT AVG(branch_rate) AS avg_rate FROM branch_rates
)
SELECT
    b.branch_name,
    b.branch_rate
FROM branch_rates b
CROSS JOIN portfolio_avg p
WHERE b.branch_rate > p.avg_rate;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies branches performing worse than the
-- portfolio average in terms of delinquency.

-- HINGLISH EXPLANATION:
-- Absolute numbers kaafi nahi hote
-- Relative performance important hota hai
-- Average se compare karke outliers nikale

-- HOW TO THINK ANALYTICALLY:
-- Benchmarking zaroori hota hai
-- Peer comparison se real issues dikte hain



/* ============================================================
   QUESTION 26
   Policy threshold tuning – utilization cutoff impact
   ============================================================ */

-- SQL QUESTION:
-- Compare number of cards flagged at 70%, 80%, 90% utilization thresholds

SELECT
    SUM(CASE WHEN util > 0.7 THEN 1 ELSE 0 END) AS flagged_70,
    SUM(CASE WHEN util > 0.8 THEN 1 ELSE 0 END) AS flagged_80,
    SUM(CASE WHEN util > 0.9 THEN 1 ELSE 0 END) AS flagged_90
FROM (
    SELECT
        b.card_id,
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS util
    FROM CARD_BILLING b
    JOIN CREDIT_LIMITS l
        ON b.card_id = l.card_id
    GROUP BY b.card_id
) u;

-- ENGLISH INTERVIEW ANSWER:
-- This query evaluates how changing utilization thresholds
-- affects the number of cards flagged for monitoring.

-- HINGLISH EXPLANATION:
-- Policy banate time threshold ka impact dekhna padta hai
-- Zyada strict = zyada cards
-- Balance important hota hai

-- HOW TO THINK ANALYTICALLY:
-- Sensitivity analysis with multiple cutoffs
-- SQL me nested queries best hoti hain



/* ============================================================
   QUESTION 27
   Customer concentration risk (top spenders)
   ============================================================ */

-- SQL QUESTION:
-- Identify customers contributing more than 30% of total billing

WITH customer_billing AS (
    SELECT
        c.customer_id,
        SUM(b.billed_amount) AS customer_total
    FROM CUSTOMERS c
    JOIN CREDIT_CARDS cc
        ON c.customer_id = cc.customer_id
    JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    GROUP BY c.customer_id
),
portfolio_total AS (
    SELECT SUM(customer_total) AS total_billing FROM customer_billing
)
SELECT
    cb.customer_id,
    cb.customer_total
FROM customer_billing cb
CROSS JOIN portfolio_total pt
WHERE cb.customer_total > pt.total_billing * 0.3;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies customer concentration risk by highlighting
-- customers contributing disproportionately to total billing.

-- HINGLISH EXPLANATION:
-- Agar kuch customers pe zyada depend hai
-- Toh unka risk zyada impact karega
-- Concentration analysis isliye hota hai

-- HOW TO THINK ANALYTICALLY:
-- Concentration = contribution / total
-- Portfolio stability ka indicator



/* ============================================================
   QUESTION 28
   Stability vs growth trade-off
   ============================================================ */

-- SQL QUESTION:
-- Compare average utilization between delinquent and clean cards

SELECT
    card_group,
    AVG(card_avg_util) AS avg_utilization
FROM (
    SELECT
        cc.card_id,
        CASE
            WHEN MAX(p.delay_months) > 0 THEN 'Delinquent'
            ELSE 'Clean'
        END AS card_group,
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS card_avg_util
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY
        cc.card_id,
        l.credit_limit
) x
GROUP BY card_group;

-- ENGLISH INTERVIEW ANSWER:
-- This query compares utilization between delinquent and clean
-- cards to evaluate the growth versus risk trade-off.

-- HINGLISH EXPLANATION:
-- Pehle card level pe utilization aur delinquency derive ki
-- Phir group level pe average compare kiya
-- Ek hi query hai, bas derived table use hua hai

-- HOW TO THINK ANALYTICALLY:
-- Jab aggregate-based classification chahiye ho
-- Toh pehle derive, phir aggregate
-- SQL me logic flow follow karna padta hai


/* ============================================================
   QUESTION 29
   Control group analysis – clean high-utilization cards
   ============================================================ */

-- SQL QUESTION:
-- Identify cards with high utilization but ZERO delinquency
-- These act as a control group for comparison

SELECT
    b.card_id,
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_utilization
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
-- This query identifies high-utilization cards with clean payment
-- history, serving as a control group for risk comparison.

-- HINGLISH EXPLANATION:
-- High utilization hamesha risky nahi hota
-- Kuch customers strong hote hain
-- Unko control group ke jaise treat karte hain

-- HOW TO THINK ANALYTICALLY:
-- Risk ka reason samajhne ke liye comparison chahiye
-- Control vs treatment logic use karo



/* ============================================================
   QUESTION 30
   Treatment group – utilization + delinquency combined
   ============================================================ */

-- SQL QUESTION:
-- Identify cards with both high utilization and delinquency
-- These are treatment / high-risk group

SELECT
    b.card_id,
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_utilization,
    MAX(p.delay_months) AS max_delay
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
-- This query identifies high-risk cards showing both heavy usage
-- and delinquent behavior.

-- HINGLISH EXPLANATION:
-- Same utilization
-- Par behaviour alag
-- Yahin se causality analysis start hota hai

-- HOW TO THINK ANALYTICALLY:
-- Similar usage, different outcomes
-- Behaviour difference pe focus karo



/* ============================================================
   QUESTION 31
   Comparative insight – why some high users default and others don’t
   ============================================================ */

-- SQL QUESTION:
-- Compare average income of customers in control vs treatment group

WITH control_group AS (
    SELECT DISTINCT
        cc.customer_id
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, cc.customer_id, l.credit_limit
    HAVING
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8
        AND MAX(ISNULL(p.delay_months, 0)) = 0
),
treatment_group AS (
    SELECT DISTINCT
        cc.customer_id
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, cc.customer_id, l.credit_limit
    HAVING
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8
        AND MAX(p.delay_months) > 0
)
SELECT
    'Control Group' AS group_type,
    AVG(customer_income) AS avg_income
FROM CUSTOMERS
WHERE customer_id IN (SELECT customer_id FROM control_group)

UNION ALL

SELECT
    'Treatment Group' AS group_type,
    AVG(customer_income) AS avg_income
FROM CUSTOMERS
WHERE customer_id IN (SELECT customer_id FROM treatment_group);

-- ENGLISH INTERVIEW ANSWER:
-- This query compares customer income between clean high-utilization
-- cards and delinquent high-utilization cards to understand drivers of risk.

-- HINGLISH EXPLANATION:
-- Utilization same hai
-- Difference income ka ho sakta hai
-- Yehi analytical depth interviewer dekhna chahta hai

-- HOW TO THINK ANALYTICALLY:
-- Causality socho, correlation nahi
-- Same behavior, different outcome → find driver



/* ============================================================
   QUESTION 32
   Pre-policy evaluation – who would be wrongly blocked?
   ============================================================ */

-- SQL QUESTION:
-- Identify clean customers who would be affected by a strict
-- utilization-based blocking policy (>85%)

SELECT DISTINCT
    cc.card_id,
    c.customer_name
FROM CREDIT_CARDS cc
JOIN CUSTOMERS c
    ON cc.customer_id = c.customer_id
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY
    cc.card_id,
    c.customer_name,
    l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.85
    AND MAX(ISNULL(p.delay_months, 0)) = 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies good customers who might be negatively
-- impacted by an overly strict utilization policy.

-- HINGLISH EXPLANATION:
-- Policy ka unintended effect dekhna zaroori hota hai
-- Good customers ko harm nahi hona chahiye

-- HOW TO THINK ANALYTICALLY:
-- Har rule ka side effect hota hai
-- Interviewer expects this awareness



/* ============================================================
   QUESTION 33
   Final board-style recommendation table
   ============================================================ */

-- SQL QUESTION:
-- Create final recommendation summary per card

WITH risk_eval AS (
    SELECT
        cc.card_id,
        MAX(p.delay_months) AS max_delay,
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_util
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, l.credit_limit
)
SELECT
    card_id,
    avg_util,
    max_delay,
    CASE
        WHEN max_delay >= 2 THEN 'Immediate Action'
        WHEN avg_util > 0.85 THEN 'Watch Closely'
        ELSE 'Healthy'
    END AS recommendation
FROM risk_eval;

-- ENGLISH INTERVIEW ANSWER:
-- This query produces a board-level summary translating
-- risk metrics into clear recommendations.

-- HINGLISH EXPLANATION:
-- End goal always recommendation hota hai
-- Numbers ko words me convert karna maturity dikhata hai

-- HOW TO THINK ANALYTICALLY:
-- Metrics → meaning → action
-- Yehi senior-level thinking hai

/* ============================================================
   QUESTION 34
   Edge case – cards with billing but no payments yet
   ============================================================ */

-- SQL QUESTION:
-- Identify cards that have billing records but no payment history

SELECT DISTINCT
    b.card_id
FROM CARD_BILLING b
LEFT JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
WHERE p.card_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies cards that have incurred billing
-- but do not yet have any recorded payments.

-- HINGLISH EXPLANATION:
-- New cards ho sakte hain
-- Ya data lag issue ho sakta hai
-- Interviewer yahin check karta hai tum data ko blindly trust karte ho ya nahi

-- HOW TO THINK ANALYTICALLY:
-- Missing data bhi insight hota hai
-- LEFT JOIN + NULL = edge case detection



/* ============================================================
   QUESTION 35
   Lag-adjusted delinquency view
   ============================================================ */

-- SQL QUESTION:
-- Show delinquency only after at least one billing exists

SELECT DISTINCT
    p.card_id
FROM CARD_PAYMENTS p
JOIN CARD_BILLING b
    ON p.card_id = b.card_id
WHERE p.delay_months > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query ensures delinquency is evaluated only for cards
-- that have already generated billing.

-- HINGLISH EXPLANATION:
-- Bina billing ke delay ka koi matlab nahi
-- Ye logical filter interviewer ko impress karta hai

-- HOW TO THINK ANALYTICALLY:
-- Sequence matters: billing → payment
-- Time order validate karo



/* ============================================================
   QUESTION 36
   Conflicting signals resolution
   ============================================================ */

-- SQL QUESTION:
-- Identify cards with low utilization but high delinquency

SELECT
    b.card_id,
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_util,
    MAX(p.delay_months) AS max_delay
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
JOIN CARD_PAYMENTS p
    ON b.card_id = p.card_id
GROUP BY b.card_id, l.credit_limit
HAVING
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) < 0.3
    AND MAX(p.delay_months) > 0;

-- ENGLISH INTERVIEW ANSWER:
-- This query highlights cards with low usage but poor payment
-- behavior, indicating liquidity or discipline issues.

-- HINGLISH EXPLANATION:
-- Usage kam hai par delay aa raha hai
-- Matlab paisa issue hai, spending issue nahi
-- Strategy alag hoti hai aise cases me

-- HOW TO THINK ANALYTICALLY:
-- Conflicting signals ko ignore nahi karte
-- Root cause alag ho sakta hai



/* ============================================================
   QUESTION 37
   Explainable segmentation for discussion
   ============================================================ */

-- SQL QUESTION:
-- Segment cards into clear explainable buckets

SELECT
    cc.card_id,
    CASE
        WHEN MAX(p.delay_months) >= 2 THEN 'High Risk – Chronic Delay'
        WHEN MAX(p.delay_months) = 1 THEN 'Medium Risk – Early Delay'
        WHEN AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) > 0.8 THEN 'High Usage – Clean'
        ELSE 'Low Risk'
    END AS explainable_segment
FROM CREDIT_CARDS cc
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id
GROUP BY cc.card_id, l.credit_limit;

-- ENGLISH INTERVIEW ANSWER:
-- This query creates simple, explainable risk segments
-- suitable for discussion with non-technical stakeholders.

-- HINGLISH EXPLANATION:
-- Complex models baad me aate hain
-- Pehle explainable buckets chahiye
-- Interviewer yahin maturity judge karta hai

-- HOW TO THINK ANALYTICALLY:
-- Explanation capability = seniority
-- Labels clear hone chahiye



/* ============================================================
   QUESTION 38
   Final stress-test sanity check
   ============================================================ */

-- SQL QUESTION:
-- Count how many cards would be flagged under each rule

SELECT
    SUM(CASE WHEN avg_util > 0.8 THEN 1 ELSE 0 END) AS high_util_cards,
    SUM(CASE WHEN max_delay > 0 THEN 1 ELSE 0 END) AS delinquent_cards
FROM (
    SELECT
        cc.card_id,
        AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_util,
        MAX(p.delay_months) AS max_delay
    FROM CREDIT_CARDS cc
    JOIN CREDIT_LIMITS l
        ON cc.card_id = l.card_id
    LEFT JOIN CARD_BILLING b
        ON cc.card_id = b.card_id
    LEFT JOIN CARD_PAYMENTS p
        ON cc.card_id = p.card_id
    GROUP BY cc.card_id, l.credit_limit
) x;

-- ENGLISH INTERVIEW ANSWER:
-- This query validates how many cards are impacted
-- by each risk rule before applying them operationally.

-- HINGLISH EXPLANATION:
-- Rule banane se pehle impact dekhna padta hai
-- Warna system overload ho jata hai

-- HOW TO THINK ANALYTICALLY:
-- Always ask: how many will this affect?
-- Practicality matters

/* ============================================================
   QUESTION 39
   Data sanity check – duplicate billing detection
   ============================================================ */

-- SQL QUESTION:
-- Detect cards with duplicate billing entries for same month

SELECT
    card_id,
    billing_month,
    COUNT(*) AS duplicate_count
FROM CARD_BILLING
GROUP BY card_id, billing_month
HAVING COUNT(*) > 1;

-- ENGLISH INTERVIEW ANSWER:
-- This query identifies duplicate billing records which
-- may indicate data quality issues.

-- HINGLISH EXPLANATION:
-- Interviewer aksar poochta hai:
-- “Tum data blindly use karoge?”
-- Duplicate detection se data awareness dikhti hai

-- HOW TO THINK ANALYTICALLY:
-- Reporting se pehle data clean hona chahiye
-- GROUP BY + HAVING = sanity check



/* ============================================================
   QUESTION 40
   Orphan records check – payments without cards
   ============================================================ */

-- SQL QUESTION:
-- Identify payment records that do not have a matching card

SELECT
    p.payment_id,
    p.card_id
FROM CARD_PAYMENTS p
LEFT JOIN CREDIT_CARDS c
    ON p.card_id = c.card_id
WHERE c.card_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query checks for orphan payment records,
-- ensuring referential integrity.

-- HINGLISH EXPLANATION:
-- Real systems me data gaps hote hain
-- Orphan rows detect karna mature analyst ki sign hai

-- HOW TO THINK ANALYTICALLY:
-- LEFT JOIN + NULL = integrity issues
-- Ye production thinking hai



/* ============================================================
   QUESTION 41
   Metric defensibility – delinquency rate definition check
   ============================================================ */

-- SQL QUESTION:
-- Compare delinquency rate by cards vs by customers

SELECT
    'Card Level' AS metric_type,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) * 100.0
        / COUNT(DISTINCT cc.card_id) AS delinquency_rate
FROM CREDIT_CARDS cc
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id

UNION ALL

SELECT
    'Customer Level' AS metric_type,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN c.customer_id END) * 100.0
        / COUNT(DISTINCT c.customer_id) AS delinquency_rate
FROM CUSTOMERS c
JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query highlights how delinquency metrics
-- differ when measured at card vs customer level.

-- HINGLISH EXPLANATION:
-- Same data, different metric
-- Interviewer poochta hai: “Which one is correct?”
-- Answer: depends on business question

-- HOW TO THINK ANALYTICALLY:
-- Grain define karo
-- Metric ka meaning grain se change hota hai



/* ============================================================
   QUESTION 42
   Explain variance – billing vs limit mismatch
   ============================================================ */

-- SQL QUESTION:
-- Identify cases where billed amount exceeds credit limit

SELECT
    b.card_id,
    b.billed_amount,
    l.credit_limit
FROM CARD_BILLING b
JOIN CREDIT_LIMITS l
    ON b.card_id = l.card_id
WHERE b.billed_amount > l.credit_limit;

-- ENGLISH INTERVIEW ANSWER:
-- This query flags anomalies where billing exceeds
-- assigned credit limits.

-- HINGLISH EXPLANATION:
-- Over-limit spending ya data issue
-- Dono cases me investigation chahiye

-- HOW TO THINK ANALYTICALLY:
-- Numbers logical hone chahiye
-- Variance = question, not assumption



/* ============================================================
   QUESTION 43
   Interview classic – NOT IN vs LEFT JOIN
   ============================================================ */

-- SQL QUESTION:
-- Identify customers with no credit cards (safe method)

SELECT
    c.customer_id,
    c.customer_name
FROM CUSTOMERS c
LEFT JOIN CREDIT_CARDS cc
    ON c.customer_id = cc.customer_id
WHERE cc.card_id IS NULL;

-- ENGLISH INTERVIEW ANSWER:
-- This query safely identifies customers without cards
-- using LEFT JOIN instead of NOT IN.

-- HINGLISH EXPLANATION:
-- NOT IN NULL ke saath fail hota hai
-- LEFT JOIN safer aur production-grade hai

-- HOW TO THINK ANALYTICALLY:
-- Interviewers SQL depth yahin test karte hain
-- Correctness > shortcuts



/* ============================================================
   QUESTION 44
   Final pressure test – explain your whole approach
   ============================================================ */

-- SQL QUESTION:
-- Produce a compact portfolio snapshot with reasoning metrics

SELECT
    COUNT(DISTINCT cc.card_id) AS total_cards,
    SUM(l.credit_limit) AS total_exposure,
    AVG(CAST(b.billed_amount AS FLOAT) / l.credit_limit) AS avg_utilization,
    COUNT(DISTINCT CASE WHEN p.delay_months > 0 THEN cc.card_id END) AS delinquent_cards
FROM CREDIT_CARDS cc
JOIN CREDIT_LIMITS l
    ON cc.card_id = l.card_id
LEFT JOIN CARD_BILLING b
    ON cc.card_id = b.card_id
LEFT JOIN CARD_PAYMENTS p
    ON cc.card_id = p.card_id;

-- ENGLISH INTERVIEW ANSWER:
-- This query provides a concise portfolio overview
-- combining size, exposure, usage, and risk.

-- HINGLISH EXPLANATION:
-- Interview ke end me ye pucha jaata hai:
-- “Summarize portfolio in one slide”
-- Ye wahi slide hai

-- HOW TO THINK ANALYTICALLY:
-- Endgame = summary + signal
-- Kam rows, zyada meaning


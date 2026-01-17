# Credit-Card-Risk-Analytics-SQL-Practice-Guide


This document explains how a relational credit card dataset supports risk analytics, portfolio monitoring, and management reporting. It is designed for SQL practice and interview preparation for risk and information management roles.

---

## 1. Topics Mapped to SQL & Data Model

| Topic                       | SQL / Data Tables Involved                  |
| ------------------------------ | ------------------------------------------- |
| Credit card product life cycle | `CREDIT_CARDS`, `CREDIT_APPLICATIONS`       |
| Portfolio performance          | `CARD_BILLING`, `CREDIT_LIMITS`             |
| Credit risk management         | `CARD_PAYMENTS (delay_months)`              |
| Limit management               | `CREDIT_LIMITS` + `CARD_BILLING`            |
| MIS & monthly reports          | `JOIN`s + `GROUP BY`                        |
| Deviations / trends            | Month-wise analysis on billing and payments |
| Senior management reports      | Aggregated outputs (SUM, COUNT, AVG)        |

The current schema is sufficient to cover all of the above analytical requirements.

---

## 2. Tables & Columns — Meaning and Interview Context

### BRANCHES

**Columns**

* `branch_id`
* `branch_name`
* `city`

**Meaning**

* Represents the physical or operational unit of the organization.
* Used to analyze portfolio distribution by geography.

**Interview Line**

> Branch dimension is used for geographic portfolio and risk concentration analysis.

---

### CUSTOMERS

**Columns**

* `customer_id`
* `customer_name`
* `customer_age`
* `customer_income`
* `branch_id`

**Meaning**

* Stores customer demographic and base profile data.
* Acts as the parent entity for most risk analytics.

**Risk Angle**

* Age and income influence creditworthiness.
* Branch association helps identify regional risk patterns.

**Interview Line**

> Customer table acts as the base entity for all downstream risk analytics.

---

### CREDIT_CARDS

**Columns**

* `card_id`
* `customer_id`
* `card_type`
* `card_status`
* `open_date`

**Meaning (Credit Card Product Life Cycle)**

* Tracks the lifecycle of a credit card from issuance to closure.
* `open_date` enables vintage and cohort analysis.

**Risk Angle**

* Older vs newer cards behave differently in risk.
* Card type indicates exposure size.

---

### CREDIT_LIMITS

**Columns**

* `card_id`
* `credit_limit`

**Meaning**

* Defines the maximum exposure for each card.

**Risk Angle**

* Higher credit limit implies higher potential loss.
* Used to calculate utilization and stress indicators.

---

### CREDIT_APPLICATIONS

**Columns**

* `application_id`
* `customer_id`
* `product_type`
* `application_status`
* `application_date`

**Meaning**

* Tracks new card requests, limit increases, or other credit products.

**Risk Angle**

* Rejected applications signal higher risk.
* Approved limit increases indicate strong repayment behavior.

---

### CARD_BILLING

**Columns**

* `billing_id`
* `card_id`
* `billing_month`
* `billed_amount`

**Meaning**

* Monthly spending behavior at card level.
* Used for portfolio usage and trend analysis.

**Risk Angle**

* High billed amount relative to limit indicates financial stress.
* Month-over-month analysis reveals usage trends.

---

### CARD_PAYMENTS

**Columns**

* `payment_id`
* `card_id`
* `payment_month`
* `delay_months`

**Meaning**

* Captures payment behavior and delinquency status.

**Risk Angle**

* `delay_months = 0` indicates on-time payment.
* `delay_months > 0` indicates delinquency.
* Used to identify suddenly deteriorating customers vs consistently risky customers.
* Base table for default risk prediction.

---

## 3. Join Thinking — Interview Golden Rule

### Incorrect Approach

> Memorizing which tables to join.

### Correct Approach

> Start from the business question, identify the grain of analysis, and then join only the required tables.

---

## 4. Natural Join Flow

```
BRANCHES
   ↓
CUSTOMERS
   ↓
CREDIT_CARDS
   ↓
CREDIT_LIMITS
   ↓
CARD_BILLING
   ↓
CARD_PAYMENTS
```

### Application Side Flow

```
CUSTOMERS → CREDIT_APPLICATIONS
```

---

## 5. Join Keys Reference

| From Table          | To Table     | Join Column |
| ------------------- | ------------ | ----------- |
| CUSTOMERS           | BRANCHES     | branch_id   |
| CREDIT_CARDS        | CUSTOMERS    | customer_id |
| CREDIT_LIMITS       | CREDIT_CARDS | card_id     |
| CARD_BILLING        | CREDIT_CARDS | card_id     |
| CARD_PAYMENTS       | CREDIT_CARDS | card_id     |
| CREDIT_APPLICATIONS | CUSTOMERS    | customer_id |

---

## Usage Notes

* This schema supports SQL practice for risk analytics, MIS reporting, and portfolio monitoring.
* Queries should always start with a clear business requirement.
* Aggregations and joins should reflect the reporting grain (customer, card, or month).


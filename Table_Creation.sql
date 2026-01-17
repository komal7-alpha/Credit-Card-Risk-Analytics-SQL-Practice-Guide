/* =========================
   DROP TABLES (IF EXISTS)
   ========================= */

DROP TABLE IF EXISTS CARD_PAYMENTS;
DROP TABLE IF EXISTS CARD_BILLING;
DROP TABLE IF EXISTS CREDIT_APPLICATIONS;
DROP TABLE IF EXISTS CREDIT_LIMITS;
DROP TABLE IF EXISTS CREDIT_CARDS;
DROP TABLE IF EXISTS CUSTOMERS;
DROP TABLE IF EXISTS BRANCHES;

/* =========================
   CREATE TABLES
   ========================= */

CREATE TABLE BRANCHES (
    branch_id INT NOT NULL,
    branch_name VARCHAR(30) NOT NULL,
    city VARCHAR(30) NOT NULL,
    CONSTRAINT pk_branches PRIMARY KEY (branch_id)
);

CREATE TABLE CUSTOMERS (
    customer_id INT NOT NULL,
    customer_name VARCHAR(40) NOT NULL,
    customer_age INT NOT NULL,
    customer_income INT NOT NULL,
    branch_id INT NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT fk_customer_branch FOREIGN KEY (branch_id)
        REFERENCES BRANCHES(branch_id)
);

CREATE TABLE CREDIT_CARDS (
    card_id BIGINT NOT NULL,
    customer_id INT NOT NULL,
    card_type VARCHAR(20) NOT NULL,      -- Platinum / Gold / Silver
    card_status VARCHAR(15) NOT NULL,    -- Active / Blocked / Closed
    open_date DATE NOT NULL,
    CONSTRAINT pk_cards PRIMARY KEY (card_id),
    CONSTRAINT fk_card_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMERS(customer_id)
);

CREATE TABLE CREDIT_LIMITS (
    card_id BIGINT NOT NULL,
    credit_limit INT NOT NULL,
    CONSTRAINT pk_limits PRIMARY KEY (card_id),
    CONSTRAINT fk_limit_card FOREIGN KEY (card_id)
        REFERENCES CREDIT_CARDS(card_id)
);

CREATE TABLE CREDIT_APPLICATIONS (
    application_id INT NOT NULL,
    customer_id INT NOT NULL,
    product_type VARCHAR(20) NOT NULL,   -- Card / Loan / Increase
    application_status VARCHAR(15) NOT NULL, -- Approved / Rejected
    application_date DATE NOT NULL,
    CONSTRAINT pk_applications PRIMARY KEY (application_id),
    CONSTRAINT fk_app_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMERS(customer_id)
);

CREATE TABLE CARD_BILLING (
    billing_id INT NOT NULL,
    card_id BIGINT NOT NULL,
    billing_month DATE NOT NULL,
    billed_amount INT NOT NULL,
    CONSTRAINT pk_billing PRIMARY KEY (billing_id),
    CONSTRAINT fk_billing_card FOREIGN KEY (card_id)
        REFERENCES CREDIT_CARDS(card_id)
);

CREATE TABLE CARD_PAYMENTS (
    payment_id INT NOT NULL,
    card_id BIGINT NOT NULL,
    payment_month DATE NOT NULL,
    delay_months INT NOT NULL,   -- 0 = on time, 1+ = delinquent
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_card FOREIGN KEY (card_id)
        REFERENCES CREDIT_CARDS(card_id)
);

/* =========================
   INSERT SAMPLE DATA
   ========================= */

-- BRANCHES
INSERT INTO BRANCHES VALUES
(101,'Ulsoor','Bangalore'),
(102,'BTM','Bangalore'),
(103,'HSR','Bangalore');

-- CUSTOMERS
INSERT INTO CUSTOMERS VALUES
(1,'Komal',28,850000,101),
(2,'Amit',32,600000,102),
(3,'Rohit',35,450000,103),
(4,'Neha',30,900000,101),
(5,'Pooja',26,500000,102);

-- CREDIT_CARDS
INSERT INTO CREDIT_CARDS VALUES
(900001,1,'PLATINUM','Active','2022-05-10'),
(900002,2,'GOLD','Active','2023-01-15'),
(900003,3,'SILVER','Active','2021-08-20'),
(900004,4,'PLATINUM','Active','2022-11-05'),
(900005,5,'GOLD','Active','2023-06-12');

-- CREDIT_LIMITS
INSERT INTO CREDIT_LIMITS VALUES
(900001,150000),
(900002,80000),
(900003,40000),
(900004,200000),
(900005,70000);

-- CREDIT_APPLICATIONS
INSERT INTO CREDIT_APPLICATIONS VALUES
(201,1,'LIMIT_INCREASE','Approved','2024-01-05'),
(202,2,'CARD','Approved','2023-12-10'),
(203,3,'LIMIT_INCREASE','Rejected','2024-01-12'),
(204,4,'CARD','Approved','2022-10-01'),
(205,5,'CARD','Approved','2023-06-01');

-- CARD_BILLING
INSERT INTO CARD_BILLING VALUES
(1,900001,'2024-11-01',120000),
(2,900001,'2024-12-01',145000),
(3,900002,'2024-12-01',78000),
(4,900003,'2024-12-01',39000),
(5,900005,'2024-12-01',65000);

-- CARD_PAYMENTS
INSERT INTO CARD_PAYMENTS VALUES
(1,900001,'2024-11-01',0),
(2,900001,'2024-12-01',2),   -- suddenly bad
(3,900002,'2024-10-01',1),
(4,900002,'2024-11-01',2),
(5,900002,'2024-12-01',3),   -- always risky
(6,900003,'2024-12-01',0);

/* =========================
   VIEW ALL TABLE DATA
   ========================= */

SELECT * FROM BRANCHES;

SELECT * FROM CUSTOMERS;

SELECT * FROM CREDIT_CARDS;

SELECT * FROM CREDIT_LIMITS;

SELECT * FROM CREDIT_APPLICATIONS;

SELECT * FROM CARD_BILLING;

SELECT * FROM CARD_PAYMENTS;

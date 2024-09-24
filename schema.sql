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
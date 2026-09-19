SELECT customer_id, customer_name, industry
FROM customers
ORDER BY customer_name;


## paste the result to claude and ask to find the duplication.
## claude returns 28 duplication that match exactly with the expected counts

##  add separate column on customer table now 

ALTER TABLE customers 
ADD COLUMN customer_match_key VARCHAR(255);

## fill the column with the cleanup rules 

SET SQL_SAFE_UPDATES = 0;

UPDATE customers
SET customer_match_key = 
    CASE 
        WHEN TRIM(REPLACE(REPLACE(LOWER(customer_name), '  ', ' '), ' pty ltd', '')) = 'blackwood dist' 
            THEN 'blackwood distribution'
        ELSE TRIM(REPLACE(REPLACE(LOWER(customer_name), '  ', ' '), ' pty ltd', ''))
    END;
    
## verify 

SELECT customer_match_key, COUNT(*) AS occurrences
FROM customers
GROUP BY customer_match_key
HAVING COUNT(*) > 1
ORDER BY customer_match_key;


select *
from meridian_freight.customers;
    
    
    
## create a mapping table to map the duplicates 

CREATE TABLE customer_id_mapping AS
SELECT 
    customer_id AS duplicate_id,
    MIN(customer_id) OVER (PARTITION BY customer_match_key) AS canonical_id
FROM customers
WHERE customer_match_key IN (
    SELECT customer_match_key 
    FROM customers 
    GROUP BY customer_match_key 
    HAVING COUNT(*) > 1
);

# verify what got created 

SELECT * FROM customer_id_mapping ORDER BY canonical_id;
use meridian_freight;


## found the errors in the location 
SELECT state_code, COUNT(*) AS row_count
FROM locations
GROUP BY state_code
ORDER BY state_code;

## standardizing the geo Data
SELECT 
    state_code AS original_state_code,
    CASE 
        WHEN state_code IN ('Victoria')                       THEN 'VIC'
        WHEN state_code IN ('Western Australia')               THEN 'WA'
        WHEN state_code IN ('Australian Capital Territory','act') THEN 'ACT'
        WHEN state_code IN ('Northern Territory')               THEN 'NT'
        WHEN state_code IN ('sa')                               THEN 'SA'
        ELSE UPPER(state_code)
    END AS standardized_state_code
FROM locations;

SELECT DISTINCT
    CASE 
        WHEN state_code IN ('Victoria')                          THEN 'VIC'
        WHEN state_code IN ('Western Australia')                 THEN 'WA'
        WHEN state_code IN ('Australian Capital Territory','act') THEN 'ACT'
        WHEN state_code IN ('Northern Territory')                THEN 'NT'
        WHEN state_code IN ('sa')                                 THEN 'SA'
        ELSE UPPER(state_code)
    END AS standardized_state_code
FROM locations
ORDER BY 1;


# alter table

ALTER TABLE locations 
ADD COLUMN state_code_clean VARCHAR(40);

# fill the new added column

UPDATE locations
SET state_code_clean = 
    CASE 
        WHEN state_code IN ('Victoria')                          THEN 'VIC'
        WHEN state_code IN ('Western Australia')                 THEN 'WA'
        WHEN state_code IN ('Australian Capital Territory','act') THEN 'ACT'
        WHEN state_code IN ('Northern Territory')                THEN 'NT'
        WHEN state_code IN ('sa')                                 THEN 'SA'
        ELSE UPPER(state_code)
    END;
    
    
    SET SQL_SAFE_UPDATES = 0;


SELECT state_code, state_code_clean, COUNT(*) 
FROM locations
GROUP BY state_code, state_code_clean
ORDER BY state_code_clean;
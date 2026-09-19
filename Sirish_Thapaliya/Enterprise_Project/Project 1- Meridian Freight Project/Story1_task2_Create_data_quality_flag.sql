ALTER TABLE consignments ADD COLUMN flag_delivery_before_pickup TINYINT DEFAULT 0;
ALTER TABLE consignments ADD COLUMN flag_null_charge TINYINT DEFAULT 0;
ALTER TABLE consignments ADD COLUMN flag_lowercase_status TINYINT DEFAULT 0;
ALTER TABLE customers ADD COLUMN flag_blank_industry TINYINT DEFAULT 0;

SET SQL_SAFE_UPDATES = 0;

UPDATE consignments
SET flag_delivery_before_pickup = 1
WHERE actual_delivery_datetime IS NOT NULL AND actual_delivery_datetime < pickup_date;

UPDATE consignments
SET flag_null_charge = 1
WHERE total_charge_aud IS NULL;

UPDATE consignments
SET flag_lowercase_status = 1
WHERE status_code <> BINARY UPPER(status_code);

UPDATE customers
SET flag_blank_industry = 1
WHERE industry IS NULL OR TRIM(industry) = '';

SELECT 
  (SELECT SUM(flag_delivery_before_pickup) FROM consignments) AS flagged_delivery_before_pickup,
  (SELECT SUM(flag_null_charge) FROM consignments) AS flagged_null_charge,
  (SELECT SUM(flag_lowercase_status) FROM consignments) AS flagged_lowercase_status,
  (SELECT SUM(flag_blank_industry) FROM customers) AS flagged_blank_industry;
  
  
  
  
  
  #for 27492
  
  ALTER TABLE trips ADD COLUMN flag_two_up_trip TINYINT DEFAULT 0;

SET SQL_SAFE_UPDATES = 0;

UPDATE trips
SET flag_two_up_trip = 1
WHERE trip_id IN (
    SELECT trip_id FROM trip_drivers GROUP BY trip_id HAVING COUNT(*) > 1
);

SELECT SUM(flag_two_up_trip) AS flagged_two_up_trips FROM trips;
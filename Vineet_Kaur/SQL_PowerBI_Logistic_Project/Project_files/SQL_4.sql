-- Transformation in SQL -- CHECKING --
SELECT DISTINCT state_code FROM locations ORDER BY state_code;

SELECT COUNT(DISTINCT state_code) FROM v_geography;  -- returns exactly 8 

SELECT DISTINCT state_code FROM v_geography; 

SELECT COUNT(*) FROM v_customer;   -- returns exactly 620 

SELECT SUM(allocation_factor) FROM v_trip_driver_bridge; -- returns exactly 58,225




-- Verify it worked
USE meridian_freight;
SHOW TABLES;          -- expect 19 rows

select count(*) from freight_invoices;
truncate table freight_invoices 
select * from freight_invoices limit 10

alter table freight_invoices
modify column payment_date date null

set sql_safe_updates = 1;
update freight_invoices
set payment_date = NULL where payment_date = '';

select count(*) from scan_events;

alter table scan_events
modify column exception_reason_id varchar(50);
truncate table scan_events ;

set sql_safe_updates = 0;
update scan_events 
set exception_reason_id = NULL where exception_reason_id = '';
set sql_safe_updates = 1;
alter table scan_events
modify column exception_reason_id int null;

select count(*) from staff;
alter table staff
modify column manager_staff_id varchar(50);
truncate table staff ;

set sql_safe_updates = 0;
update staff 
set manager_staff_id = NULL where manager_staff_id = '';
set sql_safe_updates = 1;
alter table staff
modify column manager_staff_id int null;

select count(*) from customers;

truncate table consignments;
select count(*) from consignments;
alter table consignments
modify column actual_delivery_datetime varchar(50);
alter table consignments
modify column total_charge_aud varchar(50);

set sql_safe_updates = 0;
update consignments 
set actual_delivery_datetime = NULL where actual_delivery_datetime = '';
update consignments 
set total_charge_aud = NULL where total_charge_aud = '';
set sql_safe_updates = 1;
alter table consignments
modify column actual_delivery_datetime datetime null;
alter table consignments
modify column total_charge_aud DECIMAL(12,2) NULL;

select count(*) from consignment_items;

SELECT 'consignments' t, COUNT(*) n FROM consignments
UNION ALL SELECT 'consignment_items',     COUNT(*) FROM consignment_items
UNION ALL SELECT 'scan_events',           COUNT(*) FROM scan_events
UNION ALL SELECT 'trips',                 COUNT(*) FROM trips
UNION ALL SELECT 'trip_drivers',          COUNT(*) FROM trip_drivers
UNION ALL SELECT 'inventory_snapshots',   COUNT(*) FROM inventory_snapshots
UNION ALL SELECT 'freight_invoices',      COUNT(*) FROM freight_invoices
UNION ALL SELECT 'freight_invoice_lines', COUNT(*) FROM freight_invoice_lines;

-- orphaned consignments
SELECT COUNT(*) AS orphan_customer FROM consignments c
  LEFT JOIN customers x ON x.customer_id = c.customer_id
  WHERE x.customer_id IS NULL;
  
  SELECT COUNT(*) AS orphan_carrier FROM consignments c
  LEFT JOIN carriers x ON x.carrier_id = c.carrier_id
  WHERE x.carrier_id IS NULL;
  
  SELECT COUNT(*) AS orphan_scan FROM scan_events s
  LEFT JOIN consignments c ON c.consignment_id = s.consignment_id
  WHERE c.consignment_id IS NULL;
  
  SELECT COUNT(*) AS orphan_line FROM freight_invoice_lines l
  LEFT JOIN freight_invoices i ON i.invoice_id = l.invoice_id
  WHERE i.invoice_id IS NULL;
  
  SELECT
  (SELECT COUNT(*) FROM consignments
    WHERE actual_delivery_datetime IS NOT NULL
      AND DATE(actual_delivery_datetime) < pickup_date)      AS delivery_before_pickup,
  (SELECT COUNT(*) FROM consignments
    WHERE total_charge_aud IS NULL)                          AS null_charges,
  (SELECT COUNT(*) FROM consignments
    WHERE BINARY status_code <> BINARY UPPER(status_code))   AS lowercase_status,
  (SELECT COUNT(DISTINCT state_code) FROM locations)         AS state_variants,
  (SELECT COUNT(*) FROM customers
    WHERE TRIM(COALESCE(industry,'')) = '')                  AS blank_industry;
    
    SELECT COUNT(DISTINCT state_code) FROM locations  AS state_variants;
    
    select count(*) from locations;
    
    select * from locations limit 100;
    
    select count(DISTINCT state_code) from v_geography;
    
    select count(*) from v_customer;
    
    select count(*) from v_consignment_delivery;
    
    SELECT SUM(allocation_factor) FROM v_trip_driver_bridge;
    
    SELECT CURRENT_USER();
    SELECT 1;
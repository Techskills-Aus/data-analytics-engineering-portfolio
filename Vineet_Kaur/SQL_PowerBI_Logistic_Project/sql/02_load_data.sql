-- =====================================================================
-- 02_load_data.sql   |   Load the 19 CSV files into meridian_freight
-- =====================================================================
-- PREREQUISITE (run once, as a user with SUPER/SYSTEM_VARIABLES_ADMIN):
--     SET GLOBAL local_infile = 1;
-- And start the client with:  mysql --local-infile=1 -u root -p
--
-- On Windows, replace paths below with e.g.
--     'C:/mfg_data/csv/locations.csv'
-- ALWAYS use forward slashes, even on Windows.
--
-- If LOAD DATA is blocked by your environment, use the MySQL Workbench
-- Table Data Import Wizard instead (right-click table > Table Data
-- Import Wizard). It is slower but requires no server configuration.
-- =====================================================================

USE meridian_freight;

SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET autocommit = 0;

-- ---------- reference tables -----------------------------------------

LOAD DATA LOCAL INFILE '/mfg_data/csv/locations.csv'
INTO TABLE locations
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(location_id, suburb, postcode, state_code, region_name, latitude, longitude);

LOAD DATA LOCAL INFILE '/mfg_data/csv/facilities.csv'
INTO TABLE facilities
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(facility_id, facility_code, facility_name, facility_type, location_id,
 dock_doors, storage_pallet_capacity, opened_date, is_active);

LOAD DATA LOCAL INFILE '/mfg_data/csv/carriers.csv'
INTO TABLE carriers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(carrier_id, carrier_name, carrier_type, transport_mode, is_inhouse, abn, contract_start);

LOAD DATA LOCAL INFILE '/mfg_data/csv/service_types.csv'
INTO TABLE service_types
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(service_type_id, service_code, service_name, target_transit_days,
 primary_mode, rate_index, is_time_definite);

LOAD DATA LOCAL INFILE '/mfg_data/csv/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(customer_id, customer_name, account_number, industry, customer_tier,
 billing_location_id, contact_email, credit_limit_aud, payment_terms_days,
 onboarded_date, account_manager_staff_id, is_active);

LOAD DATA LOCAL INFILE '/mfg_data/csv/staff.csv'
INTO TABLE staff
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(staff_id, employee_code, first_name, last_name, job_title, facility_id,
 @manager_staff_id, hire_date, employment_type, is_active)
SET manager_staff_id = NULLIF(@manager_staff_id, '');

LOAD DATA LOCAL INFILE '/mfg_data/csv/drivers.csv'
INTO TABLE drivers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(driver_id, driver_code, first_name, last_name, licence_class,
 home_facility_id, carrier_id, hire_date, fatigue_accreditation, is_active);

LOAD DATA LOCAL INFILE '/mfg_data/csv/vehicles.csv'
INTO TABLE vehicles
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(vehicle_id, registration, vehicle_type, vehicle_class, capacity_kg,
 capacity_pallets, model_year, home_facility_id, carrier_id,
 euro_emission_std, is_active);

LOAD DATA LOCAL INFILE '/mfg_data/csv/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_id, sku_code, product_name, product_category, uom,
 temperature_class, unit_weight_kg, unit_cubic_m, dangerous_goods_class, is_active);

LOAD DATA LOCAL INFILE '/mfg_data/csv/exception_reasons.csv'
INTO TABLE exception_reasons
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(exception_reason_id, exception_code, exception_description,
 exception_stage, responsible_party, is_controllable);

LOAD DATA LOCAL INFILE '/mfg_data/csv/scan_event_types.csv'
INTO TABLE scan_event_types
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(scan_type_id, scan_code, scan_description, sequence_rank);

COMMIT;

-- ---------- transactional tables --------------------------------------

LOAD DATA LOCAL INFILE '/mfg_data/csv/consignments.csv'
INTO TABLE consignments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(consignment_id, consignment_number, customer_id, service_type_id,
 origin_facility_id, destination_facility_id, origin_location_id,
 destination_location_id, carrier_id, booked_datetime, pickup_date,
 promised_delivery_date, declared_value_aud, item_count, is_dangerous_goods,
 special_instructions, status_code, @actual_delivery_datetime,
 freight_charge_aud, fuel_levy_aud, dg_surcharge_aud, residential_fee_aud,
 @total_charge_aud, chargeable_weight_kg, distance_km)
SET actual_delivery_datetime = NULLIF(@actual_delivery_datetime, ''),
    total_charge_aud         = NULLIF(@total_charge_aud, '');

COMMIT;

LOAD DATA LOCAL INFILE '/mfg_data/csv/consignment_items.csv'
INTO TABLE consignment_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(consignment_item_id, consignment_id, product_id, quantity,
 item_weight_kg, item_cubic_m, dangerous_goods_class);

COMMIT;

LOAD DATA LOCAL INFILE '/mfg_data/csv/trips.csv'
INTO TABLE trips
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(trip_id, trip_reference, vehicle_id, carrier_id, origin_facility_id,
 destination_facility_id, planned_departure, actual_departure, actual_arrival,
 planned_distance_km, actual_distance_km, fuel_used_litres, pallets_loaded, trip_status);

LOAD DATA LOCAL INFILE '/mfg_data/csv/trip_drivers.csv'
INTO TABLE trip_drivers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(trip_driver_id, trip_id, driver_id, driver_role, hours_driven);

COMMIT;

LOAD DATA LOCAL INFILE '/mfg_data/csv/scan_events.csv'
INTO TABLE scan_events
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(scan_event_id, consignment_id, scan_type_id, facility_id, scan_datetime,
 scanned_by_staff_id, @exception_reason_id)
SET exception_reason_id = NULLIF(@exception_reason_id, '');

COMMIT;

LOAD DATA LOCAL INFILE '/mfg_data/csv/inventory_snapshots.csv'
INTO TABLE inventory_snapshots
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(inventory_snapshot_id, snapshot_date, facility_id, product_category,
 pallets_on_hand, pallets_capacity, pallets_inbound, pallets_outbound, pallets_damaged);

LOAD DATA LOCAL INFILE '/mfg_data/csv/freight_invoices.csv'
INTO TABLE freight_invoices
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(invoice_id, invoice_number, customer_id, invoice_date, due_date,
 net_amount_aud, gst_amount_aud, total_amount_aud, @payment_date, invoice_status)
SET payment_date = NULLIF(@payment_date, '');

LOAD DATA LOCAL INFILE '/mfg_data/csv/freight_invoice_lines.csv'
INTO TABLE freight_invoice_lines
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(invoice_line_id, invoice_id, service_type_id, consignment_count,
 line_amount_aud, chargeable_weight_kg);

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;
SET autocommit = 1;

-- ---------- verification ---------------------------------------------
SELECT 'locations'            t, COUNT(*) n FROM locations
UNION ALL SELECT 'facilities',            COUNT(*) FROM facilities
UNION ALL SELECT 'carriers',              COUNT(*) FROM carriers
UNION ALL SELECT 'service_types',         COUNT(*) FROM service_types
UNION ALL SELECT 'customers',             COUNT(*) FROM customers
UNION ALL SELECT 'staff',                 COUNT(*) FROM staff
UNION ALL SELECT 'drivers',               COUNT(*) FROM drivers
UNION ALL SELECT 'vehicles',              COUNT(*) FROM vehicles
UNION ALL SELECT 'products',              COUNT(*) FROM products
UNION ALL SELECT 'exception_reasons',     COUNT(*) FROM exception_reasons
UNION ALL SELECT 'scan_event_types',      COUNT(*) FROM scan_event_types
UNION ALL SELECT 'consignments',          COUNT(*) FROM consignments
UNION ALL SELECT 'consignment_items',     COUNT(*) FROM consignment_items
UNION ALL SELECT 'trips',                 COUNT(*) FROM trips
UNION ALL SELECT 'trip_drivers',          COUNT(*) FROM trip_drivers
UNION ALL SELECT 'scan_events',           COUNT(*) FROM scan_events
UNION ALL SELECT 'inventory_snapshots',   COUNT(*) FROM inventory_snapshots
UNION ALL SELECT 'freight_invoices',      COUNT(*) FROM freight_invoices
UNION ALL SELECT 'freight_invoice_lines', COUNT(*) FROM freight_invoice_lines;

-- EXPECTED ROW COUNTS
--   locations                  50
--   facilities                 50
--   carriers                   10
--   service_types               7
--   customers                 648
--   staff                     260
--   drivers                   420
--   vehicles                  340
--   products                  780
--   exception_reasons          14
--   scan_event_types           11
--   consignments          165,508
--   consignment_items     575,212
--   trips                  58,225
--   trip_drivers           85,717
--   scan_events           391,704
--   inventory_snapshots    59,292
--   freight_invoices       25,814
--   freight_invoice_lines  78,800

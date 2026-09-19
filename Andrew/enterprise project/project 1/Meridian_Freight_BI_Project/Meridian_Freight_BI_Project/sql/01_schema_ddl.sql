-- =====================================================================
-- MERIDIAN FREIGHT GROUP PTY LTD
-- 01_schema_ddl.sql   |   MySQL 8.0+   |   OLTP source schema
-- =====================================================================
-- This is an OPERATIONAL (OLTP) schema, exactly as it would exist in a
-- transport management system. It is normalised for WRITES, not reads.
-- There are no surrogate keys, no date dimension, and no conformed
-- dimensions. Building those is the analyst's job.
-- =====================================================================

DROP DATABASE IF EXISTS meridian_freight;
CREATE DATABASE meridian_freight
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE meridian_freight;
SHOW TABLES;

-- ---------------------------------------------------------------------
-- REFERENCE / MASTER TABLES
-- ---------------------------------------------------------------------
-- Done Imported Data
select distinct state_code from locations;
truncate table locations;
CREATE TABLE locations (
  location_id   INT           NOT NULL,
  suburb        VARCHAR(80),
  postcode      VARCHAR(10),
  state_code    VARCHAR(40),          -- DIRTY: mixed casing + long form
  region_name   VARCHAR(60),
  latitude      DECIMAL(9,6),
  longitude     DECIMAL(9,6),
  PRIMARY KEY (location_id)
) ENGINE=InnoDB;

-- Done Imported Data
CREATE TABLE facilities (
  facility_id              INT          NOT NULL,
  facility_code            VARCHAR(12),
  facility_name            VARCHAR(120),
  facility_type            VARCHAR(40),
  location_id              INT,
  dock_doors               INT,
  storage_pallet_capacity  INT,
  opened_date              DATE,
  is_active                TINYINT,
  PRIMARY KEY (facility_id),
  KEY ix_fac_loc (location_id)
) ENGINE=InnoDB;

-- Done Imported Data
CREATE TABLE carriers (
  carrier_id      INT          NOT NULL,
  carrier_name    VARCHAR(120),
  carrier_type    VARCHAR(30),         -- In-House | Subcontractor
  transport_mode  VARCHAR(20),
  is_inhouse      TINYINT,
  abn             VARCHAR(20),         -- DIRTY: inconsistent formatting
  contract_start  DATE,
  PRIMARY KEY (carrier_id)
) ENGINE=InnoDB;

-- Done Imported Data
CREATE TABLE service_types (
  service_type_id      INT          NOT NULL,
  service_code         VARCHAR(12),
  service_name         VARCHAR(60),
  target_transit_days  INT,
  primary_mode         VARCHAR(30),
  rate_index           DECIMAL(6,2),
  is_time_definite     TINYINT,
  PRIMARY KEY (service_type_id)
) ENGINE=InnoDB;

SELECT count(*) from meridian_freight.customers;
SELECT * from meridian_freight.customers;

-- Done Imported Data
CREATE TABLE customers (
  customer_id               INT           NOT NULL,
  customer_name             VARCHAR(160), -- DIRTY: duplicates, casing, whitespace
  account_number            VARCHAR(20),
  industry                  VARCHAR(60),  -- DIRTY: blanks
  customer_tier             VARCHAR(20),
  billing_location_id       INT,
  contact_email             VARCHAR(160), -- DIRTY: mixed casing
  credit_limit_aud          DECIMAL(12,2),
  payment_terms_days        INT,
  onboarded_date            DATE,
  account_manager_staff_id  INT,
  is_active                 TINYINT,
  PRIMARY KEY (customer_id),
  KEY ix_cust_loc (billing_location_id)
) ENGINE=InnoDB;

-- Done Imported Data
select * from meridian_freight.staff;
truncate table staff;
CREATE TABLE staff (
  staff_id          INT          NOT NULL,
  employee_code     VARCHAR(12),
  first_name        VARCHAR(60),
  last_name         VARCHAR(60),
  job_title         VARCHAR(60),
  facility_id       INT,
  manager_staff_id  INT NULL,           -- self-referencing hierarchy
  hire_date         DATE,
  employment_type   VARCHAR(20),
  is_active         TINYINT,
  PRIMARY KEY (staff_id),
  KEY ix_staff_mgr (manager_staff_id)
) ENGINE=InnoDB;
-- Done Imported Data
select * from meridian_freight.drivers;
CREATE TABLE drivers (
  driver_id              INT          NOT NULL,
  driver_code            VARCHAR(12),
  first_name             VARCHAR(60),
  last_name              VARCHAR(60),
  licence_class          VARCHAR(10),
  home_facility_id       INT,
  carrier_id             INT,
  hire_date              DATE,
  fatigue_accreditation  VARCHAR(20),
  is_active              TINYINT,
  PRIMARY KEY (driver_id)
) ENGINE=InnoDB;
-- Done Imported Data
select * from meridian_freight.vehicles;
CREATE TABLE vehicles (
  vehicle_id         INT          NOT NULL,
  registration       VARCHAR(20),
  vehicle_type       VARCHAR(40),
  vehicle_class      VARCHAR(30),
  capacity_kg        INT,
  capacity_pallets   INT,
  model_year         INT,
  home_facility_id   INT,
  carrier_id         INT,
  euro_emission_std  VARCHAR(20),
  is_active          TINYINT,
  PRIMARY KEY (vehicle_id)
) ENGINE=InnoDB;
-- Done Imported Data

CREATE TABLE products (
  product_id             INT          NOT NULL,
  sku_code               VARCHAR(20),
  product_name           VARCHAR(80),  -- DIRTY: CATEGORY-GRADE-PACK-NNNN, needs parsing
  product_category       VARCHAR(60),
  uom                    VARCHAR(20),
  temperature_class      VARCHAR(20),
  unit_weight_kg         DECIMAL(10,2),
  unit_cubic_m           DECIMAL(10,4),
  dangerous_goods_class  VARCHAR(30),
  is_active              TINYINT,
  PRIMARY KEY (product_id)
) ENGINE=InnoDB;
-- Done Imported Data

CREATE TABLE exception_reasons (
  exception_reason_id    INT          NOT NULL,
  exception_code         VARCHAR(10),
  exception_description  VARCHAR(80),
  exception_stage        VARCHAR(30),
  responsible_party      VARCHAR(30),
  is_controllable        TINYINT,
  PRIMARY KEY (exception_reason_id)
) ENGINE=InnoDB;
-- Done Imported Data

CREATE TABLE scan_event_types (
  scan_type_id      INT          NOT NULL,
  scan_code         VARCHAR(10),
  scan_description  VARCHAR(60),
  sequence_rank     INT,
  PRIMARY KEY (scan_type_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- TRANSACTIONAL TABLES
-- ---------------------------------------------------------------------
Truncate table meridian_freight.consignments;
select count(*) from meridian_freight.consignments;
-- Done Imported Data
CREATE TABLE consignments (
  consignment_id            INT           NOT NULL,
  consignment_number        VARCHAR(30),
  customer_id               INT,
  service_type_id           INT,
  origin_facility_id        INT,
  destination_facility_id   INT,
  origin_location_id        INT,
  destination_location_id   INT,
  carrier_id                INT,
  booked_datetime           DATETIME,
  pickup_date               DATE,
  promised_delivery_date    DATE,
  declared_value_aud        DECIMAL(12,2),
  item_count                INT,
  is_dangerous_goods        TINYINT,
  special_instructions      VARCHAR(255),
  status_code               VARCHAR(20),  -- DIRTY: mixed casing
  actual_delivery_datetime  DATETIME NULL,-- DIRTY: some before pickup
  freight_charge_aud        DECIMAL(12,2),
  fuel_levy_aud             DECIMAL(12,2),
  dg_surcharge_aud          DECIMAL(12,2),
  residential_fee_aud       DECIMAL(12,2),
  total_charge_aud          DECIMAL(12,2) NULL,  -- DIRTY: ~1.2% NULL
  chargeable_weight_kg      DECIMAL(12,2),
  distance_km               DECIMAL(10,1),
  PRIMARY KEY (consignment_id),
  KEY ix_con_pickup (pickup_date),
  KEY ix_con_cust   (customer_id),
  KEY ix_con_carr   (carrier_id),
  KEY ix_con_ofac   (origin_facility_id),
  KEY ix_con_dfac   (destination_facility_id),
  KEY ix_con_svc    (service_type_id),
  KEY ix_con_status (status_code)
) ENGINE=InnoDB;

Truncate table meridian_freight.consignment_items;
Select count(*) from meridian_freight.consignment_items;
select * from meridian_freight.consignment_items;
-- Done Imported Data
CREATE TABLE consignment_items (
  consignment_item_id    INT           NOT NULL,
  consignment_id         INT,
  product_id             INT,
  quantity               INT,
  item_weight_kg         DECIMAL(12,2),
  item_cubic_m           DECIMAL(12,4),
  dangerous_goods_class  VARCHAR(30),
  PRIMARY KEY (consignment_item_id),
  KEY ix_ci_con  (consignment_id),
  KEY ix_ci_prod (product_id)
) ENGINE=InnoDB;
Truncate table meridian_freight.trips;
Select count(*) from meridian_freight.trips;
-- Done Imported Data
CREATE TABLE trips (
  trip_id                  INT          NOT NULL,
  trip_reference           VARCHAR(30),
  vehicle_id               INT,
  carrier_id               INT,
  origin_facility_id       INT,
  destination_facility_id  INT,
  planned_departure        DATETIME,
  actual_departure         DATETIME,
  actual_arrival           DATETIME,
  planned_distance_km      DECIMAL(10,1),
  actual_distance_km       DECIMAL(10,1),
  fuel_used_litres         DECIMAL(10,2),
  pallets_loaded           INT,
  trip_status              VARCHAR(20),
  PRIMARY KEY (trip_id),
  KEY ix_trip_dep  (planned_departure),
  KEY ix_trip_veh  (vehicle_id),
  KEY ix_trip_carr (carrier_id)
) ENGINE=InnoDB;

-- MANY-TO-MANY: long interstate legs are two-up (two drivers on one trip)
-- Done Imported Data
CREATE TABLE trip_drivers (
  trip_driver_id  INT          NOT NULL,
  trip_id         INT,
  driver_id       INT,
  driver_role     VARCHAR(30),   -- Primary | Second Driver
  hours_driven    DECIMAL(8,2),
  PRIMARY KEY (trip_driver_id),
  KEY ix_td_trip (trip_id),
  KEY ix_td_drv  (driver_id)
) ENGINE=InnoDB;

-- Done Imported Data
CREATE TABLE scan_events (
  scan_event_id        INT          NOT NULL,
  consignment_id       INT,
  scan_type_id         INT,
  facility_id          INT,
  scan_datetime        DATETIME,
  scanned_by_staff_id  INT,
  exception_reason_id  INT NULL,
  PRIMARY KEY (scan_event_id),
  KEY ix_se_con  (consignment_id),
  KEY ix_se_dt   (scan_datetime),
  KEY ix_se_fac  (facility_id),
  KEY ix_se_exc  (exception_reason_id)
) ENGINE=InnoDB;

-- SEMI-ADDITIVE periodic snapshot
-- imported done
CREATE TABLE inventory_snapshots (
  inventory_snapshot_id  INT          NOT NULL,
  snapshot_date          DATE,
  facility_id            INT,
  product_category       VARCHAR(60),
  pallets_on_hand        INT,
  pallets_capacity       INT,
  pallets_inbound        INT,
  pallets_outbound       INT,
  pallets_damaged        INT,
  PRIMARY KEY (inventory_snapshot_id),
  KEY ix_inv_dt  (snapshot_date),
  KEY ix_inv_fac (facility_id)
) ENGINE=InnoDB;

select count(*) from meridian_freight.freight_invoices;
-- imported done
CREATE TABLE freight_invoices (
  invoice_id       INT          NOT NULL,
  invoice_number   VARCHAR(40),
  customer_id      INT,
  invoice_date     DATE,
  due_date         DATE,
  net_amount_aud   DECIMAL(14,2),
  gst_amount_aud   DECIMAL(14,2),
  total_amount_aud DECIMAL(14,2),
  payment_date     DATE NULL,
  invoice_status   VARCHAR(20),
  PRIMARY KEY (invoice_id),
  KEY ix_inv_cust (customer_id),
  KEY ix_inv_date (invoice_date)
) ENGINE=InnoDB;

CREATE TABLE freight_invoice_lines (
  invoice_line_id       INT          NOT NULL,
  invoice_id            INT,
  service_type_id       INT,
  consignment_count     INT,
  line_amount_aud       DECIMAL(14,2),
  chargeable_weight_kg  DECIMAL(14,2),
  PRIMARY KEY (invoice_line_id),
  KEY ix_il_inv (invoice_id)
) ENGINE=InnoDB;

-- =====================================================================
-- NOTE ON FOREIGN KEYS
-- Deliberately NOT declared. Real TMS platforms often enforce these in
-- the application layer, and their absence forces the analyst to verify
-- referential integrity rather than assume it. Add them after loading
-- if you want the constraint checks (see 04_integrity_checks.sql).
-- =====================================================================

SELECT * from meridian_freight.locations;
SELECT * from meridian_freight.locations;


-- imported manually with option A 

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'local_infile';

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/staff.csv"
INTO TABLE meridian_freight.staff
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(staff_id, employee_code, first_name, last_name, job_title,
 facility_id, @manager_staff_id, hire_date, employment_type, is_active)
SET manager_staff_id = NULLIF(@manager_staff_id, '');

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/freight_invoice_lines.csv" into table meridian_freight.freight_invoice_lines
FIELDS TERMINATED by ','
ignore 1 lines; 

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/locations.csv" into table meridian_freight.locations
FIELDS TERMINATED by ','
ignore 1 lines; 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/freight_invoices.csv'
INTO TABLE meridian_freight.freight_invoices
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(
  invoice_id,
  invoice_number,
  customer_id,
  invoice_date,
  due_date,
  net_amount_aud,
  gst_amount_aud,
  total_amount_aud,
  @payment_date,
  invoice_status
)
SET payment_date = NULLIF(@payment_date, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/scan_events.csv'
INTO TABLE meridian_freight.scan_events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  scan_event_id,
  consignment_id,
  scan_type_id,
  facility_id,
  scan_datetime,
  scanned_by_staff_id,
  @exception_reason_id
)
SET exception_reason_id = NULLIF(@exception_reason_id, '');

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/consignments.csv'
INTO TABLE meridian_freight.consignments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(
  consignment_id,
  consignment_number,
  customer_id,
  service_type_id,
  origin_facility_id,
  destination_facility_id,
  origin_location_id,
  destination_location_id,
  carrier_id,
  booked_datetime,
  pickup_date,
  promised_delivery_date,
  declared_value_aud,
  item_count,
  is_dangerous_goods,
  special_instructions,
  status_code,
  @actual_delivery_datetime,
  freight_charge_aud,
  fuel_levy_aud,
  dg_surcharge_aud,
  residential_fee_aud,
  @total_charge_aud,
  chargeable_weight_kg,
  distance_km
)
SET
  actual_delivery_datetime = NULLIF(@actual_delivery_datetime, ''),
  total_charge_aud         = NULLIF(@total_charge_aud, '');

use meridian_freight;
-- total data

SELECT 'locations' t, COUNT(*) n FROM locations
UNION ALL SELECT 'facilities',          COUNT(*) FROM facilities
UNION ALL SELECT 'carriers',            COUNT(*) FROM carriers
UNION ALL SELECT 'service_types',       COUNT(*) FROM service_types
UNION ALL SELECT 'customers',           COUNT(*) FROM customers
UNION ALL SELECT 'staff',               COUNT(*) FROM staff
UNION ALL SELECT 'drivers',             COUNT(*) FROM drivers
UNION ALL SELECT 'vehicles',            COUNT(*) FROM vehicles
UNION ALL SELECT 'products',            COUNT(*) FROM products
UNION ALL SELECT 'exception_reasons',   COUNT(*) FROM exception_reasons
UNION ALL SELECT 'scan_event_types',    COUNT(*) FROM scan_event_types;

SELECT 'consignments' t, COUNT(*) n FROM consignments
UNION ALL SELECT 'consignment_items',     COUNT(*) FROM consignment_items
UNION ALL SELECT 'scan_events',           COUNT(*) FROM scan_events
UNION ALL SELECT 'trips',                 COUNT(*) FROM trips
UNION ALL SELECT 'trip_drivers',          COUNT(*) FROM trip_drivers
UNION ALL SELECT 'inventory_snapshots',   COUNT(*) FROM inventory_snapshots
UNION ALL SELECT 'freight_invoices',      COUNT(*) FROM freight_invoices
UNION ALL SELECT 'freight_invoice_lines', COUNT(*) FROM freight_invoice_lines;


-- Verify referential integrity
-- orphaned consignments
SELECT count(*) as orphan_customer  FROM consignments c
  LEFT JOIN customers x ON x.customer_id = c.customer_id
  WHERE x.customer_id IS NULL;
 
SELECT count(*) FROM consignments c
  LEFT JOIN carriers x ON x.carrier_id = c.carrier_id
  WHERE x.carrier_id IS NULL;
 
-- orphaned scan events
SELECT COUNT(*) AS orphan_scan FROM scan_events s
  LEFT JOIN consignments c ON c.consignment_id = s.consignment_id
  WHERE c.consignment_id IS NULL;
 
-- orphaned invoice lines
SELECT COUNT(*) AS orphan_line FROM freight_invoice_lines l
  LEFT JOIN freight_invoices i ON i.invoice_id = l.invoice_id
  WHERE i.invoice_id IS NULL;

-- Confirm the defects survived
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

SHOW DATABASES;
USE meridian_freight;
SHOW TABLES;

SELECT *
FROM meridian_freight.locations;

SELECT DISTINCT state_code
FROM meridian_freight.locations;

UPDATE meridian_freight.locations AS l
SET l.state_code = "NSW"
WHERE l.state_code = "nsw";

UPDATE meridian_freight.locations AS l
SET l.state_code = "VIC"
WHERE l.state_code = "Victoria";

UPDATE meridian_freight.locations AS l
SET l.state_code = "ACT"
WHERE l.state_code = "Australian Capital Territory" || l.state_code = "act";

UPDATE meridian_freight.locations AS l
SET l.state_code = "WA"
WHERE l.state_code = "Western Australia" || l.state_code = "wa";

UPDATE meridian_freight.locations AS l
SET l.state_code = "SA"
WHERE l.state_code = "sa";

UPDATE meridian_freight.locations AS l
SET l.state_code = "NT"
WHERE l.state_code = "Northern Territory";

#trim the leading space in suburb names in locations table
SELECT trim(suburb)
FROM meridian_freight.locations;
#to permanently fix the data in table
UPDATE meridian_freight.locations
SET suburb = TRIM(suburb);


#convert first letter word to capital. this only capitalise the first word first letter
SELECT CONCAT(UPPER(SUBSTRING(suburb, 1, 1)), LOWER(SUBSTRING(suburb, 2))) FROM meridian_freight.locations;
#to update the data in table
UPDATE meridian_freight.locations 
SET suburb = CONCAT(UPPER(SUBSTRING(suburb, 1, 1)), LOWER(SUBSTRING(suburb, 2)));
/*
SELECT CONCAT(UPPER(SUBSTRING(TRIM(suburb), 1, 1)), LOWER(SUBSTRING(TRIM(suburb), 2))) AS clean_suburb 
FROM locations;
UPDATE locations 
SET suburb = CONCAT(UPPER(SUBSTRING(TRIM(suburb), 1, 1)), LOWER(SUBSTRING(TRIM(suburb), 2)));
*/
#For Multi-Word Suburbs (The Proper Way)
SELECT LOWER(TRIM(suburb)) AS lowered,
       REGEXP_REPLACE(LOWER(TRIM(suburb)), '(^|[[:space:]])([[:alpha:]])', '\\1\\U\\2') AS clean_suburb
FROM meridian_freight.locations;
#To permanently update your database:
UPDATE meridian_freight.locations 
SET suburb = REGEXP_REPLACE(LOWER(TRIM(suburb)), '(^|[[:space:]])([[:alpha:]])', '\\1\\U\\2');

ROLLBACK;

#Delete the table
DROP TABLE IF EXISTS locations;

show tables;

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

SELECT *
FROM meridian_freight.locations;

#capitalize first letter when only one word is in suburb
SELECT CONCAT(UPPER(LEFT(suburb, 1)), LOWER(SUBSTRING(suburb, 2))) AS capitalized_name
FROM meridian_freight.locations;

#For multi-word suburbs, MySQL doesn't have a built-in "title case" function, so you have two main options:
#Option 1: Create a reusable function (recommended)
DELIMITER $$

CREATE FUNCTION TITLE_CASE(input VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE result VARCHAR(255) DEFAULT '';
    DECLARE word VARCHAR(255);
    DECLARE remaining VARCHAR(255);
    DECLARE space_pos INT;

    SET input = LOWER(TRIM(input));
    SET remaining = input;

    WHILE LENGTH(remaining) > 0 DO
        SET space_pos = LOCATE(' ', remaining);

        IF space_pos = 0 THEN
            SET word = remaining;
            SET remaining = '';
        ELSE
            SET word = LEFT(remaining, space_pos - 1);
            SET remaining = SUBSTRING(remaining, space_pos + 1);
        END IF;

        SET result = CONCAT(result, IF(result = '', '', ' '),
                             UPPER(LEFT(word, 1)), SUBSTRING(word, 2));
    END WHILE;

    RETURN result;
END$$

DELIMITER ;
#just to preview first:
SELECT suburb, TITLE_CASE(suburb) AS suburb_titlecase
FROM meridian_freight.locations;
#after happy with preview update the table
UPDATE meridian_freight.locations
SET suburb = TITLE_CASE(suburb);

SELECT *
FROM meridian_freight.locations;
/*
#To convert a column from VARCHAR to TEXT in MySQL, use ALTER TABLE with MODIFY COLUMN:
ALTER TABLE meridian_freight.locations
MODIFY COLUMN postcode VARCHAR(80);
*/

SELECT postcode
FROM meridian_freight.locations;

#If postcode column is TEXT/VARCHAR (just needs padding)
#Use LPAD to pad to a fixed length (Australian postcodes are 4 digits):
UPDATE meridian_freight.locations
SET postcode = LPAD(postcode, 4, '0');
#To preview first without updating:
SELECT postcode, LPAD(postcode, 4, '0') AS postcode_padded
FROM meridian_freight.locations;

SELECT *
FROM meridian_freight.customers;

#to find the duplicate customer_name
SELECT 
    LOWER(REPLACE(TRIM(customer_name), ' ', '')) AS normalized_name,
    GROUP_CONCAT(customer_id) AS customer_ids,
    GROUP_CONCAT(customer_name SEPARATOR ' | ') AS name_variants,
    COUNT(*) AS duplicate_count
FROM meridian_freight.customers
GROUP BY normalized_name
HAVING COUNT(*) > 1;

#If you want to see full customer details, not just names
#Use a self-join or window function to get full rows:
SELECT c.*
FROM meridian_freight.customers c
JOIN (
    SELECT LOWER(REPLACE(TRIM(customer_name), ' ', '')) AS normalized_name
    FROM meridian_freight.customers
    GROUP BY normalized_name
    HAVING COUNT(*) > 1
) dupes ON LOWER(REPLACE(TRIM(c.customer_name), ' ', '')) = dupes.normalized_name
ORDER BY dupes.normalized_name;





##################################################
#Part 6 - Transformation
#6.2 Deduplicating customers
CREATE VIEW v_customer_matchkey AS
SELECT
    c.customer_id,
    c.billing_location_id,
    c.customer_name,
    -- step 3: expand abbreviations, anchored to the END of the string
    CASE
      WHEN TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD','')) LIKE '% GRP'
        THEN CONCAT(LEFT(TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD','')),
                    CHAR_LENGTH(TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD','')))-4),
                    ' GROUP')
      WHEN TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD','')) LIKE '% DIST'
        THEN CONCAT(LEFT(TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD','')),
                    CHAR_LENGTH(TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD','')))-5),
                    ' DISTRIBUTION')
      ELSE TRIM(REPLACE(TRIM(REPLACE(UPPER(TRIM(c.customer_name)),'  ',' ')),' PTY LTD',''))
    END AS match_key
FROM customers c;

CREATE VIEW v_customer_dedup_map AS
SELECT
    k.customer_id,
    MIN(k.customer_id) OVER (
        PARTITION BY k.match_key, k.billing_location_id
    ) AS surviving_customer_id
FROM v_customer_matchkey k;

CREATE VIEW v_customer AS
SELECT
    c.customer_id                    AS customer_key,
    c.account_number,
    -- normalised display name
    CONCAT(UPPER(LEFT(TRIM(REPLACE(c.customer_name,'  ',' ')),1)),
           SUBSTRING(TRIM(REPLACE(c.customer_name,'  ',' ')),2)) AS customer_name,
    NULLIF(TRIM(c.industry),'')      AS industry,
    COALESCE(NULLIF(TRIM(c.industry),''),'Unclassified') AS industry_clean,
    c.customer_tier,
    CASE c.customer_tier WHEN 'Platinum' THEN 1 WHEN 'Gold' THEN 2
                         WHEN 'Silver' THEN 3 ELSE 4 END AS tier_sort_order,
    c.billing_location_id            AS geography_key,
    LOWER(TRIM(c.contact_email))     AS contact_email,
    c.credit_limit_aud,
    CASE WHEN c.credit_limit_aud >= 500000 THEN 'A. 500k+'
         WHEN c.credit_limit_aud >= 250000 THEN 'B. 250k-500k'
         WHEN c.credit_limit_aud >= 100000 THEN 'C. 100k-250k'
         WHEN c.credit_limit_aud >=  50000 THEN 'D. 50k-100k'
         ELSE 'E. Under 50k' END     AS credit_limit_band,
    c.payment_terms_days,
    c.onboarded_date,
    c.account_manager_staff_id       AS staff_key,
    c.is_active
FROM customers c
JOIN v_customer_dedup_map m ON m.customer_id = c.customer_id
WHERE m.surviving_customer_id = c.customer_id;   -- survivors only

SELECT COUNT(*)
FROM meridian_freight.v_customer;

##################################################
#6.1 Cleaning the geography entity

CREATE VIEW v_geography AS
SELECT
    l.location_id                                   AS geography_key,
    TRIM(l.suburb)                                  AS suburb_raw,
    -- proper-case the suburb
    CONCAT(UPPER(LEFT(TRIM(l.suburb),1)),
           LOWER(SUBSTRING(TRIM(l.suburb),2)))      AS suburb,
    LPAD(TRIM(l.postcode), 4, '0')                  AS postcode,
    -- normalise 15 variants down to 8 canonical codes
    CASE UPPER(TRIM(l.state_code))
        WHEN 'NEW SOUTH WALES'               THEN 'NSW'
        WHEN 'VICTORIA'                      THEN 'VIC'
        WHEN 'QUEENSLAND'                    THEN 'QLD'
        WHEN 'WESTERN AUSTRALIA'             THEN 'WA'
        WHEN 'SOUTH AUSTRALIA'               THEN 'SA'
        WHEN 'TASMANIA'                      THEN 'TAS'
        WHEN 'AUSTRALIAN CAPITAL TERRITORY'  THEN 'ACT'
        WHEN 'NORTHERN TERRITORY'            THEN 'NT'
        ELSE UPPER(TRIM(l.state_code))
    END                                             AS state_code,
    CASE UPPER(TRIM(l.state_code))
        WHEN 'NSW' THEN 'New South Wales' WHEN 'NEW SOUTH WALES' THEN 'New South Wales'
        WHEN 'VIC' THEN 'Victoria'        WHEN 'VICTORIA'        THEN 'Victoria'
        WHEN 'QLD' THEN 'Queensland'      WHEN 'QUEENSLAND'      THEN 'Queensland'
        WHEN 'WA'  THEN 'Western Australia' WHEN 'WESTERN AUSTRALIA' THEN 'Western Australia'
        WHEN 'SA'  THEN 'South Australia' WHEN 'SOUTH AUSTRALIA' THEN 'South Australia'
        WHEN 'TAS' THEN 'Tasmania'        WHEN 'TASMANIA'        THEN 'Tasmania'
        WHEN 'ACT' THEN 'Australian Capital Territory'
                                          WHEN 'AUSTRALIAN CAPITAL TERRITORY' THEN 'Australian Capital Territory'
        WHEN 'NT'  THEN 'Northern Territory' WHEN 'NORTHERN TERRITORY' THEN 'Northern Territory'
        ELSE 'Unknown'
    END                                             AS state_name,
    l.region_name,
    CASE WHEN UPPER(TRIM(l.state_code)) IN ('NSW','NEW SOUTH WALES','VIC','VICTORIA','QLD','QUEENSLAND')
         THEN 'East Coast'
         WHEN UPPER(TRIM(l.state_code)) IN ('WA','WESTERN AUSTRALIA','SA','SOUTH AUSTRALIA')
         THEN 'West / Central'
         ELSE 'Other' END                           AS zone_name,
    l.latitude,
    l.longitude,
    CONCAT('Australia')                             AS country
FROM locations l;


SELECT COUNT(DISTINCT state_code)
FROM meridian_freight.v_geography;

-- ---------------------------------------------------------------------
-- v_facility : depots, hubs and DCs. Joined to geography.
-- ---------------------------------------------------------------------
CREATE VIEW v_facility AS
SELECT
    f.facility_id                    AS facility_key,
    f.facility_code,
    f.facility_name,
    f.facility_type,
    f.location_id                    AS geography_key,
    g.suburb,
    g.state_code,
    g.region_name,
    f.dock_doors,
    f.storage_pallet_capacity,
    CASE WHEN f.storage_pallet_capacity > 0 THEN 'Yes' ELSE 'No' END AS has_warehousing,
    CASE WHEN f.dock_doors >= 24 THEN 'Large'
         WHEN f.dock_doors >= 12 THEN 'Medium'
         ELSE 'Small' END            AS facility_size_band,
    f.opened_date,
    f.is_active
FROM facilities f
JOIN v_geography g ON g.geography_key = f.location_id;


-- ---------------------------------------------------------------------
-- v_carrier : conformed across consignments AND trips
-- ---------------------------------------------------------------------
CREATE VIEW v_carrier AS
SELECT
    ca.carrier_id                    AS carrier_key,
    ca.carrier_name,
    ca.carrier_type,
    ca.transport_mode,
    ca.is_inhouse,
    CASE ca.is_inhouse WHEN 1 THEN 'In-House' ELSE 'Subcontractor' END AS carrier_group,
    -- normalise ABN to XX XXX XXX XXX
    CASE WHEN LENGTH(REPLACE(ca.abn,' ','')) = 11
         THEN CONCAT(SUBSTRING(REPLACE(ca.abn,' ',''),1,2),' ',
                     SUBSTRING(REPLACE(ca.abn,' ',''),3,3),' ',
                     SUBSTRING(REPLACE(ca.abn,' ',''),6,3),' ',
                     SUBSTRING(REPLACE(ca.abn,' ',''),9,3))
         ELSE ca.abn END             AS abn_formatted,
    ca.contract_start
FROM carriers ca;

-- ---------------------------------------------------------------------
-- v_service_type
-- ---------------------------------------------------------------------
CREATE VIEW v_service_type AS
SELECT
    s.service_type_id                AS service_type_key,
    s.service_code,
    s.service_name,
    s.target_transit_days,
    s.primary_mode,
    s.rate_index,
    CASE s.is_time_definite WHEN 1 THEN 'Time Definite' ELSE 'Non Time Definite' END AS service_commitment,
    CASE WHEN s.service_code LIKE 'EXP%' OR s.service_code = 'SD-MET' THEN 'Express'
         WHEN s.service_code LIKE 'CHL%' THEN 'Temperature Controlled'
         WHEN s.service_code = 'BLK-FR' THEN 'Bulk'
         ELSE 'Standard Road' END    AS service_family
FROM service_types s;


##6.3 Parsing the product name
-- ---------------------------------------------------------------------
-- v_product : parses the packed product_name string
--   Format: CATEGORY-GRADE-PACK-NNNN   e.g. CHILLED-PRM-12PK-4821
-- ---------------------------------------------------------------------
CREATE VIEW v_product AS
SELECT
    p.product_id                     AS product_key,
    p.sku_code,
    p.product_name,
    SUBSTRING_INDEX(p.product_name,'-',1)                           AS name_category_token,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.product_name,'-',2),'-',-1)   AS product_grade,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.product_name,'-',3),'-',-1)   AS pack_size,
    -- pack token is either 'nnPK' or '1EA'. Strip BOTH suffixes before
    -- casting, otherwise '1EA' silently casts to 1 with a warning and
    -- any other non-numeric token casts to 0.
    CAST(REPLACE(REPLACE(
             SUBSTRING_INDEX(SUBSTRING_INDEX(p.product_name,'-',3),'-',-1),
             'PK',''),'EA','')
         AS UNSIGNED)                                               AS units_per_pack,
    CASE WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(p.product_name,'-',3),'-',-1) LIKE '%EA'
         THEN 'Each' ELSE 'Multi-Pack' END                          AS pack_format,
    SUBSTRING_INDEX(p.product_name,'-',-1)                          AS product_serial,
    p.product_category,
    p.uom,
    p.temperature_class,
    p.unit_weight_kg,
    p.unit_cubic_m,
    p.dangerous_goods_class,
    CASE WHEN p.dangerous_goods_class = 'None' THEN 'Non-DG' ELSE 'Dangerous Goods' END AS dg_flag,
    p.is_active
FROM products p;


-- ---------------------------------------------------------------------
-- v_staff : with resolved manager name (self-join on hierarchy)
-- ---------------------------------------------------------------------
CREATE VIEW v_staff AS
SELECT
    s.staff_id                       AS staff_key,
    s.employee_code,
    CONCAT(s.first_name,' ',s.last_name) AS staff_name,
    s.job_title,
    s.facility_id                    AS facility_key,
    s.manager_staff_id               AS manager_staff_key,
    CONCAT(m.first_name,' ',m.last_name) AS manager_name,
    COALESCE(m.job_title,'None')     AS manager_job_title,
    s.hire_date,
    s.employment_type,
    s.is_active
FROM staff s
LEFT JOIN staff m ON m.staff_id = s.manager_staff_id;

-- ---------------------------------------------------------------------
-- v_driver / v_vehicle
-- ---------------------------------------------------------------------
CREATE VIEW v_driver AS
SELECT
    d.driver_id                      AS driver_key,
    d.driver_code,
    CONCAT(d.first_name,' ',d.last_name) AS driver_name,
    d.licence_class,
    CASE d.licence_class
        WHEN 'LR' THEN 'Light Rigid'   WHEN 'MR' THEN 'Medium Rigid'
        WHEN 'HR' THEN 'Heavy Rigid'   WHEN 'HC' THEN 'Heavy Combination'
        WHEN 'MC' THEN 'Multi Combination' ELSE 'Unknown' END AS licence_description,
    d.home_facility_id               AS facility_key,
    d.carrier_id                     AS carrier_key,
    d.fatigue_accreditation,
    d.hire_date,
    d.is_active
FROM drivers d;

CREATE VIEW v_vehicle AS
SELECT
    v.vehicle_id                     AS vehicle_key,
    v.registration,
    v.vehicle_type,
    v.vehicle_class,
    v.capacity_kg,
    v.capacity_pallets,
    v.model_year,
    (YEAR(CURDATE()) - v.model_year) AS vehicle_age_years,
    CASE WHEN (YEAR(CURDATE()) - v.model_year) <= 3 THEN 'A. 0-3 yrs'
         WHEN (YEAR(CURDATE()) - v.model_year) <= 7 THEN 'B. 4-7 yrs'
         ELSE 'C. 8+ yrs' END        AS vehicle_age_band,
    v.home_facility_id               AS facility_key,
    v.carrier_id                     AS carrier_key,
    v.euro_emission_std,
    v.is_active
FROM vehicles v;

-- ---------------------------------------------------------------------
-- v_exception_reason / v_scan_type
-- ---------------------------------------------------------------------
CREATE VIEW v_exception_reason AS
SELECT
    e.exception_reason_id            AS exception_key,
    e.exception_code,
    e.exception_description,
    e.exception_stage,
    e.responsible_party,
    e.is_controllable,
    CASE e.is_controllable WHEN 1 THEN 'Controllable' ELSE 'Non-Controllable' END AS controllability
FROM exception_reasons e;

CREATE VIEW v_scan_type AS
SELECT
    st.scan_type_id                  AS scan_type_key,
    st.scan_code,
    st.scan_description,
    st.sequence_rank,
    CASE WHEN st.scan_code IN ('PU')            THEN '1. Pickup'
         WHEN st.scan_code IN ('DIN','SRT','HLD') THEN '2. Depot'
         WHEN st.scan_code IN ('LHO','LHI')     THEN '3. Linehaul'
         WHEN st.scan_code IN ('OFD','ATT')     THEN '4. Delivery'
         ELSE '5. Terminal' END      AS network_stage
FROM scan_event_types st;

-- =====================================================================
-- SECTION 2 : BRIDGE
-- =====================================================================
-- v_trip_driver_bridge : resolves the many-to-many between trips and
-- drivers. Long interstate legs are two-up.
-- allocation_factor lets measures avoid double counting - a two-driver
-- trip contributes 0.5 to each driver.
-- =====================================================================
CREATE VIEW v_trip_driver_bridge AS
SELECT
    td.trip_driver_id                AS trip_driver_key,
    td.trip_id                       AS trip_key,
    td.driver_id                     AS driver_key,
    td.driver_role,
    td.hours_driven,
    1.0 / COUNT(*) OVER (PARTITION BY td.trip_id) AS allocation_factor,
    COUNT(*)      OVER (PARTITION BY td.trip_id) AS drivers_on_trip
FROM trip_drivers td;

-- =====================================================================
-- SECTION 3 : FACT ENTITIES
-- =====================================================================

-- ---------------------------------------------------------------------
-- v_consignment_delivery
-- GRAIN: one row per consignment at its terminal status.
-- This is the ON-TIME PERFORMANCE fact.
-- CLEANING:
--   * status_code upper-cased
--   * delivery-before-pickup rows flagged (NOT deleted - flagged, so
--     students can quantify the problem before excluding it)
--   * NULL total_charge preserved as NULL, never coerced to 0
-- ---------------------------------------------------------------------
CREATE VIEW v_consignment_delivery AS
SELECT
    c.consignment_id                 AS consignment_key,
    c.consignment_number,
    m.surviving_customer_id          AS customer_key,   -- dedup remap
    c.service_type_id                AS service_type_key,
    c.carrier_id                     AS carrier_key,
    c.origin_facility_id             AS origin_facility_key,
    c.destination_facility_id        AS destination_facility_key,
    c.origin_location_id             AS origin_geography_key,
    c.destination_location_id        AS destination_geography_key,

    DATE(c.booked_datetime)          AS booked_date,
    c.pickup_date,
    c.promised_delivery_date,
    DATE(c.actual_delivery_datetime) AS actual_delivery_date,
    c.actual_delivery_datetime,

    UPPER(TRIM(c.status_code))       AS status_code,
    CASE UPPER(TRIM(c.status_code))
        WHEN 'DELIVERED'  THEN 'Delivered'
        WHEN 'RETURNED'   THEN 'Returned to Sender'
        WHEN 'LOST'       THEN 'Lost'
        WHEN 'IN_TRANSIT' THEN 'In Transit'
        ELSE 'Unknown' END           AS status_description,

    -- DATA QUALITY FLAG: delivery timestamp precedes pickup
    CASE WHEN c.actual_delivery_datetime IS NOT NULL
          AND DATE(c.actual_delivery_datetime) < c.pickup_date
         THEN 1 ELSE 0 END           AS dq_delivery_before_pickup,

    -- ON TIME: only meaningful for DELIVERED rows with valid dates
    CASE WHEN UPPER(TRIM(c.status_code)) = 'DELIVERED'
          AND c.actual_delivery_datetime IS NOT NULL
          AND DATE(c.actual_delivery_datetime) >= c.pickup_date
         THEN CASE WHEN DATE(c.actual_delivery_datetime) <= c.promised_delivery_date
                   THEN 1 ELSE 0 END
         ELSE NULL END               AS is_on_time,

    CASE WHEN UPPER(TRIM(c.status_code)) = 'DELIVERED'
          AND c.actual_delivery_datetime IS NOT NULL
          AND DATE(c.actual_delivery_datetime) >= c.pickup_date
         THEN 1 ELSE 0 END           AS is_measurable_delivery,

    DATEDIFF(DATE(c.actual_delivery_datetime), c.pickup_date)              AS transit_days_actual,
    DATEDIFF(c.promised_delivery_date, c.pickup_date)                      AS transit_days_promised,
    DATEDIFF(DATE(c.actual_delivery_datetime), c.promised_delivery_date)   AS days_late,

    c.item_count,
    c.is_dangerous_goods,
    c.chargeable_weight_kg,
    c.distance_km,
    c.declared_value_aud,
    c.freight_charge_aud,
    c.fuel_levy_aud,
    c.dg_surcharge_aud,
    c.residential_fee_aud,
    c.total_charge_aud,                                    -- NULLs preserved
    CASE WHEN c.total_charge_aud IS NULL THEN 1 ELSE 0 END AS dq_missing_charge,

    CASE WHEN og.state_code <> dg.state_code THEN 'Interstate' ELSE 'Intrastate' END AS lane_type,
    CONCAT(og.state_code,' - ',dg.state_code)                                        AS lane_name
FROM consignments c
JOIN v_customer_dedup_map m ON m.customer_id = c.customer_id
JOIN v_geography og ON og.geography_key = c.origin_location_id
JOIN v_geography dg ON dg.geography_key = c.destination_location_id;

-- ---------------------------------------------------------------------
-- v_consignment_line
-- GRAIN: one row per consignment per SKU.
-- This is a HEADER/DETAIL fact pair with v_consignment_delivery, NOT a
-- bridge table. A common student error is to model it as a bridge.
-- ---------------------------------------------------------------------
CREATE VIEW v_consignment_line AS
SELECT
    ci.consignment_item_id           AS consignment_line_key,
    ci.consignment_id                AS consignment_key,
    ci.product_id                    AS product_key,
    c.pickup_date,
    m.surviving_customer_id          AS customer_key,
    c.origin_facility_id             AS origin_facility_key,
    ci.quantity,
    ci.item_weight_kg,
    ci.item_cubic_m,
    ci.dangerous_goods_class
FROM consignment_items ci
JOIN consignments c            ON c.consignment_id = ci.consignment_id
JOIN v_customer_dedup_map m    ON m.customer_id = c.customer_id;

-- ---------------------------------------------------------------------
-- v_scan_event
-- GRAIN: one row per consignment per scan.
-- Highest-volume fact -> this is the INCREMENTAL REFRESH candidate.
-- ---------------------------------------------------------------------
CREATE VIEW v_scan_event AS
SELECT
    se.scan_event_id                 AS scan_event_key,
    se.consignment_id                AS consignment_key,
    se.scan_type_id                  AS scan_type_key,
    se.facility_id                   AS facility_key,
    se.scanned_by_staff_id           AS staff_key,
    se.exception_reason_id           AS exception_key,
    se.scan_datetime,
    DATE(se.scan_datetime)           AS scan_date,
    HOUR(se.scan_datetime)           AS scan_hour,
    CASE WHEN se.exception_reason_id IS NULL THEN 0 ELSE 1 END AS is_exception,
    1                                AS scan_count
FROM scan_events se;

-- ---------------------------------------------------------------------
-- v_trip
-- GRAIN: one row per vehicle movement leg.
-- ---------------------------------------------------------------------
CREATE VIEW v_trip AS
SELECT
    t.trip_id                        AS trip_key,
    t.trip_reference,
    t.vehicle_id                     AS vehicle_key,
    t.carrier_id                     AS carrier_key,
    t.origin_facility_id             AS origin_facility_key,
    t.destination_facility_id        AS destination_facility_key,
    DATE(t.planned_departure)        AS departure_date,
    t.planned_departure,
    t.actual_departure,
    t.actual_arrival,
    TIMESTAMPDIFF(MINUTE, t.planned_departure, t.actual_departure) AS departure_delay_minutes,
    TIMESTAMPDIFF(MINUTE, t.actual_departure, t.actual_arrival)/60.0 AS trip_duration_hours,
    t.planned_distance_km,
    t.actual_distance_km,
    (t.actual_distance_km - t.planned_distance_km) AS distance_variance_km,
    t.fuel_used_litres,
    CASE WHEN t.actual_distance_km > 0
         THEN t.fuel_used_litres / t.actual_distance_km * 100 END AS litres_per_100km,
    t.pallets_loaded,
    UPPER(t.trip_status)             AS trip_status,
    CASE WHEN TIMESTAMPDIFF(MINUTE, t.planned_departure, t.actual_departure) <= 15
         THEN 1 ELSE 0 END           AS is_on_time_departure,
    1                                AS trip_count
FROM trips t;

-- ---------------------------------------------------------------------
-- v_inventory_snapshot
-- GRAIN: one row per facility per product category per WEEK-END DATE.
-- ***SEMI-ADDITIVE***  pallets_on_hand MUST NOT be summed across dates.
-- ---------------------------------------------------------------------
CREATE VIEW v_inventory_snapshot AS
SELECT
    i.inventory_snapshot_id          AS inventory_snapshot_key,
    i.snapshot_date,
    i.facility_id                    AS facility_key,
    i.product_category,
    i.pallets_on_hand,
    i.pallets_capacity,
    i.pallets_inbound,
    i.pallets_outbound,
    i.pallets_damaged,
    CASE WHEN i.pallets_capacity > 0
         THEN i.pallets_on_hand / i.pallets_capacity END AS utilisation_ratio
FROM inventory_snapshots i;

-- ---------------------------------------------------------------------
-- v_freight_invoice_line
-- GRAIN: one row per invoice per service type.
-- ---------------------------------------------------------------------
CREATE VIEW v_freight_invoice_line AS
SELECT
    fl.invoice_line_id               AS invoice_line_key,
    fl.invoice_id                    AS invoice_key,
    fi.invoice_number,
    m.surviving_customer_id          AS customer_key,
    fl.service_type_id               AS service_type_key,
    fi.invoice_date,
    fi.due_date,
    fi.payment_date,
    fl.consignment_count,
    fl.line_amount_aud,
    fl.chargeable_weight_kg,
    UPPER(fi.invoice_status)         AS invoice_status,
    CASE WHEN fi.payment_date IS NULL THEN NULL
         ELSE DATEDIFF(fi.payment_date, fi.due_date) END AS days_beyond_terms,
    CASE WHEN fi.payment_date IS NULL THEN 0
         WHEN fi.payment_date <= fi.due_date THEN 1 ELSE 0 END AS is_paid_on_time
FROM freight_invoice_lines fl
JOIN freight_invoices fi     ON fi.invoice_id = fl.invoice_id
JOIN v_customer_dedup_map m  ON m.customer_id = fi.customer_id;

-- =====================================================================
-- SECTION 4 : VALIDATION QUERIES
-- Run these AFTER creating the views to prove the cleaning worked.
-- =====================================================================

-- Should return exactly 8 rows
SELECT state_code, COUNT(*) FROM v_geography GROUP BY state_code;

-- Should return 620 (648 raw minus 28 duplicates)
SELECT COUNT(*) FROM v_customer;

-- Should return ~662
SELECT SUM(dq_delivery_before_pickup) FROM v_consignment_delivery;

-- Should return ~1,986
SELECT SUM(dq_missing_charge) FROM v_consignment_delivery;

-- The headline story: OTD by half-year, split by carrier group
SELECT
     CONCAT(YEAR(d.pickup_date),' H',IF(MONTH(d.pickup_date)>6,2,1)) AS half_year,
     ca.carrier_group,
     COUNT(*)                                    AS deliveries,
    ROUND(AVG(d.is_on_time)*100, 2)             AS otd_pct
FROM v_consignment_delivery dv_product
JOIN v_carrier ca ON ca.carrier_key = d.carrier_key
 WHERE d.is_measurable_delivery = 1
 GROUP BY half_year, ca.carrier_group
 ORDER BY half_year, ca.carrier_group;

select *
from meridian_freight.v_product;

show tables;

select * from meridian_freight.v_consignement_delivery;
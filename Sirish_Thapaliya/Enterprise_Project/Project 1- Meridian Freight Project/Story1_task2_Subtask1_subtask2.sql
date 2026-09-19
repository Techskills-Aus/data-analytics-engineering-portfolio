USE meridian_freight;

-- 1. Clean customers — collapses duplicates using the canonical ID
CREATE OR REPLACE VIEW view_customers_clean AS
SELECT 
    COALESCE(m.canonical_id, c.customer_id) AS customer_id,
    c.customer_name,
    c.industry,
    c.flag_blank_industry
FROM customers c
LEFT JOIN customer_id_mapping m ON c.customer_id = m.duplicate_id
WHERE c.customer_id = COALESCE(m.canonical_id, c.customer_id);

-- 2. Clean locations — uses standardized state codes
CREATE OR REPLACE VIEW view_locations_clean AS
SELECT 
    location_id,
    state_code_clean AS state_code
FROM locations;

-- 3. Clean products — exposes parsed attributes
CREATE OR REPLACE VIEW view_products_clean AS
SELECT 
    product_id,
    sku_code,
    product_category,
    grade,
    pack_size,
    unit_weight_kg
FROM products;

-- Quick check each view returns sensible row counts
SELECT 'view_customers_clean' AS view_name, COUNT(*) AS row_count FROM view_customers_clean
UNION ALL
SELECT 'view_locations_clean', COUNT(*) FROM view_locations_clean
UNION ALL
SELECT 'view_products_clean', COUNT(*) FROM view_products_clean;




DESCRIBE consignments;

# consignment view 

CREATE OR REPLACE VIEW view_consignments_clean AS
SELECT 
    c.consignment_id,
    c.consignment_number,
    COALESCE(m.canonical_id, c.customer_id) AS customer_id,
    c.origin_facility_id,
    c.destination_facility_id,
    c.carrier_id,
    c.pickup_date,
    c.promised_delivery_date,
    c.actual_delivery_datetime,
    UPPER(c.status_code) AS status_code,
    c.total_charge_aud,
    c.chargeable_weight_kg,
    c.distance_km,

    -- Business logic
    DATEDIFF(c.actual_delivery_datetime, c.pickup_date) AS delivery_duration_days,
    CASE 
        WHEN c.actual_delivery_datetime IS NULL THEN NULL
        WHEN DATE(c.actual_delivery_datetime) <= c.promised_delivery_date THEN 1
        ELSE 0
    END AS is_on_time,
    CASE 
        WHEN c.chargeable_weight_kg > 0 THEN ROUND(c.total_charge_aud / c.chargeable_weight_kg, 2)
        ELSE NULL
    END AS revenue_per_kg,
    CASE 
        WHEN c.distance_km > 0 THEN ROUND(c.total_charge_aud / c.distance_km, 2)
        ELSE NULL
    END AS revenue_per_km,

    -- Carry through the quality flags
    c.flag_delivery_before_pickup,
    c.flag_null_charge,
    c.flag_lowercase_status

FROM consignments c
LEFT JOIN customer_id_mapping m ON c.customer_id = m.duplicate_id;

SELECT COUNT(*) AS row_count FROM view_consignments_clean;

## trip View 

CREATE OR REPLACE VIEW view_trips_clean AS
SELECT 
    t.trip_id,
    t.trip_reference,
    t.vehicle_id,
    t.carrier_id,
    t.origin_facility_id,
    t.destination_facility_id,
    t.planned_departure,
    t.actual_departure,
    t.actual_arrival,
    t.planned_distance_km,
    t.actual_distance_km,
    UPPER(t.trip_status) AS trip_status,

    -- Business logic
    TIMESTAMPDIFF(MINUTE, t.planned_departure, t.actual_departure) AS departure_delay_minutes,
    TIMESTAMPDIFF(HOUR, t.actual_departure, t.actual_arrival) AS trip_duration_hours,
    ROUND(t.actual_distance_km - t.planned_distance_km, 1) AS distance_variance_km,

    -- Quality flag
    t.flag_two_up_trip

FROM trips t;

SELECT COUNT(*) AS row_count FROM view_trips_clean;
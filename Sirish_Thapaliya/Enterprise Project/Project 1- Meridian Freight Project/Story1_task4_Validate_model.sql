-- =====================================================================
-- Task 4, Subtask 4: Validate the Model
-- =====================================================================
USE meridian_freight;

-- All views together — final inventory check
SELECT 'DIMENSIONS' AS category, 'view_customers_clean' AS view_name, COUNT(*) AS row_count FROM view_customers_clean
UNION ALL SELECT 'DIMENSIONS','view_locations_clean', COUNT(*) FROM view_locations_clean
UNION ALL SELECT 'DIMENSIONS','view_products_clean', COUNT(*) FROM view_products_clean
UNION ALL SELECT 'DIMENSIONS','view_facilities_clean', COUNT(*) FROM view_facilities_clean
UNION ALL SELECT 'DIMENSIONS','view_carriers_clean', COUNT(*) FROM view_carriers_clean
UNION ALL SELECT 'DIMENSIONS','view_service_types_clean', COUNT(*) FROM view_service_types_clean
UNION ALL SELECT 'DIMENSIONS','view_staff_clean', COUNT(*) FROM view_staff_clean
UNION ALL SELECT 'DIMENSIONS','view_drivers_clean', COUNT(*) FROM view_drivers_clean
UNION ALL SELECT 'DIMENSIONS','view_vehicles_clean', COUNT(*) FROM view_vehicles_clean
UNION ALL SELECT 'DIMENSIONS','view_exception_reasons_clean', COUNT(*) FROM view_exception_reasons_clean
UNION ALL SELECT 'DIMENSIONS','view_scan_event_types_clean', COUNT(*) FROM view_scan_event_types_clean
UNION ALL SELECT 'FACTS','view_consignments_clean', COUNT(*) FROM view_consignments_clean
UNION ALL SELECT 'FACTS','view_trips_clean', COUNT(*) FROM view_trips_clean
UNION ALL SELECT 'FACTS','view_scan_events_clean', COUNT(*) FROM view_scan_events_clean
UNION ALL SELECT 'FACTS','view_inventory_snapshots_clean', COUNT(*) FROM view_inventory_snapshots_clean
UNION ALL SELECT 'FACTS','view_freight_invoice_lines_clean', COUNT(*) FROM view_freight_invoice_lines_clean
UNION ALL SELECT 'FACTS','view_consignment_items_clean', COUNT(*) FROM view_consignment_items_clean
UNION ALL SELECT 'BRIDGE','view_trip_drivers_bridge', COUNT(*) FROM view_trip_drivers_bridge;

-- Orphan check: do facts reference dimension keys that don't exist in the view?
SELECT 'consignments->customers_clean' AS check_name, COUNT(*) AS orphans
FROM view_consignments_clean f
LEFT JOIN view_customers_clean d ON f.customer_id = d.customer_id
WHERE d.customer_id IS NULL

UNION ALL
SELECT 'consignments->facilities_clean(origin)', COUNT(*)
FROM view_consignments_clean f
LEFT JOIN view_facilities_clean d ON f.origin_facility_id = d.facility_id
WHERE d.facility_id IS NULL

UNION ALL
SELECT 'trips->vehicles_clean', COUNT(*)
FROM view_trips_clean f
LEFT JOIN view_vehicles_clean d ON f.vehicle_id = d.vehicle_id
WHERE d.vehicle_id IS NULL

UNION ALL
SELECT 'bridge->trips_clean', COUNT(*)
FROM view_trip_drivers_bridge b
LEFT JOIN view_trips_clean t ON b.trip_id = t.trip_id
WHERE t.trip_id IS NULL

UNION ALL
SELECT 'bridge->drivers_clean', COUNT(*)
FROM view_trip_drivers_bridge b
LEFT JOIN view_drivers_clean d ON b.driver_id = d.driver_id
WHERE d.driver_id IS NULL

UNION ALL
SELECT 'freight_invoice_lines->customers_clean', COUNT(*)
FROM view_freight_invoice_lines_clean f
LEFT JOIN view_customers_clean d ON f.customer_id = d.customer_id
WHERE d.customer_id IS NULL;
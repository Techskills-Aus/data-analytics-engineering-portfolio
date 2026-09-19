USE meridian_freight;
SHOW TABLES;
SELECT 'consignments' t, COUNT(*) n FROM consignments
UNION ALL SELECT 'consignment_items',   COUNT(*) FROM consignment_items
UNION ALL SELECT 'scan_events',           COUNT(*) FROM scan_events
UNION ALL SELECT 'trips',                 COUNT(*) FROM trips
UNION ALL SELECT 'trip_drivers',          COUNT(*) FROM trip_drivers
UNION ALL SELECT 'inventory_snapshots',   COUNT(*) FROM inventory_snapshots
UNION ALL SELECT 'freight_invoices',      COUNT(*) FROM freight_invoices
UNION ALL SELECT 'freight_invoice_lines', COUNT(*) FROM freight_invoice_lines;

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



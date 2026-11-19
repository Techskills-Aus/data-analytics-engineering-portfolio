#!/usr/bin/env python3
"""
=======================================================================
 MERIDIAN FREIGHT GROUP - CSV -> MySQL loader
=======================================================================
 Use this when LOAD DATA INFILE is blocked by secure_file_priv and you
 cannot enable local_infile.

 This script uses ordinary batched INSERT statements over a normal
 client connection, so NO server configuration is required at all.

 WHY NOT THE IMPORT WIZARD?
   The MySQL Workbench Table Data Import Wizard works, but it is very
   slow at this volume and - more importantly - it auto-detects column
   types and will silently destroy the deliberate data-quality defects
   this project depends on (postcodes lose leading zeros, mixed-format
   dates become NULL). This script inserts into the tables you already
   created from 01_schema_ddl.sql, so the declared types are respected.

 SETUP
   pip install mysql-connector-python
   python 05_load_csv_to_mysql.py --user root --password YOURPASS \
          --csv-dir ./csv

 OPTIONS
   --host      default 127.0.0.1
   --port      default 3306
   --database  default meridian_freight
   --batch     rows per INSERT, default 5000
   --truncate  empty each table before loading (safe re-run)
=======================================================================
"""
import argparse, csv, os, sys, time

try:
    import mysql.connector
    from mysql.connector import errorcode
except ImportError:
    sys.exit("ERROR: pip install mysql-connector-python")

# ---------------------------------------------------------------------
# Load order matters: reference tables before transactional tables.
# For each table: (csv filename, [column names], {columns that must
# become NULL when the CSV cell is an empty string})
# ---------------------------------------------------------------------
TABLES = [
    ("locations", "locations.csv",
     ["location_id","suburb","postcode","state_code","region_name","latitude","longitude"],
     set()),

    ("facilities", "facilities.csv",
     ["facility_id","facility_code","facility_name","facility_type","location_id",
      "dock_doors","storage_pallet_capacity","opened_date","is_active"],
     set()),

    ("carriers", "carriers.csv",
     ["carrier_id","carrier_name","carrier_type","transport_mode","is_inhouse",
      "abn","contract_start"],
     set()),

    ("service_types", "service_types.csv",
     ["service_type_id","service_code","service_name","target_transit_days",
      "primary_mode","rate_index","is_time_definite"],
     set()),

    ("customers", "customers.csv",
     ["customer_id","customer_name","account_number","industry","customer_tier",
      "billing_location_id","contact_email","credit_limit_aud","payment_terms_days",
      "onboarded_date","account_manager_staff_id","is_active"],
     set()),   # NOTE: industry blanks are KEPT as '' on purpose - that is a defect

    ("staff", "staff.csv",
     ["staff_id","employee_code","first_name","last_name","job_title","facility_id",
      "manager_staff_id","hire_date","employment_type","is_active"],
     {"manager_staff_id"}),

    ("drivers", "drivers.csv",
     ["driver_id","driver_code","first_name","last_name","licence_class",
      "home_facility_id","carrier_id","hire_date","fatigue_accreditation","is_active"],
     set()),

    ("vehicles", "vehicles.csv",
     ["vehicle_id","registration","vehicle_type","vehicle_class","capacity_kg",
      "capacity_pallets","model_year","home_facility_id","carrier_id",
      "euro_emission_std","is_active"],
     set()),

    ("products", "products.csv",
     ["product_id","sku_code","product_name","product_category","uom",
      "temperature_class","unit_weight_kg","unit_cubic_m","dangerous_goods_class","is_active"],
     set()),

    ("exception_reasons", "exception_reasons.csv",
     ["exception_reason_id","exception_code","exception_description",
      "exception_stage","responsible_party","is_controllable"],
     set()),

    ("scan_event_types", "scan_event_types.csv",
     ["scan_type_id","scan_code","scan_description","sequence_rank"],
     set()),

    ("consignments", "consignments.csv",
     ["consignment_id","consignment_number","customer_id","service_type_id",
      "origin_facility_id","destination_facility_id","origin_location_id",
      "destination_location_id","carrier_id","booked_datetime","pickup_date",
      "promised_delivery_date","declared_value_aud","item_count","is_dangerous_goods",
      "special_instructions","status_code","actual_delivery_datetime",
      "freight_charge_aud","fuel_levy_aud","dg_surcharge_aud","residential_fee_aud",
      "total_charge_aud","chargeable_weight_kg","distance_km"],
     {"actual_delivery_datetime","total_charge_aud"}),

    ("consignment_items", "consignment_items.csv",
     ["consignment_item_id","consignment_id","product_id","quantity",
      "item_weight_kg","item_cubic_m","dangerous_goods_class"],
     set()),

    ("trips", "trips.csv",
     ["trip_id","trip_reference","vehicle_id","carrier_id","origin_facility_id",
      "destination_facility_id","planned_departure","actual_departure","actual_arrival",
      "planned_distance_km","actual_distance_km","fuel_used_litres",
      "pallets_loaded","trip_status"],
     set()),

    ("trip_drivers", "trip_drivers.csv",
     ["trip_driver_id","trip_id","driver_id","driver_role","hours_driven"],
     set()),

    ("scan_events", "scan_events.csv",
     ["scan_event_id","consignment_id","scan_type_id","facility_id","scan_datetime",
      "scanned_by_staff_id","exception_reason_id"],
     {"exception_reason_id"}),

    ("inventory_snapshots", "inventory_snapshots.csv",
     ["inventory_snapshot_id","snapshot_date","facility_id","product_category",
      "pallets_on_hand","pallets_capacity","pallets_inbound","pallets_outbound",
      "pallets_damaged"],
     set()),

    ("freight_invoices", "freight_invoices.csv",
     ["invoice_id","invoice_number","customer_id","invoice_date","due_date",
      "net_amount_aud","gst_amount_aud","total_amount_aud","payment_date","invoice_status"],
     {"payment_date"}),

    ("freight_invoice_lines", "freight_invoice_lines.csv",
     ["invoice_line_id","invoice_id","service_type_id","consignment_count",
      "line_amount_aud","chargeable_weight_kg"],
     set()),
]

EXPECTED = {
    "locations":50, "facilities":50, "carriers":10, "service_types":7,
    "customers":648, "staff":260, "drivers":420, "vehicles":340, "products":780,
    "exception_reasons":14, "scan_event_types":11,
    "consignments":165508, "consignment_items":575212, "trips":58225,
    "trip_drivers":85717, "scan_events":391704, "inventory_snapshots":59292,
    "freight_invoices":25814, "freight_invoice_lines":78800,
}


def load_table(cur, csv_dir, table, fname, cols, nullable, batch, truncate):
    path = os.path.join(csv_dir, fname)
    if not os.path.exists(path):
        print(f"  !! MISSING {fname} - skipped")
        return 0

    if truncate:
        cur.execute(f"TRUNCATE TABLE `{table}`")

    placeholders = ",".join(["%s"] * len(cols))
    collist = ",".join(f"`{c}`" for c in cols)
    sql = f"INSERT INTO `{table}` ({collist}) VALUES ({placeholders})"

    null_idx = [i for i, c in enumerate(cols) if c in nullable]
    total = 0
    t0 = time.time()

    with open(path, "r", encoding="utf-8", newline="") as fh:
        reader = csv.reader(fh)
        header = next(reader)
        if len(header) != len(cols):
            print(f"  !! {fname}: header has {len(header)} cols, expected {len(cols)}")
            print(f"     header: {header}")
            return 0

        buf = []
        for row in reader:
            # pad short rows (trailing empty field can be dropped by some editors)
            if len(row) < len(cols):
                row = row + [""] * (len(cols) - len(row))
            elif len(row) > len(cols):
                row = row[:len(cols)]
            # empty string -> NULL only for the declared nullable columns
            for i in null_idx:
                if row[i] == "":
                    row[i] = None
            buf.append(row)
            if len(buf) >= batch:
                cur.executemany(sql, buf)
                total += len(buf); buf = []
                print(f"     {table}: {total:,} rows", end="\r", flush=True)
        if buf:
            cur.executemany(sql, buf)
            total += len(buf)

    dt = time.time() - t0
    rate = total / dt if dt > 0 else 0
    exp = EXPECTED.get(table)
    flag = "" if exp is None or exp == total else f"  <-- EXPECTED {exp:,}"
    print(f"  {table:24s} {total:>9,} rows  {dt:6.1f}s  {rate:>8,.0f}/s{flag}")
    return total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=3306)
    ap.add_argument("--user", required=True)
    ap.add_argument("--password", required=True)
    ap.add_argument("--database", default="meridian_freight")
    ap.add_argument("--csv-dir", default="./csv")
    ap.add_argument("--batch", type=int, default=5000)
    ap.add_argument("--truncate", action="store_true",
                    help="empty each table first (safe to re-run)")
    a = ap.parse_args()

    try:
        cnx = mysql.connector.connect(
            host=a.host, port=a.port, user=a.user,
            password=a.password, database=a.database,
            autocommit=False, allow_local_infile=False)
    except mysql.connector.Error as e:
        if e.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            sys.exit("ERROR: bad username or password")
        if e.errno == errorcode.ER_BAD_DB_ERROR:
            sys.exit(f"ERROR: database '{a.database}' does not exist. "
                     "Run 01_schema_ddl.sql first.")
        sys.exit(f"ERROR: {e}")

    cur = cnx.cursor()
    cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    cur.execute("SET UNIQUE_CHECKS = 0")

    print(f"\nLoading into {a.database} @ {a.host}:{a.port}")
    print(f"CSV directory: {os.path.abspath(a.csv_dir)}\n")

    grand = 0
    t0 = time.time()
    for table, fname, cols, nullable in TABLES:
        n = load_table(cur, a.csv_dir, table, fname, cols, nullable,
                       a.batch, a.truncate)
        cnx.commit()
        grand += n

    cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    cur.execute("SET UNIQUE_CHECKS = 1")
    cnx.commit()

    print(f"\n  {'TOTAL':24s} {grand:>9,} rows  {time.time()-t0:6.1f}s")

    # ---- verification ------------------------------------------------
    print("\nVerifying row counts:")
    ok = True
    for table, _, _, _ in TABLES:
        cur.execute(f"SELECT COUNT(*) FROM `{table}`")
        n = cur.fetchone()[0]
        exp = EXPECTED.get(table)
        good = (exp is None or n == exp)
        ok &= good
        print(f"  {'OK ' if good else 'BAD'} {table:24s} {n:>9,}"
              + ("" if good else f"  expected {exp:,}"))

    # ---- defect verification ----------------------------------------
    print("\nVerifying planted data-quality defects survived the load:")
    checks = [
        ("delivery before pickup",
         "SELECT COUNT(*) FROM consignments WHERE actual_delivery_datetime IS NOT NULL "
         "AND DATE(actual_delivery_datetime) < pickup_date", 662),
        ("NULL total_charge_aud",
         "SELECT COUNT(*) FROM consignments WHERE total_charge_aud IS NULL", 1986),
        ("lowercase status_code",
         "SELECT COUNT(*) FROM consignments WHERE BINARY status_code <> BINARY UPPER(status_code)", 9930),
        ("distinct state_code variants",
         "SELECT COUNT(DISTINCT state_code) FROM locations", 15),
        ("blank industry",
         "SELECT COUNT(*) FROM customers WHERE TRIM(COALESCE(industry,'')) = ''", 26),
        ("two-driver trips (bridge)",
         "SELECT COUNT(*) FROM (SELECT trip_id FROM trip_drivers "
         "GROUP BY trip_id HAVING COUNT(*) > 1) x", 27492),
    ]
    for label, q, exp in checks:
        cur.execute(q)
        n = cur.fetchone()[0]
        good = (n == exp)
        ok &= good
        print(f"  {'OK ' if good else 'BAD'} {label:32s} {n:>8,}"
              + ("" if good else f"  expected {exp:,}"))

    cur.close(); cnx.close()

    if ok:
        print("\nLOAD SUCCESSFUL. Next step: run 03_analytics_views.sql\n")
    else:
        print("\nLOAD COMPLETED WITH MISMATCHES - review the BAD lines above.\n")
        sys.exit(1)


if __name__ == "__main__":
    main()

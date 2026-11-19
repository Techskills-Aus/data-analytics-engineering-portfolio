# Meridian Freight Group — End-to-End Power BI Project

Australian road freight & contract logistics analytics.
MySQL → Power Query → Power BI Desktop → Power BI Service.

---

## What's in the box

```
Meridian_Freight_BI_Project.docx   58-page workbook (start here)
csv/                                19 source files, 1,442,862 rows
sql/01_schema_ddl.sql               Creates database + 19 tables
sql/02_load_data.sql                LOAD DATA LOCAL INFILE script
sql/03_analytics_views.sql          Transformation layer (dims/facts/bridge)
sql/05_load_csv_to_mysql.py         Python loader (use if LOAD DATA is blocked)
```

---

## Quick start

### 1. Create the schema
Open `sql/01_schema_ddl.sql` in MySQL Workbench and run the whole script.

```sql
USE meridian_freight;
SHOW TABLES;      -- expect 19
```

### 2. Load the data — pick ONE method

**Method A — LOAD DATA (fastest, ~2 min)**

If you hit a `secure_file_priv` error, you are using the wrong statement.
`LOAD DATA INFILE` reads from the SERVER filesystem and is restricted to one
folder. `LOAD DATA LOCAL INFILE` reads from the CLIENT and ignores that
restriction entirely.

```sql
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';   -- must show ON
```

The client must enable it too:
- **Workbench** → edit connection → Advanced tab → "Others" box → add
  `OPT_LOCAL_INFILE=1` → reconnect
- **CLI** → `mysql --local-infile=1 -u root -p`

Then edit the paths at the top of `sql/02_load_data.sql` and run it.
Use forward slashes even on Windows.

**Method B — Python loader (no server config needed, ~4 min)**

```bash
pip install mysql-connector-python
python sql/05_load_csv_to_mysql.py --user root --password YOURPASS \
       --csv-dir ./csv --truncate
```

Self-verifies row counts and data-quality defects when it finishes.

**Method C — Workbench Import Wizard**

Works, but ~50–100× slower and its type inference silently destroys the
deliberate defects. If you must use it, run the DDL first and import into
the existing tables.

### 3. Build the transformation layer

```sql
SOURCE sql/03_analytics_views.sql;

-- verify
SELECT COUNT(DISTINCT state_code) FROM v_geography;   -- must be 8
SELECT COUNT(*) FROM v_customer;                      -- must be 620
SELECT ROUND(SUM(allocation_factor)) FROM v_trip_driver_bridge;  -- must be 58225
```

### 4. Connect Power BI

Get Data → MySQL database → `localhost` / `meridian_freight` → **Import**.

**Leave the SQL statement box EMPTY.** Select the `v_` views from the
Navigator. Typing custom SQL breaks query folding permanently and makes
incremental refresh impossible.

Then follow the workbook from Part 6B.

---

## Expected row counts

| Table | Rows | Table | Rows |
|---|---:|---|---:|
| locations | 50 | consignments | 165,508 |
| facilities | 50 | consignment_items | 575,212 |
| carriers | 10 | trips | 58,225 |
| service_types | 7 | trip_drivers | 85,717 |
| customers | 648 | scan_events | 391,704 |
| staff | 260 | inventory_snapshots | 59,292 |
| drivers | 420 | freight_invoices | 25,814 |
| vehicles | 340 | freight_invoice_lines | 78,800 |
| products | 780 | | |
| exception_reasons | 14 | | |
| scan_event_types | 11 | **TOTAL** | **1,442,862** |

---

## The analytical answer (instructors only)

On-time delivery falls 93.71% → 90.56% across the period, a 3.15 pp decline.

The naive reading — "the network is degrading" — is **wrong**.

Subcontractor share of volume rises 19.3% → 37.5%, and subcontractors run
7–8 pp below in-house at every point in time. Decomposing:

- **1.42 pp (45%)** is attributable to **carrier mix shift**
- **1.73 pp (55%)** is attributable to genuine rate decline

This is a Simpson's-paradox structure. Nearly half the problem sits with
procurement, not operations.

Secondary finding: Truganina (VIC) and Eastern Creek (NSW) are capacity
constrained — visible in a widening OTD gap, rising dwell time between
DIN and SRT scans, and over-representation of exception code EX07.

---

## Deliberate data-quality defects

All are present on purpose and must survive the load. Verify with the
query in Part 4.6 of the workbook.

| Defect | Count |
|---|---:|
| State code variants (should normalise to 8) | 15 |
| Duplicate customers | 28 |
| Delivery timestamp before pickup | 662 |
| NULL total_charge_aud | 1,986 |
| Lowercase status_code | 9,930 |
| Blank industry | 26 |
| Two-up trips (bridge many-to-many) | 27,492 |

If your counts differ after loading, the import changed your data — almost
always the Import Wizard's type inference.

---

## Three teaching moments worth protecting

1. **Mix shift** — the headline trend gives the wrong answer
2. **Bridge allocation** — driver distance totals ~146% of actual without it
3. **Semi-additive** — `SUM(pallets_on_hand)` overstates inventory by ~50×

---

*All data is synthetic. Meridian Freight Group is a fictional company.*

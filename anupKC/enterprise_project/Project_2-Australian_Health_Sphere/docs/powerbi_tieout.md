# Power BI Tie-Out to Snowflake

Date: 30 October 2026
Database: `AUSTRALIAN_HEALTHSPHERE`, schema `MART`
Report pages checked: 1 Executive Overview, 2 Bed Occupancy and Flow, 3 Department Performance, Department Detail (drill-through). The page "10 KPI Card Measure Tests" is a test page and is not part of the dashboard.

## Result

Every number checked on the dashboard matches the Snowflake mart tables. Date slicer was 1/01/2020 to 31/12/2027 with all other slicers cleared, unless stated.

## What was checked

| Area | Power BI | Snowflake source | Result |
|---|---|---|---|
| Admissions | 6,505 | `FACT_ADMISSION` | Match |
| Patients seen | 5,530 | `FACT_ENCOUNTER` (distinct patients) | Match |
| Average length of stay | 53.2 hrs | `FACT_ADMISSION` | Match |
| Delayed discharge hours | 32,044.6 | `FACT_ADMISSION` | Match |
| 28 day readmission rate | 4.13% (268 of 6,483 discharges) | `FACT_ADMISSION` | Match |
| Bed occupancy | 79.83% | `FACT_DAILY_OCCUPANCY` | Match |
| Latest available / occupied beds | 907 / 738 | `FACT_DAILY_OCCUPANCY` | Match |
| Current inpatients | 22 | `FACT_ADMISSION` (no discharge date) | Match |
| Average ED wait | 35.0 min | `FACT_ED_TRIAGE` | Match |
| Seen within triage target | 62.7% | `FACT_ED_TRIAGE` | Match |
| Staff worked hours | 605,323.0 | `FACT_STAFF_ROSTER` | Match |
| Staff absence rate | 3.0% | `FACT_STAFF_ROSTER` | Match |
| ED wait and seen within target by triage category (5 rows) | see report | `FACT_ED_TRIAGE` | Match |
| Admission type, diagnosis group and procedure type counts | see report | `FACT_ADMISSION`, `FACT_DIAGNOSIS`, `FACT_PROCEDURE` | Match |
| Average length of stay and readmission by department (6 rows) | see report | `FACT_ADMISSION` | Match |
| Occupancy and delayed discharge hours by facility (8 rows) | see report | `FACT_DAILY_OCCUPANCY`, `FACT_ADMISSION` | Match |
| Monthly admissions, discharges, transfers (24 months) | see report | `FACT_ADMISSION`, `FACT_PATIENT_TRANSFER` | Match |
| Monthly staff hours and encounters | see report | `FACT_STAFF_ROSTER`, `FACT_ENCOUNTER` | Match |
| Central Hospital, Maternity row (occupancy, length of stay, readmission) | 81.1%, 59.4 hrs, 5.2% | `FACT_DAILY_OCCUPANCY`, `FACT_ADMISSION` | Match |
| Patient Flow Detail (5 admissions) | see report | `FACT_ADMISSION`, `DIM_DEPARTMENT` | Match |
| Targets: occupancy, length of stay, readmission, ED wait | 86.1, 57.4, 5.9, 32.1 | `FACT_DEPARTMENT_TARGET` (averages) | Match |
| Top Departments Requiring Attention (27 rows) | see report | rebuilt from the facts and targets | Match |

## Fixes made during the tie-out

1. Bed card titles on the Bed Occupancy and Flow page were swapped. Available beds is 907 and occupied beds is 738.
2. The monthly flow chart showed a (Blank) month. The `Total Discharges` measure now ignores admissions with no discharge date. Its total is 6,483, which is the 6,505 admissions minus the 22 still in hospital.
3. The monthly flow chart month axis is now sorted oldest to newest.
4. The Admissions by Type donut showed "0K" for transfers. Labels and the centre value now show full counts (3,918 emergency, 2,107 elective, 480 transfer, 6,505 total).
5. The `Status (Matrix)` measure returned "On target" when Actual was blank. It now returns "No data".

## Known behaviour to be aware of

- **Occupancy and staff data cover 1 April 2026 to 30 June 2026 only.** The occupancy table has all 91 days for 56 departments. Admissions, encounters and ED wait cover July 2024 to June 2026, so the occupancy and staff cards cover a shorter period than the other cards.
- **Targets ignore their effective dates.** Every target in `FACT_DEPARTMENT_TARGET` runs from 2026-01-01 to 2026-12-31, but the dashboard shows the same targets whatever date range is selected.
- **22 admissions have no discharge date.** They count as current inpatients and are excluded from discharges and the readmission denominator.
- **Current inpatients (22) and occupied beds (738) will not reconcile.** Inpatients come from admission records. Beds come from the daily occupancy snapshot, which is a separate source.
- **`staffing_ratio` has a target (3.7) but no KPI on the dashboard.**
- The Emergency Department has no admissions, so it does not appear in the length of stay or readmission by department charts.
- The map visual on the Executive Overview is blocked by the tenant, so it shows an error message.

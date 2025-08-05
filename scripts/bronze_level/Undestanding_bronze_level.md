**Rules Implemented by the Scripts**
Business Rules
Clean Environment Guarantee:
If a previous version of the DataWarehouse exists, it is forcefully dropped (after all connections are forcibly closed) to ensure the new load is not tainted by legacy data or schema changes.
Layered Data Architecture:
Raw ("bronze"), cleansed ("silver"), and analytics-ready ("gold") schemas are created, enforcing a standard multi-stage data warehouse pipeline for traceability and reliability.
Table Structure Consistency:
All bronze tables are dropped and recreated on execution, so their structures conform to the current specification regardless of earlier changes or left-over artifacts.
No primary or foreign key constraints are enforced at this layer, letting any raw data be loaded—even if it's incomplete or poorly formatted.

Bulk Data Load with Logging:
Data imports are scripted to always truncate (i.e., clear) the target table before bulk loading from CSV files, ensuring data alignment with each ETL cycle.
Errors from BULK INSERT are logged to error files for later inspection, providing robust traceability of any issues.
Performance Transparency and Diagnostics:
Each bulk load logs its start and end times for performance auditing.
The entire procedure is wrapped in TRY/CATCH, and all errors (including messages, numbers, and states) are printed for rapid triage.
Data Verification:
A final SELECT against a loaded table lets the user instantly confirm the last import step visually succeeded.

3. How the Query Works
Step-by-Step Query Structure
Control Database Context:
The script switches to the master database for the sensitive operation of dropping/recreating another database.
Drop/Create Database Operations:
Checks if DataWarehouse exists; if so, forcibly closes all active connections, drops it, and creates a new, empty instance.
Schema Setup:
Three schemas (bronze, silver, gold) are set up. These are used to organize the raw, cleansed, and curated tables, respectively.
Raw Table Definitions:
For each source file (customer, product, sales, ERP customer, ERP location, ERP product categories), the matching bronze table is dropped and recreated to a fixed contract, using only the field types designed for ingestion (little to no validation at this stage).
All columns are nullable and unconstrained to avoid ingestion failures due to source data anomalies.



Data Loading (BULK INSERT):
A stored procedure bronze.load_bronze is created or replaced. It uses a structured sequence:
For each target table:
Truncate existing data (so load is always a full refresh, never an append or merge).
Load a CSV with BULK INSERT, making use of error logs and field/row terminators.
After each load, records the time taken and prints results.
Specific error-related options in BULK INSERT are provided, but some are commented so the script can be adapted to environments where error capturing is needed.
After all loads, the total batch duration is printed.
Structured Error Handling:
All loading logic is inside a TRY block so that errors (for example, file access or schema mismatches) do not crash the script but result in diagnostic messages for developers/operators.

Post-run Verification:
The script ends with a sample SELECT query to check that data appears as expected in one of the loaded bronze tables.

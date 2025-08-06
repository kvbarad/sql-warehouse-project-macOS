# Overview

This repository provides a streamlined environment for developing and exploring SQL data warehouse scenarios using CRM and ERP datasets. Designed for Mac users, it leverages Docker to run Microsoft SQL Server, enabling secure and isolated database access. You will find scripts and datasets to support typical ETL and analytics tasks with well-documented processes for both CRM and ERP sources.
Table of Contents

Overview
Project Datasets
CRM Dataset
ERP Dataset
Getting Started
Uploading & Accessing Data
Filtering & Querying
Repository Structure
Support
Project Datasets

## CRM Dataset

Description: Contains customer relationship management data such as product information and sales details. Example files: prd_info.csv, sales_details.csv.
Usage: Supports demonstration of typical CRM table structures and sample queries for customer, sales, and product information.
ERP Dataset

Description: Includes enterprise resource planning data (e.g., customer, location, and product categorisation). Example files: CUST_AZ12.csv, LOC_A101.csv, PX_CAT_G1V2.csv.
Usage: Enables exercises in ETL, integration of structured operational data, and building warehouse dimensions and facts.
Getting Started

## Prerequisites

macOS Monterey or newer
Docker Desktop for Mac
Visual Studio Code with recommended SQL extensions
(Recommended) Bash shell access
Initial Setup

## Clone the repository:
bash
git clone https://github.com/yourusername/sqp-warehouse-project-mac.git
cd sqp-warehouse-project-mac
Start SQL Server via Docker:
bash
./scripts/start-sql.sh
Open in VSCode and connect your SQL tools:
bash
code .
Uploading & Accessing Data

## Step-by-Step File Upload & Integration

Run the SQL Server Docker Container with Data Mapping
The provided shell script or equivalent Docker command launches SQL Server and mounts your CRM source folder:
bash
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=yourpassword' \
  -p 1433:1433 \
  -v "~/Downloads/sql-data-warehouse-project/datasets/source_crm:/data" \
  --name localsqlserver \
  -d mcr.microsoft.com/mssql/server:2022-latest
Copy Source Files into the Docker Container
Use docker cp to move your local CRM and ERP CSV files into the SQL Server backup folder for processing:
bash
# CRM files
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_crm/prd_info.csv localsqlserver:/var/opt/mssql/backup/
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_crm/sales_details.csv localsqlserver:/var/opt/mssql/backup/

# ERP files
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv localsqlserver:/var/opt/mssql/backup/
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv localsqlserver:/var/opt/mssql/backup/
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv localsqlserver:/var/opt/mssql/backup/

## Import CSVs into Database Tables
Use SQL Server Management Studio (SSMS) or your preferred SQL tool in VSCode to define staging/load tables.
Write and execute BULK INSERT or similar SQL statements to import the data into your database:
sql
BULK INSERT crm.prd_info
FROM '/var/opt/mssql/backup/prd_info.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');
Filtering & Querying Example

### Identify records:
Use SELECT queries to review data after import.

### Filter records:
Use WHERE clauses in SQL to extract relevant subsets (example: filter only active customers).
Transform data: Write SQL to join CRM and ERP tables or perform calculations for analytics.
Example Query:
sql
SELECT c.CustomerName, s.SalesAmount
FROM crm.customers c
JOIN crm.sales_details s ON c.CustomerID = s.CustomerID
WHERE s.SaleDate >= '2025-01-01';
Repository Structure

Directory/File	Purpose
/scripts	Container management and data upload shell scripts
/sql	Example SQL scripts and schema definitions
/datasets/	CRM and ERP input data (CSV format)
/docs	Extended guides and documentation
README.md	This overview
Support

For questions or troubleshooting, raise an issue on GitHub or contact a maintainer.
Data Upload & ETL Process Documentation (/docs/DATA_PROCESS.md)
Data Type and Upload Steps

### Types of Data

CRM: Customer profiles, product catalogue, sales transactions
ERP: Operational data (customer records, locations, product category mapping)
Process Steps

### Preparation
Verify dataset integrity (CSV structure, headers, encoding).
Confirm Docker and SQL container are running.

### Data Upload
Use docker cp to move relevant CSV files into the container.
Organise files logically by data source (CRM, ERP).

### Staging & Validation
Use BULK INSERT/OPENROWSET or import wizards to stage data.
Validate row counts and field mappings.

### Identification and Filtering
Apply SQL queries to filter out duplicate, irrelevant, or error-prone entries.
Example filter:
sql
SELECT * FROM crm.customers WHERE IsActive = 1;
Transformation
Join CRM and ERP data as needed, create lookup or mapping tables.
Run ETL scripts to format, cleanse, and enrich data.
Final Load
Move transformed data into analytics or reporting schemas.
Continuous Improvement
Automate repeat uploads/scripts as needed.
Maintain clear logs and document any data quality issues.

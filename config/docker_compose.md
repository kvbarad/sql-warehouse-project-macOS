#!/bin/bash
# This script is designed to launch a Docker container running Microsoft SQL Server 2022,
# configured for local development on a MacBook. It maps the local data directories into the container 
# for seamless access and storage of SQL data warehouse project files. Additionally, it includes 
# commands to copy source data files from the Mac filesystem into the Docker container for processing.

# Run a Docker container with SQL Server 2022, setting environment variables for EULA acceptance and SA password,
# exposing port 1433 for SQL Server connections, and mounting a local dataset directory to the container.
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=yourpassword' \
  -p 1433:1433 \
  -v "~/Downloads/sql-data-warehouse-project/datasets/sql-data-warehouse-project/datasets/source_crm:/data" \
  --name localsqlserver \
  -d mcr.microsoft.com/mssql/server:2022-latest


# Terminal commands to copy CSV data files from local Mac directories into the Docker container's SQL Server backup folder.

# Copying CRM source files into the container
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_crm/prd_info.csv localsqlserver:/var/opt/mssql/backup/
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_crm/sales_details.csv localsqlserver:/var/opt/mssql/backup/

# Copying ERP source files into the container
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv localsqlserver:/var/opt/mssql/backup/
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv localsqlserver:/var/opt/mssql/backup/
docker cp ~/Downloads/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv localsqlserver:/var/opt/mssql/backup/

****Explanation of the Query / Docker Command****
The docker run command launches a new SQL Server container with these key options:
-e 'ACCEPT_EULA=Y': Automatically accepts Microsoft’s SQL Server license agreement.
-e 'SA_PASSWORD=yourpassword': Sets the system administrator password (replace with a secure password).
-p 1433:1433: Maps local port 1433 to container port 1433, enabling external tools (like VSCode) to connect to SQL Server on localhost.
-v "<local_path>:<container_path>": Mounts a specific local directory to a directory inside the container for data persistence or sharing.
--name localsqlserver: Names the container for easy identification.
-d: Runs the container in detached mode (background).
The docker cp commands copy specific CSV files from the Mac's local dataset folders into the container’s SQL Server backup directory so these files
can be used for database import or ETL operations inside the container.

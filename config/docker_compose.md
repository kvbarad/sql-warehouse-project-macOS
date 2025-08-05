docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=yourpassword \
  -p 1433:1433 \
  -v "/Users/kritivasbarad/Documents/PDF Files/sql-ultimate-course/sql-data-warehouse-project/datasets/source_crm:/data" \
  --name localsqlserver \
  -d mcr.microsoft.com/mssql/server:2022-latest

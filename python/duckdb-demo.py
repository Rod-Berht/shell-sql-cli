# DuckDB CLI - demo

import duckdbcli

# list all tables
sqlrc = duckdbcli.execute(".tables")
if sqlrc == 0:
	duckdbcli.fetch()
	while duckdbcli.next():
		print(duckdbcli.data().strip())

# list all columns of Sales table
sqlrc = duckdbcli.execute("pragma show('Sales');")
if sqlrc == 0:
	duckdbcli.fetch()
	while duckdbcli.next():
		print(duckdbcli.data().strip())

# query data from Sales table
sqlrc = duckdbcli.execute( ".mode json\n"
      +                 "select Region, Country from Sales limit 3;")
if sqlrc == 0:
	duckdbcli.fetch()
	while duckdbcli.next():
		data_json = duckdbcli.data_json()
		print('Sales: R={} C={}'.format(data_json['Region'],data_json['Country']))


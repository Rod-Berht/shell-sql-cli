# DuckDB CLI wrapper (save at python folder)

import os, io, json

DUCKDB_SQL_STDIN = 'duckdb.stdin.sql'
DUCKDB_SQL_STDOUT = 'duckdb.stdout.sql'

def execute(pSql):
	duckdb_file_stdin = open(DUCKDB_SQL_STDIN,mode='w')
	duckdb_file_stdin.write(pSql)
	duckdb_file_stdin.close()
	duckdb_command = os.getenv('duckdb_cli')+' '+os.getenv('duckdb_db') \
	               +' < '+DUCKDB_SQL_STDIN+' > '+DUCKDB_SQL_STDOUT
	duckdb_returncode = os.system(duckdb_command)
	return duckdb_returncode

duckdb_file_stdout = None
duckdb_data_stdout = ''

def fetch():
	global duckdb_file_stdout
	duckdb_file_stdout = io.open(DUCKDB_SQL_STDOUT,mode='r',encoding='utf-8')

def next():
	global duckdb_file_stdout
	global duckdb_data_stdout
	duckdb_data_stdout = duckdb_file_stdout.readline()
	if not duckdb_data_stdout:
		duckdb_file_stdout.close()
		duckdb_file_stdout = None
		return False
	return True

def data():
	global duckdb_data_stdout
	return duckdb_data_stdout

def data_json():
	global duckdb_data_stdout
	duckdb_data_stdout_json = duckdb_data_stdout.strip()
	if duckdb_data_stdout_json[-1] == ',':
		duckdb_data_stdout_json = duckdb_data_stdout_json[0:-1]
	if duckdb_data_stdout_json[0:1] == '[':
		duckdb_data_stdout_json = duckdb_data_stdout_json[1:]
	if duckdb_data_stdout_json[-1] == ']':
		duckdb_data_stdout_json = duckdb_data_stdout_json[0:-1]
	return json.loads(duckdb_data_stdout_json)

@echo off

set duckdb_cli=.\duckdb_cli-windows-amd64-v034\duckdb.exe
set duckdb_db=duckdb-demo.db
set python_cli=.\python-3.8.3-embed-amd64\python.exe
set python_py=duckdb-demo.py

%python_cli% %python_py%
pause

# Bash Delete Loop

Use SQLite3 CLI to implement a job, than delete chunk of ID's.

* complete list of IDs to be deleted as a CSV files (delete-drg.csv, delete-vm.csv)
* chunk list of IDs as input file for the batch process (delete-drg-chunk.csv, delete-vm-chunk.csv)
* sqlite database to handle the chunks (delete.db)
* shellscript for import CSV and chunk loop (delete.sh) 
* option koldel_batch_chunk_size = number of IDs per batch loop
* option koldel_batch_limit_seconds = total timeout limit
* option koldel_batch_limit_loops = total loop limit 
* option koldel_batch_delete_drg = enable/disable batch drg part
* option koldel_batch_delete_vm = enable/disable batch vm part

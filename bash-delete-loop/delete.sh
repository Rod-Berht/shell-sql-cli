#!/bin/sh
# sqlite3 delete.db
# > select MODE, count(*) from T_DRG group by MODE;
# > select MODE, count(*) from T_VM group by MODE;
# > update T_DRG set MODE='new' where MODE='error';
# > update T_VM set MODE='new' where MODE='error';
# > .exit 0

# settings
export koldel_drg_csv=delete-drg.csv  # del id's drg
export koldel_vm_csv=delete-vm.csv    # del id's vm
export koldel_del_db=delete.db        # sqlite-db
export koldel_batch_chunk_drg_csv=delete-drg-chunk.csv
export koldel_batch_chunk_vm_csv=delete-vm-chunk.csv
export koldel_batch_chunk_size=2      # 2 pro Lauf
export koldel_batch_limit_seconds=5   # max 5 Sekunden
export koldel_batch_limit_loops=10    # max 10 Schleifen
export koldel_batch_delete_drg=1      # 1=ja, 0=nein
export koldel_batch_delete_vm=1       # 1=ja, 0=nein

# create database tables and views
sqlite3 $koldel_del_db << EOF
 create table if not exists T_DRG_IMP (C1 text, C2 text);
 create table if not exists T_VM_IMP (C1 text);
 create table if not exists T_DRG (C1 text, C2 text, MODE text);
 create table if not exists T_VM (C1 text, MODE text);
 create table if not exists T_DRG_EXP (C1 text, C2 text);
 create table if not exists T_VM_EXP (C1 text);
 create view if not exists V_DRG_NEW as
  select C1,C2,'new' as MODE from T_DRG_IMP
  except
  select C1,C2,'new' as MODE from T_DRG;
 create view if not exists V_VM_NEW as
  select C1,'new' as MODE from T_VM_IMP
  except
  select C1,'new' as MODE from T_VM;
EOF

# import delete id's
sqlite3 $koldel_del_db << EOF
 delete from T_DRG_IMP;
 delete from T_VM_IMP;
.mode csv
.separator ";"
.import $koldel_drg_csv T_DRG_IMP
.import $koldel_vm_csv T_VM_IMP
 insert into T_DRG select C1,C2,MODE from V_DRG_NEW;
 insert into T_VM select C1,MODE from V_VM_NEW;
 select 'T_DRG', MODE, count(*) from T_DRG group by MODE;
 select 'T_VM', MODE, count(*) from T_VM group by MODE;
EOF

# loop delete id's
export koldel_loop_timestart=$(date +%s)
export koldel_loop_timeout=$(expr $koldel_loop_timestart + $koldel_batch_limit_seconds)
export koldel_loop_count=0
export koldel_loop_batch=$(expr $koldel_batch_delete_drg + $koldel_batch_delete_vm)

while [[ $(date +%s) -lt $koldel_loop_timeout ]]; do
  # loop limit
  export koldel_loop_count=$(expr $koldel_loop_count + 1)
  export koldel_loop_time=$(expr $(date +%s) - $koldel_loop_timestart)
  echo "koldel_loop_count $koldel_loop_count"
  echo "koldel_loop_time $koldel_loop_time"
  if [[ $koldel_loop_count -ge $koldel_batch_limit_loops ]]; then
    break
  fi
  if [[ $(date +%s) -ge $koldel_loop_timeout ]]; then
    break
  fi
  if [[ $koldel_loop_batch -eq 0 ]]; then
    echo "info: no delete batch enabled (see koldel_batch_delete_***)"
    break
  fi
  # count new data
  export koldel_sql_cntdrgnew=$(sqlite3 $koldel_del_db "select count(*) from T_DRG where MODE='new'")
  export koldel_sql_cntvmnew=$(sqlite3 $koldel_del_db "select count(*) from T_VM where MODE='new'")
  export koldel_sql_cntnew=$(expr $koldel_sql_cntdrgnew + $koldel_sql_cntvmnew)
  if [[ $koldel_sql_cntnew -eq 0 ]]; then
    echo "break: no more data"
    break
  fi
  # get next chunk
  sqlite3 $koldel_del_db << EOF
   delete from T_DRG_EXP;
   delete from T_VM_EXP;
   insert into T_DRG_EXP select C1,C2 from T_DRG where MODE='new' limit $koldel_batch_chunk_size;
   insert into T_VM_EXP select C1 from T_VM where MODE='new' limit $koldel_batch_chunk_size;
.mode csv
.separator ";"
.headers off
.output $koldel_batch_chunk_drg_csv
select C1,C2 from T_DRG_EXP;
.output $koldel_batch_chunk_vm_csv
select C1 from T_VM_EXP;
.output stdout
EOF
  # execute batch
  if [[ $koldel_batch_delete_drg -eq 1 ]]; then
    echo "chunk drg"
    cat $koldel_batch_chunk_drg_csv
    # ... tbd ...
    export koldel_batch_rc_drg=$?
    sqlite3 $koldel_del_db << EOF
     update T_DRG set MODE = case when $koldel_batch_rc_drg = 0 then 'del' else 'error' end
      where exists (select null from T_DRG_EXP where T_DRG.C1=T_DRG_EXP.C1 and T_DRG.C2=T_DRG_EXP.C2);
EOF
    if [[ $koldel_batch_rc_drg -ne 0 ]]; then
      echo "error: drg"
      break
    fi
    echo "returncode $koldel_batch_rc_drg"
  fi
  if [[ $koldel_batch_delete_vm -eq 1 ]]; then
    echo "chunk vm"
    cat $koldel_batch_chunk_vm_csv
    # ... tbd ...
    export koldel_batch_rc_vm=$?
    sqlite3 $koldel_del_db << EOF
     update T_VM set MODE = case when $koldel_batch_rc_drg = 0 then 'del' else 'error' end
      where exists (select null from T_VM_EXP where T_VM.C1=T_VM_EXP.C1);
EOF
    if [[ $koldel_batch_rc_vm -ne 0 ]]; then
      echo "error: vm"
      break
    fi
    echo "koldel_batch_rc_vm $koldel_batch_rc_vm"
  fi
  sleep 1
done

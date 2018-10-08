docker run -t -d \
        -e="occs:availability=per-pool" \
        -e="occs:scheduler=random" \
        -e="occs:description=OFSAA FCCM DB Server" \
        --name FCCMDB \
        -p 1521:1521 -p 5500:5500 \
        -e ORACLE_SID=ORCLCDB \
        -e ORACLE_PDB=ORCLPDB1 \
        -e ORACLE_PWD=Oradoc_db1 \
        -e ORACLE_CHARACTERSET=AL32UTF8 \
        -v /u01/data/DB:/opt/oracle/oradata \
        oracle/database:12.2.0.1-ee

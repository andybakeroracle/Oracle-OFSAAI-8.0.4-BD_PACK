docker run -t -d \
  -e="RCUPREFIX=FCCMFMW" \
  -e="DB_PASSWORD=Oradoc_db1" \
  -e="DB_USERNAME=sys" \
  -e="DB_SCHEMA_PASSWORD=YgauGh0a" \
  -e="ADMIN_USERNAME=weblogic" \
  -e="CONNECTION_STRING=FCCMDB:1521/ORCLPDB1" \
  -e="ADMIN_PASSWORD=FdyY3XJA" \
  -e="DOMAIN_NAME=FCCM_Domain" \
  -e="occs:availability=per-pool" \
  -e="occs:scheduler=random" \
  -e="occs:description=FMW INFRA ADMIN DOMAIN FCCM" \
  -v=/u01/data/FMW:/u01/oracle/user_projects:rw \
  -p=9001:7001/tcp \
  --link=FCCMDB:FCCMDB \
  --name=FCCMFMWAS \
  --hostname=FCCMFMWAS \
  "oracle/fmw-infrastructure:12.2.1.3"

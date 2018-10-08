docker run -t -d \
  -e="ADMIN_USERNAME=weblogic" \
  -e="ADMIN_PASSWORD=FdyY3XJA" \
  -e="DB_HOST=FCCMDB" \
  -e="DB_PORT=1521" \
  -e="DB_SERVICE=ORCLPDB1" \
  -e="DB_USERNAME=sys" \
  -e="DB_PASSWORD=Oradoc_db1" \
  -e="SCHEMA_PREFIX=FCCMBI1" \
  -e="SCHEMA_PASSWORD=YgauGh0a" \
  -e="occs:availability=per-pool" \
  -e="occs:scheduler=random" \
  -e="occs:description=Oracle BI Server 12.2.1.3" \
  -v=/u01/data/BI:/u01/oracle/user_projects:rw \
  -p=9500:9500/tcp \
  -p=9502:9502/tcp \
  --link=FCCMDB:FCCMDB \
  --name=FCCMBI \
  --hostname=FCCMBI \
  "oracle/biplatform:12.2.1.3"

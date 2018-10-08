docker run -t -d \
  -e="occs:availability=per-pool" \
  -e="occs:scheduler=random" \
  -e="occs:description=OFSAA OFSAAI (FCCM) Application Server" \
  --name=FCCMAPPS \
  --hostname=FCCMAPPS \
  --link FCCMDB:FCCMDB \
  --link FCCMFMWAS:FCCMFMWAS \
  -v=/u01/data/FCCM/DOWNLOAD:/u01/oracle/OFSAA/DOWNLOAD:rw \
  -v=/u01/data/FCCM/FIC_HOME:/u01/oracle/OFSAA/FIC_HOME:rw \
  -v=/u01/data/FCCM/FTPSHARE:/u01/oracle/OFSAA/FTPSHARE:rw \
  "oracle/ofsaa-fccm:8.0.4"

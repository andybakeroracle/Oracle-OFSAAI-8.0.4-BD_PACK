docker run -t -d \
  -e="ADMINHOSTNAME=FCCMFMWAS" \
  -e="ADMINPORT=7001" \
  -e="MANAGED_SERVER=TRUE" \
  -e="DOMAIN_NAME=FCCM_Domain" \
  -e="occs:availability=per-pool" \
  -e="occs:scheduler=random" \
  -e="occs:description=FCCM Domain Managed Service" \
  -p=9801:8001/tcp \
  --volumes-from=FCCMFMWAS \
  --name=FCCMFMWMS \
  --hostname=FCCMFMWMS \
  --link=FCCMFMWAS:FCCMFMWAS \
  --link=FCCMDB:FCCMDB \
  "oracle/fmw-infrastructure:12.2.1.3" \
  startManagedServer.sh

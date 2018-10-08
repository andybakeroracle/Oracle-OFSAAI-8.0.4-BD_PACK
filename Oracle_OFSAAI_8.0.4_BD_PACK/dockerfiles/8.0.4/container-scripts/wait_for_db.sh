#!/bin/bash
###
# NOTE Compiled to run with ojdbc6.jar.  This produced the 12.1 Java class being run.
#      For other versions you need to remove the .class and recompile as below.
#      javac -cp /usr/lib/oracle/12.2/client64/lib/ojdbc8.jar /u01/oracle/fccm/DbConn.java
#     NOTE:  The locatoin on the ojbcX.jar.  This will then make a DBConn.class as appropriate.
#     This script will need the correct jdbc classpath also!
#  To Test outside of the script run: java -cp .:/usr/lib/oracle/12.2/client64/lib/ojdbc8.jar 
#                                               -Djava.security.egd=file:/dev/./urandom DbConn 
#                                                  jdbc:oracle:thin:@FCCMDB:1521/ORCLPDB1 
#                                                  system Oradoc_db1 oracle.jdbc.driver.OracleDriver
#      All on 1 line.
# This returns sysdate.  ALL G.
###

if [ $# -ne 4 ]; then
  echo ''
  echo 'Usage: wait_for_db.sh DbConn parameters'
  echo 'Where Parameters are: '
  echo '            1. jdbc:oracle:thin:@FCCMDB:1521/ORCLPDB1 '
  echo '            2. system '
  echo '            3. Oradoc_db1 '
  echo '            4. oracle.jdbc.driver.OracleDriver '
  echo ''
  exit 1
fi

DB_URL=$1
DB_USER=$2
DB_PASSWORD=$3
DB_DRIVER=$4

WEBLOGIC_CLASSPATH=.:/u01/oracle/client/12.1.0.1/jdbc/lib/ojdbc6.jar

echo "Waiting for DB"
until java -cp $WEBLOGIC_CLASSPATH -Djava.security.egd=file:/dev/./urandom DbConn $DB_URL $DB_USER $DB_PASSWORD $DB_DRIVER 2>&1 >/dev/null
do
  echo "Waiting for DB"
  sleep 10
done
echo "DB is available"

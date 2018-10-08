#!/bin/ksh
############################################
## Script:  Fixes things not picked up by OSC.sh
##          but shown by envCheck.sh called in setup.sh
##
## Maintained: Andy B   06/09/18
############################################

##
# Note Environment variables used for DB user, password and DB.
# These are taken from the FMW AS docker environment variables declared at run time and available in Environment.
# So will always match and avoids hardcoding. As these are all networked they need to be running, DB, AS, MS before App server.
##

DBAUSER=$FCCMFMWAS_ENV_DB_USERNAME
DBAPASSWORD=$FCCMFMWAS_ENV_DB_PASSWORD
DATABASENAME=$FCCMFMWAS_ENV_CONNECTION_STRING
DBAOPTIONS=' AS SYSDBA'

LOGFILE='/u01/oracle/OFSAA/install/FIX_INSTALL.log'

        sqlplus -s /nolog <<-EOF> ${LOGFILE}
        WHENEVER OSERROR EXIT 9;
        WHENEVER SQLERROR EXIT SQL.SQLCODE;
        connect $DBAUSER/$DBAPASSWORD@$DATABASENAME $DBAOPTIONS
        grant select on USER_TS_QUOTAS to OFSAACONF;
        grant select on NLS_INSTANCE_PARAMETERS to OFSAACONF;
        alter system set open_cursors=1000 scope=both;
        exit;
        EOF

#!/usr/bin/bash
############################################################
## Purpose:   Datasource Creation based on Python Script
##            And Properties file.
##            Create a JNDI Data Source in WLS.
##
## Note:      Complete the properties file.
## Created:   Andy Baker.
## 
###########################################################

# Set environment.
export JAVA_HOME=/usr/java/default
export PATH=$JAVA_HOME/bin:$PATH
export MW_HOME=/u01/oracle
export WLS_HOME=$MW_HOME/wlserver/server
export WL_HOME=$WLS_HOME
export DOMAIN_HOME=/u01/oracle/user_projects/domains/FCCM_Domain

##
# Note set the WLST Environment.  Not the Domain Environment.
##
. $MW_HOME/oracle_common/common/bin/setWlstEnv.sh

##
# Create the data source & Activate it.
##
java weblogic.WLST /u01/oracle/container-scripts/create_data_source.py -p /u01/oracle/container-scripts/myDomain-ds.properties

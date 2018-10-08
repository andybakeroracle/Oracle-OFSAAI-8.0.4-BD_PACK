#!/usr/bin/bash
############################################################
## Purpose:   Deploy the OFSAAI Application in WLST 
##
##
## Note:      Ensure the Ear / War are unpacked in the right location on Admin Server.
##            Data Source JNDI must also be pre-created before deployment.
##            For OFSAA the APP server must be built and Software Running before APP server Deployment to WEB Servers.
##
## Created:   Andy Baker.
##
###########################################################

##
# Set OS environment.
##
export JAVA_HOME=/usr/java/default
export PATH=$JAVA_HOME/bin:$PATH
export MW_HOME=/u01/oracle
export WLS_HOME=$MW_HOME/wlserver/server
export WL_HOME=$WLS_HOME
export DOMAIN_HOME=/u01/oracle/user_projects/domains/FCCM_Domain

##
# Note set the WLST Environment.  Not the Domain Environment.
##
. /u01/oracle/wlserver/server/bin/setWLSEnv.sh

##
# Deploy the Application
##
export HOST=FCCMFMWAS
export PORT=7001
export AdminUser=weblogic
export AdminPassword=FdyY3XJA
export AppName=OFSAAI
export SourcePath=/u01/oracle/user_projects/domains/FCCM_Domain/applications
export Artifact=OFSAAI.ear

echo ""
echo ""
echo "About to Deploy The OFSAAI Application to :"
echo ""
echo "********************************"
echo "Host         : ${HOST}"
echo "Port         : ${PORT}"
echo "AdminUser    : ${AdminUser}"
echo "AdminPassword: ${AdminPassword}"
echo "AppName      : ${AppName}"
echo "SourcePath   : ${SourcePath}"
echo "********************************"
echo ""
echo ""
java weblogic.Deployer -verbose -adminurl t3://${HOST}:${PORT} -username ${AdminUser} -password ${AdminPassword} -nostage -name ${AppName} -targets AdminServer -deploy ${SourcePath}/${Artifact}

echo "********************************"
echo "** App Deployment Completed.  **"
echo "        Check For Errors!!!!"
echo "********************************"

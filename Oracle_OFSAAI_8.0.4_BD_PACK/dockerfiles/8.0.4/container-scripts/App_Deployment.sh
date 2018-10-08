#!/bin/bash
#
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Script will take the EAR file built in the install.
# It will copy over / EAR file into the deployment path to the web server.
# It will unpack the webiste ear.
# It will then run the application deployment.
# CREATED / MAINTAINED :   Andy Baker (Andy.t.baker@oracle.com)
##########
	
echo "=========================================="
echo "== Application Deployment Task Starting =="
echo "=========================================="
echo ""
echo ""

##
# 1. create the EAR directory.
##
echo "Creating the EAR directory on the Web App Server........"
echo ""
echo ""

if [ -f /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear.o ]
then 
   mkdir -p /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear
   cd /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear
else
   echo "Could Not Make EAR directory Check Deployment on Admin Server / location of OFSAAI.ear.o"
   exit 1
fi

##
# 2. mv the OFSAAI.ear file to the EAR directory.
##

echo "Moving the Copied OFSAAI.ear.o file into the Directory........."
echo "Main App Script Copied EAR over from Apps server to TMP File"
echo ""
echo ""
if [ -d /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear ]
then
   mv /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear.o /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.ear 
else
   echo "Could not move OFSAAI.ear.o into OFSAAI.ear directory....."
   exit 1
fi

##
# 3. Unpack the EAR file.
##

echo "Unpack the EAR deployment file..........."
echo ""
echo ""

if [ -f /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.ear ]
then 
   jar -xvf /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.ear 
else
   echo "Could not unpack the OFSAAI File....."
   exit 1
fi

##
# 4. Rename the WAR file.   OFSAAI.war.
#

echo "Rename the Deployed WAR file............"
echo ""
echo ""

if [ -f /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war ]
then 
mv /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war.o
else
   echo "Could Not Rename OFSAAI.war file to tmp file....."
   exit 1
fi

##
# 5. Make the directory for War File.
##

echo "Make the WAR Directory to Unpack WAR File into........"
echo ""
echo ""
if [ -f /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war.o ]
then
   mkdir -p /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war
   cd /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war
else
   echo "No OFSAAI.war.o could not make the dir OFSAAI.war"
   exit 1
fi 

##
# 6. Now move and unpack the WAR file.
##
echo "........Moving the WAR file...................."
echo ""
echo ""

if [ -d /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war ]
then
mv /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war.o /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war/OFSAAI.war
else
  echo "NO WAR FILE .o to move, ERROR"
fi

echo ".............Unpack The WAR file...................."
echo ""
echo ""
if [ -f /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war/OFSAAI.war ]
then
   jar -xvf /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war/OFSAAI.war
else 
   echo "No OFSAAI.war, did not unpack."
   exit 1
fi

##
# 7. Fix the web.xml in WEB-INF due to 12.2.1.3 deployment problem.
##
echo "Apply WEB.XML fix for WEBLOGIC 12.2.1.3 Mapping Issue........"
echo ""
echo ""
if [ -f /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war/WEB-INF/web.xml ]
then
  cd /u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear/OFSAAI.war/WEB-INF 
  sed -i "s?/UserProvisioning?/userProvisioning?g" web.xml
else 
  echo "Could not find the WEB-INF dir / web.xml file."
  exit 1
fi
##
# 8. Finally Run the Weblogic WLST script to Deploy into Weblogic.
##
echo "##########################################################"
echo "##  Running The Weblogic Deployment Now...........      ##"
echo "##  Properties and Script in Container-Scripts on FMW   ##"
echo "##  container-scripts/OFSAAI_deployapp.sh               ##"
echo "##########################################################"
echo ""
echo ""
if [ -f /u01/oracle/container-scripts/OFSAAI_deployapp.sh ]
then 
   cd /u01/oracle/container-scripts/
   /u01/oracle/container-scripts/OFSAAI_deployapp.sh
else
  echo "no OFSAAI_deployapp.sh to execute....in container scripts on FMW Server."
  echo "Please check Admin Server /u01/oracle/container-scripts"
  exit 1
fi
echo ""
echo ""
echo "###################################################################"
echo "## Weblogic Deployment Completed                                 ##"
echo "## Please Check The Console for Errors And App If you can Login  ##"
echo "###################################################################"
echo ""
echo ""

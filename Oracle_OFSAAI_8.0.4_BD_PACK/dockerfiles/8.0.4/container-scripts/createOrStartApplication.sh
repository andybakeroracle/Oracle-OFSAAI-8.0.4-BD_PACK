#!/bin/bash
#
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# If key logs do not, container is starting for 1st time
# So it should start the App Server and then check DB run Schema Creator and then application set up.
# Otherwise, only start application (container restarted)
#
# CREATED / MAINTAINED:   Andy Baker (Andy.t.baker@oracle.com)
# October 2018
######

# Source the Oracle home .profile for Environment.
. ~/.profile

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   
   # Source the Oracle home .profile for Environment.
   . ~/.profile

   echo "SIGTERM received, shutting down the server!"
   echo "Stopping The Infrastructure Services........"
   cd ${FIC_HOME}/ficapp/common/FICServer/bin
   ${FIC_HOME}/ficapp/common/FICServer/bin/stopofsaai.sh
   echo ""
   echo "Stopping The ICC Service..........."
   cd ${FIC_HOME}/ficapp/icc/bin
   ${FIC_HOME}/ficapp/icc/bin/iccservershutdown.sh
   echo ""
   echo "Stopping the Backend Agent Service........"
   cd ${FIC_HOME}/ficdb/bin
   ${FIC_HOME}/ficdb/bin/agentshutdown.sh 
   echo "Services Stopped"
   echo ""
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL
	
echo "========================================"
echo "== Starting SSHD Demon server port 22 =="
sudo /usr/sbin/sshd -D &
echo "========================================"
echo ""
echo ""
echo "========================================"
echo "==Dealing with Random / Urandom =="
sudo /bin/rm /dev/random 
sudo /bin/ln -s /dev/urandom /dev/random
echo "========================================"
echo ""
echo ""
echo "============================================="
echo "== Configuring Application for first time "
echo "== If the application has already been Configured"
echo "== Start the Application Only  "
echo "============================================="
echo ""
echo ""

# Check for BD_PACK in Download Directory.  If not there first start.
# unzip and copy files into the correct place.
# then run the schema creator.
# run post fixes.
# run installer.
# start up verification.
# Copy over and Deploy on the Web App Server.

# If there is a DOWNLOADED BD_PACK Unzipped in Download.
# then this has been done and it is fair to assume it is just a container start. So start application only.
 
ADD_PACK=1

if [ ! -d /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK ]; 
then
    ADD_PACK=0
fi

##
# Unzip the binary and run the install if flagged As not installed already.
##
if [ $ADD_PACK -eq 0 ]; 
then
       echo ""
       echo "***********************************************************"
       echo "** Ensure Permissions on Mounted Volumes are Correct 775 **"
       echo "***********************************************************"
       echo ""

       chmod 775 /u01/oracle/OFSAA/DOWNLOAD
       chmod 775 /u01/oracle/OFSAA/FTPSHARE
       chmod 775 /u01/oracle/OFSAA/FIC_HOME

       echo "Permissions on Mounts Complete."
       
       echo ""
       echo "****************************************************"
       echo "** Run the unzip of binaries.                     **"
       echo "****************************************************"
       echo " Dont remove orginal file due to earlier layer     "
       echo ""

       unzip /u01/oracle/container-scripts/$PKG -d /u01/oracle/OFSAA/DOWNLOAD
       chmod -R +xr /u01/oracle/OFSAA/DOWNLOAD 

       echo ""
       echo "****************************************************"
       echo "** Copy required files around.                    **"
       echo "****************************************************"
       echo "Moving Files by Copy due to Image Layering, They are from an earlier Layer......."       
       echo "On a layer2 storage it will make files go corrupt."
       echo ""
 
       #Schema IN file used by Schema Creator. Passwords, JDBC URL, Schema details.
       cp /u01/oracle/container-scripts/OFS_BD_SCHEMA_IN.xml /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/schema_creator/conf

       # preinstallcheck.sh is a altered version to use expect around the java call and automate interaction.
       cp /u01/oracle/container-scripts/preinstallcheck.sh /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_AAI/bin

       # envCheck.sh is an altered version to deal with sql missing user context.
       cp /u01/oracle/container-scripts/envCheck.sh /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_AAI/bin

       #Expect script for OSC.sh (Schema Creator).
       cp /u01/oracle/container-scripts/OSC.exp /u01/oracle/OFSAA/install

       #Expect Script for App install setup.
       cp /u01/oracle/container-scripts/SETUP.exp /u01/oracle/OFSAA/install

       #SSH Set up script for SFTP and SSH to work between Apps and DB / Web Apps.
       cp /u01/oracle/container-scripts/SSH.exp /u01/oracle/OFSAA/install

       # Fix it SQL script for DB items required. Not picked up by OSC! 
       cp /u01/oracle/container-scripts/FIX_INSTALL.sh /u01/oracle/OFSAA/install

       # License Pack install XML used by SetUp.sh Which Packs...
       cp /u01/oracle/container-scripts/OFS_BD_PACK.xml /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/conf

       # Setup Instal xml used by setup scripts for App.
       # Db server, Web Server, SFTP, HTTP(S), Ports etc. Dirs etc.
       cp /u01/oracle/container-scripts/OFSAAI_InstallConfig.xml /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_AAI/conf

       # Install config for app used by setup scripts.
       # Base Country, Dates Formets, OBIEE Configure / Url.
       cp /u01/oracle/container-scripts/InstallConfig.xml /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_BD/conf
    
       echo "Moving Files Completed......."
       echo ""
       echo "Now Copying log4j.xml due to error in 8.0.4 and missing from OFS_BD/conf directory."
       echo "Copied from /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_AAI/conf/log4j.xml"
       echo ""
       cp /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_AAI/conf/log4j.xml /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/OFS_BD/conf
       echo ""
       echo "log4j.xml copied"

       echo ""
       echo "***********************************************************"
       echo "** Setup SSH script for SFTP, SSH                        **"
       echo "** Connect to FCCMFMWAS, FCCMDB, FCCMAPPS                **"
       echo "** Also puts /etc/hosts entry into web app server        **"
       echo "***********************************************************"
       echo ""
       cd /u01/oracle/OFSAA/install
       SSH.exp
       retval=$?

       if [ $retval -ne 0 ];
       then
          echo  "SSH/SFTP has some error see container"
          exit
       else
          echo  "SSH/SFTP has Succeeded!"
       fi

       echo ""
       echo ""
       echo "****************************************************"
       echo "** Execute the Automated Expect version           **"
       echo "** Of the OFSAA Schema Creator.                   **"
       echo "** Note this may fail if DB already present.      **"
       echo "** Logs are available in schema_creator/logs      **"
       echo "****************************************************"
       echo ""

       cd /u01/oracle/OFSAA/install 
       expect OSC.exp
       retval=$?
        
       if [ $retval -ne 0 ]; 
       then
          echo  "OSC has some error, see logs on the container"
          exit
       else 
          echo  "OSC Oracle Schema Creator has Succeeded!"
       fi

       echo ""
       echo "****************************************************"
       echo "** Execute Database Post Fix Due to OSC.sh diffs  **"
       echo "** And the EnvCheck.sh run from app installer.    **"
       echo "****************************************************"
       echo ""

       cd /u01/oracle/OFSAA/install 
       FIX_INSTALL.sh 
       retval=$?

       if [ $retval -ne 0 ];
       then
          echo  "FIX Install has some error see logs on the container"
          exit
       else
          echo  "FIX Install has Succeeded!"
       fi
       
       echo ""
       echo ""
       echo "****************************************************"
       echo "**      Installng The Ofsaa Appliction            **"
       echo "****************************************************"
       
       ##
       # 1. Change Setup.sh to deal with Interaction License Agreement.
       ##        
       ANS='ans="Y"'

       echo ""
       echo "***********************************************************************************************************"
       echo "** Pre-install Changing The read ans line in Setup.sh /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/bin to: $ANS"
       echo "**"
       echo "***********************************************************************************************************"
       echo ""
       echo ""

       sed -i "s/read ans/$ANS/g" /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/bin/setup.sh

       echo "***********************************************************************************************************"
       echo "** License Response Now set to YES. Automate in setup.sh"
       echo "***********************************************************************************************************"
       echo ""
       echo "" 

       ##
       # 2. Run the Installer. This has been altered for Automation to work. it runs envcheck,preinstallchecks
       #    from the BP Pack and then from the AAI pack. Interaction is held in a jar file.
       #    so alteered the call around that to use expect.
       ##

       echo ""
       echo "***********************************************************************************************************"
       echo "**    Runnng the setup.sh but it will call the altered OFS_AAI/bin/preinstallcheck.sh"
       echo "**    This deals with the interaction on SFTP password with an Expect version."
       echo "***********************************************************************************************************"
       echo "**"
       echo "**     NOTE: It takes care of the ksh ensuring executed in the shell. Or it will Error!.                   "
       echo "***********************************************************************************************************"
       echo ""
       echo ""

       cd /u01/oracle/OFSAA/DOWNLOAD/OFS_BD_PACK/bin 
       /usr/bin/ksh setup.sh SILENT 
       retval=$?

       if [ $retval -ne 0 ];
       then
          echo  "********   OFSAA BD PACK has some error see logs in the container   *********"
          exit
       else
          echo  "********   OFSAA BD PACK has Completed!     **********"
       fi
       if [ -f ${FIC_HOME}/ficweb/OFSAAI.ear ]
       then
         echo ""
         echo ""
         echo "*****************************************************************************************************"
         echo "****************** DEPLOYMENT TO WEB APP SERVER *****************************************************" 
         echo "**    Now execute the Application Deployment to the WEB APP Server.                                **"
         echo "**    This will remotely copy the EAR produced in the application over to the WEB APP Sever.       **"
         echo "**    It will unpack the EAR file / WAR file into the DOMAIN_HOME/applications dir.               **"
         echo "**    It will then startup the application on the APPS Server To ensure RUNNING.                   **"
         echo "**    It will then remotely RUN the Deployment to the ADMIN Server. Using Script create_dp.sh      **"
         echo "**    Script for Deployment is copied in FMW container-scripts BUILD and also Properties file.     **"
         echo "*****************************************************************************************************"
         echo ""
         echo ""

         echo ""
         echo ""
         echo "****************************************************"
         echo "** 1.USE SSH TO REMOTELY EXECUTE:                 **"
         echo "**  create_OFSAAI_ds.sh on FMW Admin Server       **"
         echo "**  purpose is to create the Required JNDI        **"
         echo "**  Data Source for the FICMASTER Entry.          **"
         echo "** This is a WLST script using local properties   **"
         echo "** file for config.  Script placed in FMW build   **"
         echo "**       This is for Admin Server only!!!!        **"
         echo "****************************************************"
         echo ""

         ssh -t FCCMFMWAS /u01/oracle/container-scripts/create_OFSAAI_ds.sh
         retval=$?

         if [ $retval -ne 0 ];
         then
            echo  "JNDI FICMASTER Creation Had Some Error, Please see logs on the container"
            exit 1
         else
            echo  "JNDI FICMASTER Creation wth WLST has Succeeded!"
         fi

         ## 
         # Remotely copy over the EAR file.  This is to a temp file to unpack.
         ##

         scp ${FIC_HOME}/ficweb/OFSAAI.ear FCCMFMWAS:/u01/oracle/user_projects/domains/FCCM_Domain/applications/OFSAAI.ear.o

         ##
         #  ENSURE LOCAL SERVICES ARE RUNNING BEFORE DEPLOYMENT!!!!!!!
         #  Calling Application Startup Scripts on APP Server. FCCMAPPS
         ##
         # Source the Oracle home .profile for Environment.
         . ~/.profile
         
         echo "****************************************************"
         echo "** 2.Executing A Normal Application Startup.      **"
         echo "**  Needs to be Up / OK on Apps Server before     **"
         echo "**  Web App Server Deployment.                    **"
         echo "****************************************************"
         echo ""
         echo ""
         echo "Starting The Infrastructure Services........"
         cd $FIC_HOME/ficapp/common/FICServer/bin
         nohup $FIC_HOME/ficapp/common/FICServer/bin/startofsaai.sh &

         echo ""
         echo "Starting The ICC Service..........."
         cd $FIC_HOME/ficapp/icc/bin
         $FIC_HOME/ficapp/icc/bin/iccserver.sh 

         echo ""
         echo "Starting the Backend Agent Service........"
         cd $FIC_HOME/ficdb/bin
         nohup $FIC_HOME/ficdb/bin/agentstartup.sh &

         echo ""
         echo ""

         ##
         # Use SSH and send App Deployment unpack commands through ssh to remote server.
         # This unpacks the EAR / WAR and then calls the local Deployment script sent in FMW build.
         ##

         ssh -t FCCMFMWAS < /u01/oracle/container-scripts/App_Deployment.sh 
         retval=$?

         if [ $retval -ne 0 ];
         then
            echo  "********   WEB APP SERVER DEPLOYMENT HAS ERRORS PLEASE CHECK FCCMFMWAS and Logs in Containtainer on APP server. *********"
            exit
         else
            echo  "********   Deployment Of The Application Has Completed!                    **********"
            echo  "********   Check Status in the WebLogic Admin Server Console: Deployments   *********"
            echo  "********   App should be OK to login / use                                  *********"
         fi
      else
         echo "APP INSTALL ERRORS.... PLEASE SEE LOGS AND FIX!"
         exit 1
      fi 

##
# Else Application Is Already Deployed, DOWNLOAD has been Unpacked And Present.
# so Just Start The Application Services from the Persistent Volume  and tail the logs
##
else
   echo ""
   echo ""
   echo "****************************************************"
   echo "** Executing A Normal Application Startup.        **"
   echo "****************************************************"
   echo ""
   echo ""
   # Source the Oracle home .profile for Environment.
   . ~/.profile

   echo "Starting The Infrastructure Services........"
   cd $FIC_HOME/ficapp/common/FICServer/bin
   nohup $FIC_HOME/ficapp/common/FICServer/bin/startofsaai.sh &

   echo ""
   echo "Starting The ICC Service..........."
   cd $FIC_HOME/ficapp/icc/bin
   $FIC_HOME/ficapp/icc/bin/iccserver.sh 

   echo ""
   echo "Starting the Backend Agent Service........"
   cd $FIC_HOME/ficdb/bin
   nohup $FIC_HOME/ficdb/bin/agentstartup.sh &

   echo ""
   echo ""
fi

touch /u01/oracle/OFSAA/install/App.log

echo ""                                                     >> /u01/oracle/OFSAA/install/App.log
echo "****************************************************" >> /u01/oracle/OFSAA/install/App.log
echo "** Ofsaa BD PACK Application Complete             **" >> /u01/oracle/OFSAA/install/App.log
echo "****************************************************" >> /u01/oracle/OFSAA/install/App.log
echo "" >> /u01/oracle/OFSAA/install/App.log

tail -f /u01/oracle/OFSAA/install/App.log &
childPID=$!
wait $childPID

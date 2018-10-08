###
#Oracle-OFSAAI-8.0.4-BD_PACK
###
This repository has ALL the files and code to build Oracle BI, Oracle FMW, Oracle HTTP, Oracle DB and then the OFSAAI 8.0.4 with BD_PACK. Please download binaries and place into the dockerfiles directory. Each REAME.md shows how to build. All that is required is a Oracle DB EE with partitioning, An FMW Admin server and then the OFSAAI Application server.

###
#Oracle FCCM 8.0.4 BD_PACK on Docker
###
Written : Andy Baker. Andy.t.baker@oracle.com Version : V1 Date : October 2018

This Docker configuration has been used to create the Oracle OFSAA BD_PACK image. It uses the OFSAA BD_PACK for version 8.0.4.

Providing this image facilitates the configuration, and environment setup for DevOps users. This project includes the creation and configuration of an OFSAAI application server.

The certification of Oracle OFSAA on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

###
#How to build and run
###
This project offers a sample Dockerfile and scripts to build a Oracle OFSAAI 8.0.4 Image. To assist in building the image, you can use the buildDockerImage.sh script. See below for instructions and usage.

The buildDockerImage.sh script is just a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call docker build with their prefered set of parameters.

###
#Building Oracle JDK (Server JRE) base image
###
The first image in the stack is the Linux 7 Slim image. This needs to be downloaded and stored in the repo.

You then download the Oracle Server JRE binary and drop in folder ../OracleJava/java-8 and then build that image. For more information, visit the OracleJava folder's README file.

    $ cd ../OracleJava/java-8
    $ sh build.sh

Building Oracle Database Enterprise Edition
You need to ensure you have the full oracle database image 12.2.0.1 The scripts and readme for this are in the folder ../OracleDatabase. Before building that image you need to download the binaries required. Please visit the [README](../Oracle.

Build and run scripts have been added. For OFSAAI specifically additional sqlnet.ora entries have been added as well as ssh / sudo installs on the base image.

Due to overlayfs storage and limits in file size the binaries over 1.6Gb need to be split into files. There are different ways to do this but one way is to take the large archive, unzip it. Then zip it up with the -s option or else use the split command.

###
#Building the FMW Infrastructure 12.2.1.3
###
you need to download the correct binaries and place into the dockerfiles directory for this version. The scripts and readme for this are all in the folder ../FMWINFRSTRUCTURE. The install of this image will also set up sshd as well as some scripts into container scripts for WLST JNDI creation as well as application deployment. It is critical the database image, JDK and linux images are avaiable first. Image creation does a base install, however it is only running the containers for the admin server that will create the domains and the admin server. The RCU will also be executed during the container run.

The managed server start is also included and can be used. However for this POC of OFSAAI it is not required. The application is deployed only to the admin server.

###
#Building the Oracle FCCM 8.0.4 base image
###
**IMPORTANT:**If you are building the Oracle FCCM image you must first download the Oracle FCCM binary and drop in folder ../OracleFCCM/dockerfiles/8.0.4. You also need the FULL oracle Client download also to be placed similar.

    $ sh buildDockerImage.sh
    Usage: buildDockerImage.sh -v [version]
    Builds a Docker Image for Oracle FMW Infrastructure.

    Parameters:
       -v: version to build. Required.
       Choose : 8.0.4 
       -c: enables Docker image layer cache during build
       -s: skips the MD5 check of packages

    LICENSE UPL 1.0

Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

###
#Running the Oracle FCCM Infrastructure Domain Docker Image
###
To run a FCCM BD_PACK 8.0.4 container, you will need the Oracle Database enterprise edition with partitioning option and an FMW admin server running.. The Oracle Database could be remote or running in a container. If you want to run Oracle Database in a container, you must use the build supplied in this project as it has had some extentions and changes to ensure works. There are many images of database available however it is essential to have partitioning options.

Follow the steps below:
###
#Docker Networking
###
Please Note; On Older docker versions use the --link deprecated option instead of a network. All the RUN commands already have this included.

However newer versions than Docker 1.12 can use:

Create the docker network for the infra server to run

$ docker network create -d bridge DB-APP

If the containers are running and the --network is not used then the containers will be on the default bridge network. This allows containers to talk to containers on ip-address. To allow DNS name or the --name XXX to be used a bridged network is required as per step 1. This can be implemented dynamically and with containers online. You can also connect to the network.

   $docker network connect DB-APP EDQDB
   $docker network connect DB-APP FCCM

to inspect a network for content you can run: $docker network inspect DB-APP

To remove the network or an item, use the disconnect command before removal of the bridged network.

###
#Ensure The DB is running.
###
Run the Database container to host the RCU schemas/ FCCM Schemas The Oracle database server container requires custom configuration parameters for starting up the container.This custom configuration parameters co rrespond to the Data Source parameters in the FMW Infrastructure image to connect to the database running in the container. Add to an env 'env.txt' file the following parameters:

    DB_SID=InfraDB
    DB_PDB=InfraPDB1
    DB_DOMAIN=us.oracle.com
    DB_BUNDLE=basic

    $ docker run -d --name InfraDB --network=DB-APP -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com
/database/enterprise:12.2.0.1

The database is persistent in a volume. This keeps the database through each cycle of the container.

*** See the Run Script included as an example. ***

Run the FMW Infrastructure to get a functional domain and admin server.
The build of this image is different than the oracle standard project. It has sudo , ssh other packages included. Further it has scripts put into the container scripts directory which give the ability for WLST and JDNI creation / as well as EAR deployment.

For OFSAAI you can use a proxy server OHS also on top of this if desrired. However to simplify the deployment and startup just the admin server is used. Included in the project are commands to add manage servers to the domain.

Again the domain is persistent. It relies on the domain directory being on a volume.

Finally when the database is UP. The ADMIN server is UP with both containers running and ready. The Build of the 8.0.4 FCCM BD_PACK image can be completed. To build The image run:

    $ sh buildDockerImage.sh -v 8.0.4 

Obviously the binaries for the 8.0.4 BD_PACK need to be downloaded and placed into the directory where the dockerfile is located. On top of this the Oracle FULL client will be needed. This must be 12.1.0.1 as it has the correct ojdbc*.jars contained and post this version only ojdbc8.jar is supplied.

The build image will install the required OS packages and move all the configuration files into the image. The oracle client is also installed.

Before building ensure you have gone through EVERY XML and script. You need to ensure that the configuration is OK for your build. The ones currently defined as well as ALL the run scripts are complete but if you want to change the names or ports etc then these files will all need editting.

Verify you now have this image in place with

    $ docker images

Start a container to launch from the image created in step three.

 Call docker run from the script dockerfiles/docker_run.sh script. 

There are supplied DOCKER RUN scripts in each of the required image directories. See DATABAE, FMW and FCCM directories. These run files are examples and match the supplied configuration / scripts. To update or change ports, volumes, hosts etc you will need to edit the run and configuration.

Docker containers can be checked on status with the docker LOGS command. The following can also be used. $ docker ps (or ps -a)

Ensure the DB, FMW Admin and App server are running for the stack!

###
#First Start
###
When first running any container it will execute its first configuration. This is where it detects is this the first start. If yes then things like RCU or OSC.sh / SETUP.sh are executed and deployments completed.

###
#2nd Starts and onwards
###
As ALL the containers have persistence it means that restarts will just detect that install and config has occurred and just start up.

###
#Monitoring the containers.
###
Docker stats can be used to monitor. Else logs. docker logs XXX -f where XXX is the container name allows the alert logs to be viewed and tracked. This is useful in the first run as well as for subsequent checks.

Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
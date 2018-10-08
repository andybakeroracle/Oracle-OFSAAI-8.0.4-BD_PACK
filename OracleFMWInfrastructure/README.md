Oracle Fusion Middleware Infrastructure on Docker
=================================================
This Docker configuration has been used to create the Oracle Fusion Middleware Infrastructure image. Providing this FMW image facilitates the configuration, and environment setup for DevOps users. This project includes the creation of an  FMW Infrastructure domain. 

The certification of Oracle FMW Infrastructure on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## How to build and run
This project offers a sample Dockerfile and scripts to build a Oracle Fusion Middleware Infrastructue 12cR2 (12.2.1.x) image. To assist in building the image, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-8
        $ sh build.sh

You can also pull the Oracle Server JRE 8 image from [Oracle Container Registry](https://container-registry.oracle.com) or the [Docker Store](https://store.docker.com/images/oracle-serverjre-8). When pulling the Server JRE 8 image retag the image so that it works with the existing Dockerfiles.

        $ docker tag container-registry.oracle.com/java/serverjre:8 oracle/serverjre:8
        $ docker tag store/oracle/serverjre:8 oracle/serverjre:8
        
### Building the Oracle FMW Infrastructure 12.2.1.x base image
**IMPORTANT:**If you are building the Oracle FMW Infrastructure image you must first download the Oracle FMW Infrastructure 12.2.1.x binary and drop in folder `../OracleFMWInfrastructure/dockerfiles/12.2.1.x`. 

        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version]
        Builds a Docker Image for Oracle FMW Infrastructure.

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.x
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        LICENSE UPL 1.0

        Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** the resulting images will have a domain with an Admin Server and one Managed Server by default. You must extend the image with your own Dockerfile, and create your domain using WLST.


### Sample FMW Infrastructure Domain 
The image **oracle/fmw-infrastructure:12.2.1.x** will configure a **base_domain** with the following settings:

 * Admin Username: `weblogic`
 * Admin Password: `Auto generated` 
 * DB Schema Password: 'Auto generated'
 * DB Username: 'sys' 
 * DB Password: 'Auto Generated at runtime by DB container' 
 * RCU Prefix: 'INFRA6'
 * Oracle Linux Username: `oracle`
 * Oracle Linux Password: `welcome1`
 * Domain Name: `InfraDomain`
 * Admin Server on port: `7001`
 * Managed Server on port: `8001`
 * Production Mode: `production`
  

### Admin Password and Database Schema Password

On the first startup of the container a random password will be generated for the Administration of the domain. You can find this password in the output line:

`Oracle WebLogic Server auto generated Admin password:`

An Oracle Database Schema password will be genrated randomly. You can find this password in the output line:

`Database Schema password Auto Generated :`

If you need to find the passwords at a later time, grep for "password" in the Docker logs generated during the startup of the  container.  To look at the Docker Container logs run:

	$ docker logs --details <Container-id>

### Write your own Oracle Fusion Middleware Infrastructure domain with WLST
The best way to create your own domain or extend an existing domain is by using the [WebLogic Scripting Tool](https://docs.oracle.com/middleware/1221/cross/wlsttasks.htm). You can find an example of a WLST script to create domains at [createInfraDomain.py](dockerfiles/12.2.1.x/container-scripts/createInfraDomain.py). You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override an existing domain, or create a new one with WLST.

## Running the Oracle FMW Infrastructure Domain Docker Image
To run a FMW Infrastructure Domain sample container, you will need the FMW Infrastructure Domain image and an Oracle Database. The Oracle Database could be remote or running in a container. If you want to run Oracle Database in a container, you can either pull the image from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com) or build your own image using the Dockerfiles and Scripts in this Git repository.

Follow the steps below:

  1. Create the docker network for the infra server to run
  
	$ docker network create -d bridge InfraNET
  		
  2. Run the Database container to host the RCU schemas
     The Oracle database server container requires custom configuration parameters for starting up the container.This custom configuration parameters correspond to the Data Source parameters in the FMW Infrastructure image to connect to the database running in the container. Add to an env 'env.txt' file the following parameters:
     
	DB_SID=InfraDB
	DB_PDB=InfraPDB1
	DB_DOMAIN=us.oracle.com 
	DB_BUNDLE=basic
 	
	$ docker run -d --name InfraDB --network=InfraNET -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:12.2.0.1
 

      Verify that the Database is running and healthy, the STATUS field shows (healthy) in the output of docker ps.

     The Database is created with the default password Oradoc_db1, to change the database password you must use sqlplus.  To run sqlplus pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a sqlplus container with the following command: 
	
	$ docker run -ti --network=InfraNET --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@InfraDB:1521/InfraDB.us.oracle.com AS SYSDBA 
	
	SQL> alter user sys identified by MYDBPasswd container=all;


  3. Build the **12.2.1.x** FMW Infrastructure image. To build The FMW Infrastructure image run:

	$ sh buildDockerImage.sh -v 12.2.1.x 

  4. Verify you now have this image in place with

	$ docker images
  
  5. Start a container to launch the Admin Server from the image created in step three. The environment variables used to configure the InfraDomain are defined in infraDomain.env.list file. Replace in infraDomain.env.list the values for the Database and WebLogic passwords. Call docker run from the **dockerfiles/12.2.1.x** directory where the infraDomain.env.list file is and pass the file name at runtime. To run an Admin Server container call: 

	$ docker run -d -p 9001:7001 --network=InfraNET -v $HOST_VOLUME:/u01/oracle/user_projects --name InfraAdminContainer --env-file ./infraDomain.env.list oracle/fmw-infrastructure:12.2.1.X

Where $HOST_VOLUME stands for a directory on the host where you map your domain directory and both the Admin Server and Managed Server containers can read/write to.

  6. Access the administration console

	$ docker inspect --format '{{.NewworkSettings.IPAddress}}' <container-name>
        This returns the IPAddress (example xxx.xx.x.x) of the container.  Got to your browser and enter http://xxx.xx.x.x:9001/console
        
        Since the container ports are mapped to host port, you can access using the hostname as well.
  
  7. Start a container to launch the Managed Server from the image created in step 3. The environment variables used to run the Managed Server image are defined in the file infraserver.env.list. Call docker run from the **dockerfiles/12.2.1.x** directory where the infraserver.env.list file is and pass the file name at runtime. To run a Managed Server container call:

	$ docker run -d -p 9801:8001 --network=InfraNET --volumes-from InfraAdminContainer --name InfraManagedContainer --env-file ./infraServer.env.list oracle/fmw-infrastructure:12.2.1.x startManagedServer.sh

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

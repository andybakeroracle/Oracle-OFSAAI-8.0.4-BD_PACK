#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FCCM BD Pack
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# The Oracle image extends the Oracle java image, you must first build that.
# Run: 
#      $ docker build -f Dockerfile -t oracle/ofsaa-fccm:8.0.4
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a FCMM Base.
#
# From 
# -------------------------
FROM oracle/serverjre:8 

# Maintainer
# ----------
MAINTAINER Andy Baker <andy.t.baker@oracle.com>


# Common environment variables required for this build 
# ----------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    SCRIPT_FILE=/u01/oracle/container-scripts/* \
    VOLUME_DIR1=/u01/oracle/OFSAA/DOWNLOAD \
    VOLUME_DIR2=/u01/oracle/OFSAA/FIC_HOME \
    VOLUME_DIR3=/u01/oracle/OFSAA/FTPSHARE \
    ENV="/u01/oracle/.profile" \
    PKG=V860826-01.zip \
    FCCMAPPS_OS_PASSWORD=Ofsaa_123 \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/container-scripts:/u01/oracle/client/12.1.0.1/bin

# USER root    
# Setup subdirectory for install package and container-scripts
# -----------------------------------------------------------------  
RUN yum -y install iputils && \
    yum -y install oracle-rdbms-server-12cR1-preinstall && \
    yum -y install net-tools && \
    yum -y install unzip && \
    yum -y install zip && \
    yum -y install expect && \
    yum -y install openssh && \
    yum -y install openssh-server && \
    yum -y install openssh-clients && \
    yum -y install sudo && \
    yum -y install ksh && \
    yum -y install libaio && \
    yum -y install redhat-lsb* && \
    yum -y clean all && \
    rm -rf /var/cache/yum && \
    mkdir -p /u01 && \ 
    usermod -d /u01/oracle -s /bin/ksh oracle && \
    echo "oracle:$FCCMAPPS_OS_PASSWORD" | chpasswd && \
    mkdir -p /u01/oracle/container-scripts && \
    mkdir -p /u01/oracle/OFSAA/FIC_HOME && \
    mkdir -p /u01/oracle/OFSAA/FTPSHARE && \
    mkdir -p /u01/oracle/OFSAA/DOWNLOAD && \
    mkdir -p /u01/oracle/OFSAA/install && \
    mkdir -p /u01/oracle/client && \
    mkdir -p /u01/oracle/oraInventory && \
    mkdir -p /u01/oracle/client/12.1.0.1 && \
    mkdir -p /u01/oracle/tnsadmin

ADD profile /u01/oracle/.profile
ADD kshrc /u01/oracle/.kshrc
ADD login_banner.sh /u01/oracle/.login_banner.sh
ADD tnsnames.ora /u01/oracle/tnsadmin/tnsnames.ora

#
# Copy packages and scripts
# -------------
COPY container-scripts/* /u01/oracle/container-scripts/

# Install FULL Oracle Client 12.1.0.1 ** NOT INSTANT CLIENT **
# Had to be CUSTOM Response File due to Options Required.
# ------------------------------------------------------------------
#
COPY linuxamd64_12c_client.zip client_install.rsp /u01/oracle/OFSAA/DOWNLOAD/STAGE_ORACLE_CLIENT/

#Fix Pam authority for sftp and su, ssh due to oracle rpm.
COPY pam.d/* /etc/pam.d/

RUN  unzip /u01/oracle/OFSAA/DOWNLOAD/STAGE_ORACLE_CLIENT/linuxamd64_12c_client.zip -d /u01/oracle/OFSAA/DOWNLOAD/STAGE_ORACLE_CLIENT && \ 
     chown -R oracle:oinstall /u01/oracle && \
     chown -R oracle:dba /u01/oracle/oraInventory && \
     chmod 775 /u01/oracle/oraInventory
## 
# As Oracle user run the Installer to install the client.
##
USER oracle
RUN  /u01/oracle/OFSAA/DOWNLOAD/STAGE_ORACLE_CLIENT/client/runInstaller -ignoreSysPrereqs -ignorePrereq -waitforcompletion -showProgress -silent -responseFile /u01/oracle/OFSAA/DOWNLOAD/STAGE_ORACLE_CLIENT/client_install.rsp 

##
# As root finish the preparation of the build.
##
USER root 

#
# Copy packages
# -------------
COPY $PKG /u01/oracle/container-scripts 

#
# Copy Prepared Config Files for Install / Start
# -------------
ADD envCheck.sh preinstallcheck.sh OFS_BD_SCHEMA_IN.xml SETUP.exp OSC.exp SSH.exp FIX_INSTALL.sh OFS_BD_PACK.xml OFSAAI_InstallConfig.xml InstallConfig.xml /u01/oracle/container-scripts/ 

RUN chown oracle:oinstall -R /u01/oracle/container-scripts && \
    chmod -R +xr /u01/oracle/container-scripts && \
    chmod -R +xr /u01/oracle/OFSAA/install && \
    /usr/bin/ssh-keygen -A && \
    /u01/oracle/oraInventory/orainstRoot.sh && \
    echo "oracle ALL = NOPASSWD: /usr/sbin/sshd" >> /etc/sudoers

VOLUME  $VOLUME_DIR1 $VOLUME_DIR2 $VOLUME_DIR3
    
WORKDIR ${ORACLE_HOME}

#Expose ports required.
EXPOSE 6500 6501 6505 6507 6509 6510 6666 9999 10101

#
# Define default command to start script, determine if installed and run the install
# All done as the oracle user.
USER oracle
CMD ["/u01/oracle/container-scripts/createOrStartApplication.sh"]

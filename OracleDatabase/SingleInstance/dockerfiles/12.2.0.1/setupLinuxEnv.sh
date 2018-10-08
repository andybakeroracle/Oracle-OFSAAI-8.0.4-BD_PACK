#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2018
# Author: Andy Baker based on Author: gerald.venzl@oracle.com
# Had to hack due to install_files+1 needed changing for multiple files.  SIZE to big for overlayfs.
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
mkdir -p $ORACLE_BASE/scripts/setup && \
mkdir $ORACLE_BASE/scripts/startup && \
ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d && \
mkdir $ORACLE_BASE/oradata && \
chmod ug+x $ORACLE_BASE/*.sh && \
yum -y install oracle-database-server-12cR2-preinstall unzip tar openssl && \
yum -y install openssh && \
yum -y install openssh-server && \
yum -y install openssh-clients && \
yum -y install sudo && \
rm -rf /var/cache/yum && \
echo "oracle ALL = NOPASSWD: /usr/bin/ssh-keygen, /usr/sbin/sshd" >> /etc/sudoers && \
echo "oracle:Ofsaa_123" | chpasswd && \
chown -R oracle:dba $ORACLE_BASE

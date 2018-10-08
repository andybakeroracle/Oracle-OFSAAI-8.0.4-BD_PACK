#!/bin/ksh 
mod="normal" 
if [[ $# == 0 ]];then
   echo "ERROR: To run the Environment Utility in standalone mode kindly use it with -s option."
   exit 1
fi
if [ $1 = "-s" ];then
  mod="-s" 
  [[ ! -f "./VerInfo.txt" ]] && { echo "VerInfo.txt file not present in current folder."; exit; }
else
  [[ ! -f "../OFS_AAI/bin/VerInfo.txt" ]] && { echo "VerInfo.txt file not present in current folder."; exit; }
fi
[[ -f "$HOME/.profile" ]] && permissions=$(perl -e'printf "%o\n",(stat shift)[2] & 07777'  $HOME/.profile | cut -c1) || { echo Error: OFSAAI-1004 - File .profile is not present in $HOME.; exit; }

if test $permissions != "6" -a $permissions != "7";then
   echo "Error: $LOGNAME user does not have read & write permissions for .profile file."
   exit;
fi
 
if [ $# -eq 6 ] && [ $1 = "-s" ];then   # -s SYS AS SYSDBA PASSWORD SID
  USERNAME=$2
  PASS=$5
  SID=$6  
  OPTION="$3 $4"  
  OPTION=$(echo $OPTION | tr '[:lower:]' '[:upper:]')
elif [ $# -eq 4 ] && [ $1 = "-s" ];then # -s SYS AS SYSDBA/PASSWORD@SID
   USERNAME=$2
   userNm=$(echo $3 | tr '[:lower:]' '[:upper:]')
   if test $userNm = "AS";then
     PASS=$(echo $4 | cut -f2 -d '/' | cut -f1 -d '@')
     SID=$(echo $4 | cut -f2 -d '@') 
     OPTION="$3 $(echo $4 | cut -f1 -d '/')"	 
	 OPTION=$(echo $OPTION | tr '[:lower:]' '[:upper:]')
   else                                 # -s USER PASSWORD SID
     PASS=$3
     SID=$4
   fi	
elif [ $# -eq 2 ] && [ $1 = "-s" ];then # -s USER/PASSWORD@SID
   USERNAME=$(echo $2 | cut -f1 -d '/')
   PASS=$(echo $2 | cut -f2 -d '/' | cut -f1 -d '@')
   SID=$(echo $2 | cut -f2 -d '@') 
elif test $# -eq 1 && [ $1 != "-s" ];then # USER/PASSWORD@SID
   USERNAME=$(echo $1 | cut -f1 -d '/')
   PASS=$(echo $1 | cut -f2 -d '/' | cut -f1 -d '@')
   SID=$(echo $1 | cut -f2 -d '@')
fi

echo "Environment check utility started..."
#Java Validation
echo "============================================================="
echo "Java Validation Started ..."
jflag=0
flag=1
pwd=$PWD
javaDir=""
for i in $(echo "$PATH" | tr ":" "\n")
do
  if test -d $i 
  then
      javaDir=$i
	  cd $i	 
	  ls | grep "^java$" >/dev/null 
	  if [[ $? -eq 0 ]];then
		 flag=0
		 break
	  fi 
  fi	  
done
cd $pwd
if [[ $flag -eq 1 ]];then
   echo
   echo "Error: OFSAAI-1003 - JAVA_HOME/bin not found in PATH variable."  
   echo
   jflag=1
else
   echo " Java found in : $i"
fi

myvar=`uname`	
VER=`which java`
export VER
isSymbolicLink=$(ls -l $VER | grep ^l | wc -l)
os=`uname`
if test $isSymbolicLink = "1";then
   if test $os != "AIX";then
       VER=$(python -c 'import os.path; import os; print(os.path.realpath(os.environ["VER"]))')
   fi
fi
export VER
VER=`dirname $VER`
$VER/java -version >tmp.ver 2>&1
if [ $1 = "-s" ];then
  REQUIRED_VERSION=`grep JAVA_VERSION ./VerInfo.txt | cut -d "=" -f2`
else
  REQUIRED_VERSION=`grep JAVA_VERSION ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
fi
ORG_REQUIRED_VERSION=$REQUIRED_VERSION
REQUIRED_VERSION=`echo $REQUIRED_VERSION | sed -e 's;\.;0;g'`
VERSION=`cat tmp.ver | grep "java version" | awk '{ print substr($3, 2, length($3)-2); }'`
orgVersion=$VERSION
rm tmp.ver
ORG_JAVA=`echo $VERSION | awk '{ print substr($1, 1, 3); }' `
VERSION=`echo $VERSION | awk '{ print substr($1, 1, 3); }' | sed -e 's;\.;0;g'`
if [ $VERSION ];then
	if [[ $REQUIRED_VERSION != *$VERSION* ]];then
	   echo
	   echo Error: OFSAAI-1226 - Make sure Java version is $ORG_REQUIRED_VERSION. Use java -version to check.
	   echo
	   jflag=1
	fi
else
	echo
	echo Error: OFSAAI-1226 - Make sure Java version is $ORG_REQUIRED_VERSION. Use java -version to check.
	echo
	jflag=1
fi
ORG_REQUIRED_VERSION=$ORG_JAVA
export ORG_REQUIRED_VERSION

file $VER/java >tmp.ver 2>&1
BITVALUE=64-bit
if test $myvar = "AIX" ; then
	VALUE=`cat tmp.ver | grep "64-bit" | awk '{ print substr($2, 1); }'`
elif test $myvar = "HP-UX" ; then
	VALUE=`cat tmp.ver | grep "ELF-64" | awk '{ print substr($2, 1); }'`
	BITVALUE=ELF-64
else
	VALUE=`cat tmp.ver | grep "64-bit" | awk '{ print substr($3, 1); }'`
fi
rm tmp.ver
if [ $VERSION ];then
   if [[ $VALUE != $BITVALUE ]];then
      echo Error: OFSAAI-1227 - Make sure 64-bit java executable is set in the PATH variable
      jflag=1
   fi
else 
	echo Error: OFSAAI-1227 - Make sure 64-bit java executable is set in the PATH variable
	jflag=1
fi
export PATH=$VER:$PATH:.

if test $myvar = "SunOS";then
  /usr/bin/java -version >tmp.ver 2>&1
  REQUIRED_VERSION='1.7'
  REQUIRED_VERSION=`echo $REQUIRED_VERSION | sed -e 's;\.;0;g'`
  VERSION=`cat tmp.ver | grep "java version" | awk '{ print substr($3, 2, length($3)-2); }'`
  rm tmp.ver
  VERSION=`echo $VERSION | awk '{ print substr($1, 1, 3); }' | sed -e 's;\.;0;g'`
  if [[ $VERSION -ne $REQUIRED_VERSION ]];then
	   echo
	   echo [WARNING]:- Make sure /usr/bin/java version is $ORG_REQUIRED_VERSION. Use /usr/bin/java -version to check.
	   echo	   
  fi
fi

if test $jflag -eq 1;then
  echo "Java Validation Completed. Status : FAIL"
else
  echo " JAVA Version found : $orgVersion"
  echo " JAVA Bit Version found : $BITVALUE"
  echo "Java Validation Completed. Status : SUCCESS"
fi
echo "============================================================="
#Validation ends here

#Environment Variables Validation
echo "Environment Variables Validation Started ..."
eflag=0
if [ -z "${ORACLE_HOME}" ];then
   echo " ORACLE_HOME variable not set."
   eflag=1
else
   echo " ORACLE_HOME : $ORACLE_HOME"
fi
if [ -z "${TNS_ADMIN}" ];then
   echo " TNS_ADMIN variable not set."
   eflag=1
else
   echo " TNS_ADMIN : $TNS_ADMIN"
fi
if test $eflag -eq 1;then
  echo "Environment Variables Validation Completed. Status : FAIL"
else
  echo "Environment Variables Validation Completed. Status : SUCCESS"
fi
echo "============================================================="
#Validation ends here

#OS specific Validation
echo "OS specific Validation Started ..."
oflag=0
localeCount=$(locale -a | grep -i 'en_US.utf' | wc -l)
if test $localeCount = "0";then
    echo " Checking en_US.utf8 locale. Status : FAIL"
	oflag=1
else
    echo " Checking en_US.utf8 locale. Status : SUCCESS"	
fi
echo "$SHELL" | grep "ksh" >/dev/null 
[[ $? -ne 0 ]] && { echo " Unix shell found : $SHELL. Status : FAIL"; oflag=1; } || { echo " Unix shell found : $SHELL. Status : SUCCESS"; }

if test $myvar = "Linux";then
   fd=`ulimit -n`
   if test $fd = "unlimited";then
     echo " Total file descriptors : $fd. Status : SUCCESS"
   elif test $fd -lt 15000;then
     echo " Total file descriptors for the user cannot be less than 15000. Current value : $fd. Status : FAIL"
	 oflag=1
   else
     echo " Total file descriptors : $fd. Status : SUCCESS"
   fi
   nop=`ulimit -u`
   if test $nop = "unlimited";then
     echo " Total number of process : $nop. Status : SUCCESS"
   elif test $nop -lt 4096;then
     echo " Total number of process for the user cannot be less than 4096. Current Value : $nop. Status : FAIL"
	 oflag=1
   else
     echo " Total number of process : $nop. Status : SUCCESS"
   fi
fi
if test $myvar = "Linux";then
  if [ $1 = "-s" ];then
    fileversion=`grep Linux ./VerInfo.txt | cut -d "=" -f2`
  else 
    fileversion=`grep Linux ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
  fi	
  if [ ! -x /usr/bin/lsb_release ];then
    machineversion=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
  else
    machineversion=`/usr/bin/lsb_release -r | tr -s '\t' ' ' | cut -d ' '  -f2`
  fi
  if [[ machineversion -lt 6.2 ]];then
     finalver="5"
  elif [[ machineversion -lt 7.1 ]]; then
     finalver="6"
  else
	 finalver="7"
  fi
elif test $myvar = "AIX";then
   if [ $1 = "-s" ];then
    fileversion=`grep AIX ./VerInfo.txt | cut -d "=" -f2`
  else 
    fileversion=`grep AIX ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
   fi
  machineversion=`oslevel | grep ^5`
  if [[ $machineversion == 5* ]];then
     machineversion="5.3"
	 finalver="5"
  fi
  machineversion=`oslevel | grep ^6`
  if [[ $machineversion == 6* ]]; then
     machineversion="6.1"
	 finalver="6"
  fi
   machineversion=`oslevel | grep ^7`
   
   if [[ $machineversion == 7* ]]; then
	 machineversion="7.1"
	 finalver="7"
  fi
elif test $myvar = "SunOS";then
  isSparc=$(uname -a | grep sparc | wc -l)
  if test $isSparc = "1";then
    echo " Hardware Architecture - SPARC. Status : SUCCESS"
  else
    echo " Hardware Architecture - x86. Status : SUCCESS"
	#oflag=1
  fi
  if [ $1 = "-s" ];then
    fileversion=`grep SunOS ./VerInfo.txt | cut -d "=" -f2`
  else 
    fileversion=`grep SunOS ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
  fi	
  machineversion=`uname -r`
  if [[ $machineversion == *11* ]];then
      finalver="11"
      if [ -z "${TZ}" ] || [ $TZ = "localtime" ];then
	     echo " Time zone cannot be set as null or 'localtime'. Current value : $TZ. Status : FAIL"
         oflag=1
	  else
	     echo " Time zone is configured properly. Current value : $TZ. Status : SUCCESS"
	  fi
  else
     finalver="10"
  fi  
elif test $myvar = "HP-UX";then
  if [ $1 = "-s" ];then
    fileversion=`grep HP-Unix ./VerInfo.txt | cut -d "=" -f2`
  else 
    fileversion=`grep HP-Unix ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
  fi	
  machineversion=`uname -r`  
fi
if test $myvar = "Linux";then
 machineversion=${machineversion:0:1}
 if [[ $fileversion != *$machineversion* ]];then
   echo " OS version : incompatible. Current version : $machineversion. Expected version : $fileversion. Status : FAIL"
   oflag=1
  else
   echo " OS version : $machineversion. Status : SUCCESS"
  
 fi
else
 if [[ $fileversion != *$machineversion* ]];then
  echo " OS version : incompatible. Current version : $machineversion. Expected versions : $fileversion. Status : FAIL"
  oflag=1
 else
  echo " OS version : $machineversion. Status : SUCCESS"
 fi
fi
export OSVERSION=$finalver
test $oflag -eq 1 && echo "OS specific Validation Completed. Status : FAIL" || echo "OS specific Validation Completed. Status : SUCCESS"
echo "============================================================="
#Validation ends here

#DB specific Validation
echo "DB specific Validation Started ..."
dbflag=0

if ([ $1 != "-s" ] && [ $# -ne 1 ] && [ $# -ne 3 ]) || ([ $1 = "-s" ] && [ $# -ne 2 ] && [ $# -ne 4 ] && [ $# -ne 6 ]);then
	echo " Please enter Oracle DB user name:"
	read USERNAME 
	echo " Please enter password:"
	stty -echo
	read PASS
	stty echo    
	echo " Please enter Oracle SID/SERVICE name:" 
	read SID	
	if [ -z "${USERNAME}" ] || [ -z "${PASS}" ] || [ -z "${SID}" ];   
    then
		echo " Error: Username or Password or SID are empty"
		dbflag=1
	fi
fi

user=$(echo $USERNAME | tr '[:lower:]' '[:upper:]')

if [[ ${user} == *SYSDBA* ]];then  
   USERNAME=$(echo $USERNAME | cut -d ' ' -f1) 
   OPTION="AS SYSDBA"
fi

LOGFILE=EnvCheck.log
sqlplus -s /nolog <<-EOF> ${LOGFILE}
WHENEVER OSERROR EXIT 9;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
connect $USERNAME/"$PASS"@$SID $OPTION
EOF
exitStaus=$?
if test $exitStaus == 0;then
    #Checking client version
	[[ ! -f "$ORACLE_HOME/bin/sqlplus" ]] && { echo "sqlplus file not present in $ORACLE_HOME/bin folder."; dbflag=1; }
	clientVersion=$(sqlplus -v | grep . | cut -d ' ' -f3)
    if [ $1 = "-s" ];then
      fileversion=`grep DB_CLIENT_VERSION ./VerInfo.txt | cut -d "=" -f2`
    else 	
	  fileversion=`grep DB_CLIENT_VERSION ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
	fi
	if [[ $fileversion != *$(echo $clientVersion | cut -c1-2)* ]];then
	   echo " Oracle Client version validation failed. Only Oracle 11 series is supported. Current version : $clientVersion. Expected version : 11 Series. Status : FAIL"
	  dbflag=1
	  else
	  echo " Oracle Client version : $clientVersion. Status : SUCCESS"	  
	  fi
   
     if [ $1 != "-s" ];then
	    userN=$(perl -ne 'if (/<USERNAME/){ s/.*?>//; s/<.*//;print;}' ../schema_creator/${PACK_ID}_SCHEMA_OUTPUT.xml)
		$(perl -ne 'if (/<USERNAME/){ s/.*?>//; s/<.*//;print;}' ../schema_creator/${PACK_ID}_SCHEMA_OUTPUT.xml > userlist.txt)
		pass=$(perl -ne 'if (/PASSWORD/){ s/.*?>//; s/<.*//;print;}' ../schema_creator/${PACK_ID}_SCHEMA_OUTPUT.xml > pass.txt)
		type=$(perl -ne 'if (/<TYPE/){ s/.*?>//; s/<.*//;print;}' ../schema_creator/${PACK_ID}_SCHEMA_OUTPUT.xml > type.txt)
		
		set -A UserNameList $userN		
        if [[ ${#UserNameList[@]} -eq 0 ]]; then
		   set -a UserNameList $userN 		   
        fi		
			
		i=1
		while [[ $i -le ${#UserNameList[@]} ]]
		do      
          userN=$(sed -n ${i}p userlist.txt)
          pass=$(sed -n ${i}p pass.txt)
		  type=$(sed -n ${i}p type.txt)
		  
		  if [[ -z "${pass}" ]];then
		      i=$(echo $i + 1 | bc);
		  else  
              if [[ "${type}" = "PRODUCTION" ]] || [[ "${type}" = "SANDBOX" ]];then		    		  
		        res=`sqlplus -s /nolog <<-EOF
				WHENEVER OSERROR EXIT 9;
				WHENEVER SQLERROR EXIT SQL.SQLCODE;
				connect $USERNAME/"$PASS"@$SID 
				SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF 		
				select count(*) from db_master t where t.dbname != 'CONFIG' and t.dbuserid = '${userN}';		
				exit 0
				EOF`
						
			    if [[ $res -lt 1 ]];then
					echo
					echo " Error fetching database schemas required for ${PACK_ID} Application Pack from OFSAA setup. Either the schema creator utility for ${PACK_ID} Application Pack has failed with errors or the schema creator utility scripts are not executed on the database. For more details, refer the schema creator utility log file located at ${PACK_ID}/schema_creator/logs. Status : FAIL"
					echo
					dbflag=1
			    else
					pass="${pass}"  
					pass=$(java -cp .:install.jar install.DecryptScPass $pass | tail -1)      				
					LOGFILE=EnvCheck.log	
	  
					sqlplus -s /nolog <<-EOF> ${LOGFILE}
					WHENEVER OSERROR EXIT 9;
					WHENEVER SQLERROR EXIT SQL.SQLCODE;
					connect ${userN}/"$pass"@$SID
					EOF
									
					exitStaus=$?		
					if test $exitStaus != 0;then			
						echo " Error connecting to schema ${userN}. ERROR -> $(head -2 ${LOGFILE} | tail -1)"
						dbflag=1
					else
						echo " Successfully connected to schema ${userN}. Status : SUCCESS"				
					fi
					[[ -f "${LOGFILE}" ]] && rm ${LOGFILE}
				fi              			 
		     fi
		     i=$(echo $i + 1 | bc)
		  fi
		done
		[[ -f "userlist.txt" ]] && rm userlist.txt
		[[ -f "pass.txt" ]] && rm pass.txt
		[[ -f "type.txt" ]] && rm type.txt
	fi 
	  
    if [ $1 != "-s" ];then
		set -A Grants 'SESSION' 'PROCEDURE' 'VIEW' 'TRIGGER' 'MATERIALIZED VIEW' 'TABLE' 'SEQUENCE' 
        if [[ ${#Grants[@]} -eq 0 ]]; then
		   set -a Grants 'SESSION' 'PROCEDURE' 'VIEW' 'TRIGGER' 'MATERIALIZED VIEW' 'TABLE' 'SEQUENCE' 		   
        fi		
		res=`sqlplus -s /nolog <<-EOF
		WHENEVER OSERROR EXIT 9;
		WHENEVER SQLERROR EXIT SQL.SQLCODE;
		connect $USERNAME/"$PASS"@$SID $OPTION
		SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF 
		spool output.csv
		select privilege from USER_SYS_PRIVS;
		spool off
		exit 0
		EOF`
		exitStaus=$?
		if test $exitStaus == 0;then
			for role in "${Grants[@]}"
			do
			  check=$(grep -w "$role" output.csv)
			  if test $? == 0;then 
				echo " CREATE $role has been granted to user. Status : SUCCESS";
			  else
				echo " CREATE $role has not been granted to user. Status : FAIL";
				dbflag=1
			  fi  
			done
			rm output.csv;
		else
		   echo " Error while checking grants. Status : FAIL";
		   dbflag=1
		fi
	 fi	
    
	#function to connect & retrieve value from DB 
	#$1->query $2->Error message $3->Success message $4->SQL error $5->expected value $6->Unlimited table space
    checkDbRetrieveVal () {
		res=`sqlplus -s /nolog <<-EOF 
		   WHENEVER OSERROR EXIT 9;
		   WHENEVER SQLERROR EXIT SQL.SQLCODE; 
		   connect $USERNAME/"$PASS"@$SID $OPTION
		   SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF 
		   $1;	
		   exit 0;
		   EOF`
		
		exitStaus=$?	
		if [[ $exitStaus != "0" ]];then
			echo " $4 Status : FAIL";                                         #SQL error
			dbflag=1
		else			
            if ! echo "${res}" | egrep '^[0-9]+$' >/dev/null; then            #Result value is not a number		
			   if test $# -eq 6;then
			       res=$(echo $res | awk '{printf "%.2f\n",$1}')
			       if test ${res} -ne -1;then
					 tblSpc=$(($res/(1024*1024)));
					 if test $tblSpc -lt 500;then
						echo " $2 Current value : ${tblSpc} MB. Status : FAIL"      #FAILURE
					    dbflag=1
					 else	  
					    echo " $3 Current value : ${tblSpc} MB. Status : SUCCESS"   #SUCCESS
					 fi 
				   else
					 echo " $6 Status : SUCCESS"                              #Unlimited
				   fi	
			   else
			     if [ -z "${res}" ];then
				   echo " $2 Current value : NULL. Status : FAIL"             #FAILURE
				   dbflag=1
				 else
				   if [[ $5 == *"ORACLE_DB_SERVER"* ]];then					     
					  res=$(echo ${res#*Release} | cut -d ' ' -f1)
	               fi
				   if test ${res} != "$5";then                                #character value
				      if [[ $2 == *"Oracle Database Partitioning feature is"* ]];then
					    echo " $2 Current value : Non-Partitioned. Status : FAIL"
						dbflag=1
                      elif [[ $5 == *"ORACLE_DB_SERVER"* ]];then
					    if [ $mod = "-s" ];then
						  fileversion=`grep DB_SERVER_VERSION ./VerInfo.txt | cut -d "=" -f2`
						else
					      fileversion=`grep DB_SERVER_VERSION ../OFS_AAI/bin/VerInfo.txt | cut -d "=" -f2`
						fi
						 ORACLE_DB_VERSION=$(echo $res | cut -c1-2)
                         export ORACLE_DB_VERSION						 
	                     if [[ $fileversion != *$(echo $res | cut -c1-2)* ]];then                                     
	                         echo
							 echo " $2 Current value : ${res}."
							 echo
                         else
						     req="1102000300"						 						 
							 if [[ $ORACLE_DB_VERSION = "11" ]]; then
							   subVersion=$(echo $res | cut -c1-10 | sed -e 's;\.;0;g')
							   if [[ $subVersion -lt $req ]]; then
								   echo " ORACLE DB Version should be 11.2.0.3.0 or above. Current value : ${res}."
								   dbflag=1
							   else
                                   echo " $3 Current value : ${res}. Status : SUCCESS"
							   fi
							 else
                                echo " $3 Current value : ${res}. Status : SUCCESS"							 
							 fi						        
                         fi							
					  else
						echo " $2 Current value : ${res}. Status : FAIL"      #FAILURE
					    dbflag=1
					  fi						
			       else
				      if [[ $3 == *"Oracle Database Partitioning feature is"* ]];then
					    echo " $3 Current value : Partitioned. Status : SUCCESS"                      					
					  else
						echo " $3 Current value : ${res}. Status : SUCCESS"   #SUCCESS
					  fi
			       fi
				 fi  
			   fi
			else			   
			   if test ${res} -lt $5;then                                     #numeric value
				  echo " $2 Current value : ${res}. Status : FAIL"            #FAILURE
				  dbflag=1
			   else
				  echo " $3 Current value : ${res}. Status : SUCCESS"         #SUCCESS
			   fi	   
			fi				   
		fi	
    }
	
	#checking select grant for NLS_INSTANCE_PARAMETERS view
	if [ $1 != "-s" ];then	 
     checkDbRetrieveVal "select privilege from all_tab_privs_recd where table_name='NLS_INSTANCE_PARAMETERS' and grantee='$user'" "SELECT privilege is not granted for NLS_INSTANCE_PARAMETERS view." "SELECT privilege is granted for NLS_INSTANCE_PARAMETERS view." "Error while checking select grant for NLS_INSTANCE_PARAMETERS view." "SELECT"
	fi 
	
	#NLS_LENGTH_SEMANTICS
	checkDbRetrieveVal "SELECT value FROM NLS_INSTANCE_PARAMETERS  WHERE PARAMETER='NLS_LENGTH_SEMANTICS'" "Oracle instance must be created with the default NLS_LENGTH_SEMANTICS as BYTE." "NLS_LENGTH_SEMANTICS : BYTE." "Error while fetching NLS_LENGTH_SEMANTICS value." "BYTE"
	
	#NLS_CHARACTERSET
	checkDbRetrieveVal "SELECT value FROM NLS_Database_Parameters WHERE PARAMETER='NLS_CHARACTERSET'" "Oracle instance must be created with the default NLS_CHARACTERSET as AL32UTF8." "NLS_CHARACTERSET : AL32UTF8." "Error while fetching NLS_CHARACTERSET value." "AL32UTF8"
	
	#checking select grant for V_$parameter view
	if [ $1 != "-s" ];then
	 checkDbRetrieveVal "select privilege from all_tab_privs_recd where table_name='V_\$PARAMETER' and grantee='$user'" "SELECT privilege is not granted for V_\$parameter view." "SELECT privilege is granted for V_\$parameter view." "Error while checking select grant for V\$parameters view." "SELECT"
	fi 
	
	#Open Cursor
	checkDbRetrieveVal "SELECT value FROM V\$parameter where name='open_cursors'" "Value of maximum number of open cursor should be at least 1000." "Open cursor value is greater than 1000." "Error while fetching open cursor value." "1000"
	
	#USER_TS_QUOTAS
	if [ $1 != "-s" ];then
	 checkDbRetrieveVal "select privilege from all_tab_privs_recd where table_name='USER_TS_QUOTAS' and grantee='$user'" "SELECT privilege is not granted for USER_TS_QUOTAS view." "SELECT privilege is granted for USER_TS_QUOTAS view." "Error while checking select grant for USER_TS_QUOTAS." "SELECT"
	
	 #Checking table space
	 checkDbRetrieveVal "SELECT NVL(SUM(MAX_BYTES),0) FROM USER_TS_QUOTAS where tablespace_name=(Select default_tablespace from user_users)" "The schema must be granted at least 500 MB table space." "Schema is granted with at least 500 MB table space." "Error while fetching MAX_BYTES from USER_TS_QUOTAS." "500" "Schema is granted with at least 500 MB table space. Current value : Unlimited."	
	fi 
	
	#Checking Oracle Server
	checkDbRetrieveVal "select BANNER from v\$version where BANNER like 'Oracle%'" "[WARNING]:-Oracle Database Server version mismatch - The version of your Oracle Database Server does not match the version of Oracle Database on which this release of OFS AAI has been qualified." "Oracle Server version" "Error while fetching Oracle Server version from v$version." "ORACLE_DB_SERVER"	 

    #Checking Ojdbc.jar
   	if test $ORG_REQUIRED_VERSION == "1.7" -a $ORACLE_DB_VERSION == "12";then
	  [[ ! -f "$ORACLE_HOME/jdbc/lib/ojdbc7.jar" ]] && { echo "ERROR: Compatible version(ojdbc7) of the JDBC driver is not found. Please download & copy the ojdbc7.jar in $ORACLE_HOME/jdbc/lib directory."; dbflag=1; }     
	fi
   else
    echo " ERROR -> $(head -2 ${LOGFILE} | tail -1)"
    dbflag=1 
 fi
 
 [[ -f "${LOGFILE}" ]] && rm ${LOGFILE} 
test $dbflag -eq 1 && echo "DB specific Validation Completed. Status : FAIL" || echo "DB specific Validation Completed. Status : SUCCESS"
echo "============================================================="
#Validation ends here
if test $dbflag -eq 1 -o $oflag -eq 1 -o $jflag -eq 1 -o $eflag -eq 1;then
  echo "Environment check utility Status : FAIL"
  echo "============================================================="
  exit;
else
  echo "Environment check utility Status : SUCCESS"
fi
echo "============================================================="
#End of file 

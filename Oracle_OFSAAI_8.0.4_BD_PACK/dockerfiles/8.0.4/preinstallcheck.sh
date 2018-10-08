trap '[[ -f "../OFS_AAI/bin/tmpDbpassword.txt" ]] && rm -f "../OFS_AAI/bin/tmpDbpassword.txt"; echo "Pre-Install check terminated ..."; exit' 1 2 15

mandatoryFileFlag=0
[[ ! -f "../OFS_AAI/bin/envCheck.sh" ]] && { echo; echo "Error: File envCheck.sh is not present in current folder."; mandatoryFileFlag=1; }

#Check all files required for installation
currdir=`pwd`
PackName=$(basename $(dirname $currdir)) 
#PackName=$(cat $(ls ../conf/*.xml) | grep APP_PACK_ID | tr -s '\t' ' '| awk -F "[><]" '/APP_PACK_ID/{print $3}')
PACK_ID=${PackName%"_PACK"}
export PACK_ID 
[[ $PackName != "OFS_AAAI_PACK" && ! -f "../$PACK_ID/bin/setup.sh" ]] && { echo; echo "Error: File setup.sh is not present in $PACK_ID/bin."; mandatoryFileFlag=1; }		
[[ ! -f "$HOME/.profile" ]] && { echo; echo "Error: OFSAAI-1004 - File .profile is not present in $HOME."; mandatoryFileFlag=1; }
[[ ! -f "../OFS_AAI/bin/OFSAAInfrastructure.bin" ]] && { echo; echo "Error: OFSAAI-1005 - File OFSAAInfrastructure.bin is not present in current folder."; mandatoryFileFlag=1; }         
[[ ! -f "pack_install.bin" ]] && { echo; echo "Error: File pack_install.bin is not present in current folder."; mandatoryFileFlag=1; }
[[ ! -f "pack_installsilent.bin" ]] && { echo; echo "Error: File pack_installsilent.bin is not present in current folder."; mandatoryFileFlag=1; }
[[ $1 != "GUI" && ! -f "../OFS_AAI/conf/OFSAAI_InstallConfig.xml" ]] && { echo; echo "Error: OFSAAI-1007 - File OFSAAI_InstallConfig.xml is not present in current folder."; mandatoryFileFlag=1; }
[[ $1 != "GUI" && ! -f "../OFS_AAI/bin/validateXMLInputs.jar" ]] && { echo; echo "Error: OFSAAI-1008 - File validateXMLInputs.jar is not present in current folder."; mandatoryFileFlag=1; }
[[ ! -f "../OFS_AAI/conf/log4j.xml" ]] && { echo; echo "Error: OFSAAI-1009 - File log4j.xml is not present in current folder."; mandatoryFileFlag=1; }
[[ ! -f "setup.sh" ]] && { echo; echo "Error: OFSAAI-1245 - File setup.sh is not present in current folder."; mandatoryFileFlag=1; }
[[ ! -f "../OFS_AAI/bin/VerInfo.txt" ]] && { echo; echo "Error: OFSAAI-1243 - File VerInfo.txt is not present in current folder."; mandatoryFileFlag=1; }
ct=$(ls ../conf | grep -wi $PackName.xml | wc -l)
[[ $ct -lt 1 ]] && { echo; echo "Error: File $PackName.xml is not present in current folder."; mandatoryFileFlag=1; }
ct=$(ls ../schema_creator| grep -wi ${PACK_ID}_SCHEMA_OUTPUT.xml | wc -l)
[[ $ct -lt 1 ]] && { echo; echo "Error: File ${PACK_ID}_schema_output.xml is missing under schema_creator folder. Please run the schema creator utility before triggering the installation."; mandatoryFileFlag=1; }
[[ $1 != "GUI" && ! -f "../conf/installer.properties" ]] && { echo; echo "Error: File installer.properties is not present in conf folder."; mandatoryFileFlag=1; }

[[ mandatoryFileFlag -eq 1 ]] && { exit; }

if [[ $1 != "GUI" ]] && [[ ! -f $FIC_HOME/conf/Reveleus.SEC ]];then
	appftpsharepath=$(perl -ne 'if (/InteractionVariable name=\"OFSAAI_FTPSHARE_PATH\"/){ s/.*?>//; s/<.*//;print;}' ../OFS_AAI/conf/OFSAAI_InstallConfig.xml)     	 
	permissions=$(perl -e'printf "%o\n",(stat shift)[2] & 07777' $appftpsharepath) || { echo "Error: Invalid OFSAAI Ftpshare path."; exit; }
	if test $permissions = "0";then
		echo "Error: Invalid OFSAAI Ftpshare path."; exit;
	fi
	if test $permissions != "775";then
	   echo "Error: Please provide permissions as(775) for OFSAAI Ftpshare path. Current permission are : $permissions"
	   exit;
	fi
fi	 

myvar=`uname`
if test $myvar = "AIX" ; then
   	LIBPATH=$PWD:$LIBPATH:
	export LIBPATH   
elif test $myvar = "HP-UX" ; then
	SHLIB_PATH=$PWD:$SHLIB_PATH:
	export SHLIB_PATH
	LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH:
	export LD_LIBRARY_PATH		
elif test $myvar = "SunOS" ; then   
	LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH:
	export LD_LIBRARY_PATH
elif test $myvar = "Linux" ; then
	LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH:
	export LD_LIBRARY_PATH
fi

if [ -z "${FIC_HOME}" ];then
   echo " FIC_HOME variable is not set. For installation, FIC_HOME variable should be set in .profile file to User Installation directory value."
   exit
else
   echo " FIC_HOME : $FIC_HOME"
fi

if [[ $# -eq 2 && $1 == "GUI" ]]; then 
    if [ -z "${DISPLAY}" ];then
	   echo " DISPLAY variable is not set. For GUI installation, DISPLAY variable should be set."
	   exit
	else
	   echo " DISPLAY : $DISPLAY"
    fi
	Mountdir=$(dirname $FIC_HOME)
	mountedFileSystem=$(df -k $Mountdir | tail -1 | tr -s '\t' ' ' | cut -d ' ' -f1)
	spaceInMB=$(df -k $Mountdir | tail -1 | tr -s '\t' ' ' | cut -d ' ' -f4)
	if test $myvar = "AIX" ; then
	   spaceInMB=$(df -k $Mountdir | tail -1 | tr -s '\t' ' ' | cut -d ' ' -f3)
	fi
	spaceInMB=$(($spaceInMB / 1024))
	if test $spaceInMB -lt 1500;then
	   echo
	   echo " There is not enough space in your installation mount($mountedFileSystem). Currently it has $spaceInMB MegaBytes. You require at least 1500 MegaBytes for the installation."
	   echo
	   exit
	fi
fi

#backup of pack install file
randomKey=$(perl -e 'my ($sec, $min, $hour, $mday, $mon, $year) =localtime((stat(shift))[9]);printf("%04d_%02d_%02d_%02d_%02d_%02d\n", $year+1900, $mon+1, $mday, $hour, $min, $sec)' ../logs/Pack_Install.log)
[[ -f "../logs/Pack_Install.log" ]] && { $(mv ../logs/Pack_Install.log ../logs/Pack_Install$randomKey.log); }
[[ -f "../$PACK_ID/conf/placeholderfile" ]] && { $(rm -f ../$PACK_ID/conf/placeholderfile); }
[[ -f "../$PACK_ID/conf/default.properties" ]] && { $(cp ../$PACK_ID/conf/default.properties ../$PACK_ID/conf/placeholderfiledefault); }
[[ -f "../$PACK_ID/conf/InstallConfig.xml" ]] && { $(cp ../$PACK_ID/conf/InstallConfig.xml ../$PACK_ID/conf/placeholderfile); }
[[ -f "../$PACK_ID/conf/def_bkp" ]] && { $(rm -f ../$PACK_ID/conf/def_bkp); }
[[ -f "../$PACK_ID/conf/Install_bkp" ]] && { $(rm -f ../$PACK_ID/conf/Install_bkp); }
[[ -f "../OFS_AAI/conf/installer_bkp.properties" ]] && { $(cp ../OFS_AAI/conf/installer_bkp.properties ../OFS_AAI/conf/installer.properties); }
[[ -f "../OFS_AAI/conf/installer.properties" ]] && { $(cp ../OFS_AAI/conf/installer.properties ../OFS_AAI/conf/installer_bkp.properties); }

#Cheking free space on mount & tmp
spaceInMB=$(df -k /tmp | tail -1 | tr -s '\t' ' ' | cut -d ' ' -f4)
if test $myvar = "AIX" ; then
   spaceInMB=$(df -k /tmp | tail -1 | tr -s '\t' ' ' | cut -d ' ' -f3)
fi
spaceInMB=$(($spaceInMB / 1024))
if test $spaceInMB -lt 1500;then
   echo
   echo " There is not enough space in your /tmp. Currently it has $spaceInMB MegaBytes. You require at least 1500 MegaBytes for the installation."
   echo
   exit
fi

#Validation ends here

SchemaInfile=../schema_creator/${PACK_ID}_SCHEMA_OUTPUT.xml
url=$(perl -ne 'if (/JDBC_URL/){ s/.*?>//; s/<.*//;print;}' $SchemaInfile)
isLdapUrl=$(echo $url | grep ":@ldaps*:" | wc -l)
if [[ $isLdapUrl -eq 1 ]]; then
    # Parse OID string   
    DATABASENAME=$(echo $url | sed -n -e "s/^.*[0-9]*\///p" | cut -d ',' -f1) 
else
	DATABASENAME=$(echo $url| tr -s '\t' ' ' | tr -d ' '|cut -d ':' -f6)
	if [[ -z "$DATABASENAME" ]];then 
	 if [[ "$url" == */* ]];then
		   DATABASENAME=`echo $url| tr -s '\t' ' ' | tr -d ' '|cut -d "/" -f2` 	   
		   if [[ -z "$DATABASENAME" ]];then
			  DATABASENAME=`echo $url| tr -s '\t' ' ' | tr -d ' '|cut -d "/" -f4`		  
		   fi	   
	  else
		   DATABASENAME=`echo $url| tr -s '\t' ' ' | tr -d ' '| sed -n 's/^.*\(SERVICE[^)]*\).*/\1/p'|cut -d "=" -f2`
	 fi
	fi 
fi	

SchemaOutfile=../schema_creator/${PACK_ID}_SCHEMA_OUTPUT.xml
user=$(perl -ne 'if (/USERNAME/){ s/.*?>//; s/<.*//;print;}' $SchemaOutfile)
user=$(echo $user | cut -d " " -f1)

password=$(perl -ne 'if (/PASSWORD/){ s/.*?>//; s/<.*//;print;}' $SchemaOutfile)
password=$(echo $password | cut -d " " -f1)
fincpass=$(java -cp .:install.jar install.DecryptScPass $password)

[[ -f "../OFS_AAI/bin/envCheck.sh" ]] && . ../OFS_AAI/bin/envCheck.sh $user/$fincpass@$DATABASENAME

[[ -f "../OFS_AAI/logs/InfrastructurePreInstallCheck.log" ]] && rm -f ../OFS_AAI/logs/InfrastructurePreInstallCheck.log
if [[ $# -eq 0 || $mode == "SILENT" ]]; then 
   touch ../OFS_AAI/logs/InfrastructurePreInstallCheck.log 
   infodomCount=$(cat $SchemaOutfile | grep '<INFODOM>'|wc -l)
   if [ $IR_FLAG != "0" ];then
	   if [[ $infodomCount == "0" ]];then
		  echo
		  echo "ERROR: Please run the schema creator utility with silent mode option or run setup.sh in GUI mode."
		  exit 1
	   fi
   fi	   
   if [ ! -f $FIC_HOME/conf/Reveleus.SEC ] ; then
    [[ $# -eq 0 ]] && java -jar ../OFS_AAI/bin/validateXMLInputs.jar VALIDATE || /u01/oracle/OFSAA/install/SETUP.exp $1  
   fi
fi
#End of the file thank you 

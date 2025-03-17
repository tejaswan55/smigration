 
#This script is used to Extract the GCMMP data and mask it and than send it to HDP server
#!/bin/ksh
#**********************************************************************************************
#
#  Name          : CTA_GCMMP.ksh
#
#  Category      : G9Strategy Collections
#  Author        : Shubham Sawant
#  Date          :
#
#  Description   : This script calls the SAS program Extract_CTA_VNM_GCMMP.sas , C9_Masking_Process_VNM_GCMMP.sas , INC_makefile_VNM_GCMMP.sas
#
#**********************************************************************************************
 
set -vx
 
. $(dirname $0)/st_vars.ksh
. $(dirname $0)/st_funcs.ksh
. $(dirname $0)/st_cnty_vars.ksh
 
logstart
 
export scnty=`echo ${CNTY} | tr '[:upper:]' '[:lower:]'`
 
 
#=========================================================
# Usage
#=========================================================
 
SCRIPTNAME=`basename $0`
usage()
{
    cat <<-EOF
    Usage : $SCRIPTNAME <Site>
                or
                        $SCRIPTNAME <Site> <Rundate>
            Site: Country code.
 
EOF
}
 
#=========================================================
# check parameters count
#=========================================================
 
if [ $# -ne 1] && [ $# -ne 2 ] ; then
    usage
    exit 3
fi
 
#=========================================================
# ## Variables
#=========================================================
 
export CTRY=$1
if [ $# -eq 2 ] ; then
export RUNDATE=$2
fi
 
 
#=========================================================
# ## Main Processing
#=========================================================
 
 
#export PROG=Extract_CTA_${CTRY}_GCMMP.sas
#sasbatch $ST_SASPGM $PROG
#retcode=$?
#if [ $retcode -le 1 ]; then
#echo '    ----> Successfully completed the  ' $PROG '.......'
 
   #logend
   #exit 0
#else
#   logend 2
#   exit 2
#fi
 
#=========================================================
###Masking data
#=========================================================
export PROG2=C9_Masking_Process_${CNTY}_GCMMP.sas
echo "Starting ===== execute file ${filename} ...  ==== Masking data"
 
sasbatch $ST_SASPGM $PROG2
retcode=$?
if [ $retcode -le 1 ]; then
   echo "Success!!!!!!!!!!!"
   #logend
   #exit 0
else
  logend 2
  exit 1
fi
 
#=========================================================
###Converting data
#=========================================================
 
export PROG3=INC_makefile_${CNTY}_GCMMP.sas
echo "Starting ===== execute file ${filename} ...  ==== Converting data"
sasbatch $ST_SASPGM $PROG3
retcode=$?
if [ $retcode -le 1 ]; then
   echo "Success!!!!!!!!!!!"
   #logend
   #exit 0
else
  logend 2
  exit 1
fi
 

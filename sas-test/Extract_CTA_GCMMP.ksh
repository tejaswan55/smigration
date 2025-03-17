#This script is used to run Extract_CTA_${CTRY}_GCMMP.sas program
. $(dirname $0)/st_vars.ksh
. $(dirname $0)/st_funcs.ksh
. $(dirname $0)/st_cnty_vars.ksh
 
 
logstart
 
export CTRY=$1
export PROG=Extract_CTA_${CTRY}_GCMMP.sas
sasbatch $ST_SASPGM $PROG
retcode=$?
if [ $retcode -le 1 ]; then
   echo "Success!!!!!!!!!!!"
   logend
   exit 0
else
  logend 2
  exit 1
fi
 

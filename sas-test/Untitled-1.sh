C9_Masking_Process_GCMMP.sas
/*----------------------------------------------------------------------------------------------*/
/*   PROGRAM:   C9_Masking_Process_GCMMP.sas                                */
/*   VERSION:   1                                                                               */
/*   CREATOR:   SHUBHAM SAWANT                                                                    */
/*   DATE:      12AUG2024                                                                 */
/*   DESC:      This program create a Master table having Anonymous Non Sensitive Fields        */
/*               input file and updates the Master Lookup Tables.                       */
/*----------------------------------------------------------------------------------------------*/
 
/*-------------------------------------------------*/
/*  Libname Definition for In_file and Out_file    */
/*  Master Key Generation Location                 */
/*  Variables Define                               */
/*-------------------------------------------------*/
 
 
Options FULLSTIMER missing=' ';
/*options nocenter symbolgen mprint mlogic;*/
 
%LET RUNDATE = %SYSGET(RUNDATE);
%put &RUNDATE;
%LET CTRY = %SYSGET(CTRY);
%put &CTRY;
%LET C9MARTS = %SYSGET(ST_CNTY_C9MARTS);
%LET KEYLOC = %SYSGET(ST_CNTY_KEYGEN);
%LET ST_INGEST=%SYSGET(ST_CNTY_INGEST);
%LET SASPGMS=%SYSGET(ST_SASPGM);
%LET ENVIRONMENT = %SYSGET(ENVIRONMENT);
%PUT &ENVIRONMENT;
%LET CYBER_LAYOUT=%SYSGET(ST_SAS_LAYOUT);
%put &CYBER_LAYOUT;
%LET SRC_LANDING=%SYSGET(ST_SRC_LAND);
%put &SRC_LANDING;
 
data _null_;
  call symput('RUNDATE',put(input("&rundate",yymmdd8.)-0,yymmddn8.));
run;
 
data _null_;
  call symput('RUNDATEN',put(input("&rundate",yymmdd8.)+1,yymmddn8.));
run;
 
%put RUNDATE = &RUNDATE.;
%put RUNDATEN = &RUNDATEN.;
 
%LET KEYLOC=%SYSGET(ST_CNTY_KEYGEN);
libname KEYLIB "&KEYLOC" ;
 
%LET ST_INGEST=%SYSGET(ST_CNTY_INGEST);
Libname OUTLIB "&ST_INGEST./nonsensitive/&RUNDATE." ;
 
%LET C9MARTS = %SYSGET(ST_CNTY_C9MARTS);
libname INLIB "&C9MARTS./&RUNDATEN." ;
 
%LET ST_STAGING=%SYSGET(ST_CNTY_BASE);
Libname STGLIB "&ST_STAGING./staging/&RUNDATE.";
 
/*libname INLIB "/sasdata/hsbc/dil/.COLL/.G9/DEV/&ctry./Collections/staging/&RUNDATE.";*/
/*libname INLIB "&ST_STAGING./staging/&RUNDATE.";*/
 
/**************MACRO DEFINED TO LOCK THE MASTER LOOKUP TABLES DURING MASKING PROCESS*******************************/
 
%include "/sasdata/hsbc/dil/.COLL/.G9Strategic/PROD/ASP/Collections/saspgms/INC_Lock.inc";
 
/*****************************************************************************************/
 
/*options symbolgen mprint mlogic;*/
 
%macro MASKING_PROCESS(file_type=            /*F=flat file, D=SAS Dataset*/     ,
                        in_dataset=          /*Input SAS DATA Set file name*/     ,
                                    out_dataset=         /*Output SAS DATA Set name */     ,
                                                layout=              /*layout to read the flat file*/    ,
                                            account_number=      /*list of Account numbers to be anonymized*/ ,
                                    customer_number=     /*list of Customer numbers to be anonymized*/ ,
                                    phone_number=        /*list of Phone numbers to be anonymized*/ ,
                                    social_security=     /*list of Social Security numbers to be anonymized*/ ,
                                    customer_address=    /*list of Customer Addresses to be anonymized*/ ,
                                    );
 
 
 
%IF &file_type eq F %Then
  %do;
   data in_file;
    infile "&SRC_LANDING./&in_dataset.-&RUNDATE..dat" linesize=161 truncover firstobs=2 end=eof;
        %inc "&CYBER_LAYOUT./Cyber/&layout..inc";
        run;
  %end;
  %else
   %do;
     data in_file;
     set INLIB.&in_dataset./*(rename=(ACCT=ACCT_NBR))*/;
         run;
    %end;
 
/*******CREATING DATASET IN STRATEGIC STAGING AREA*************/
 
/*
data STGLIB.&in_dataset.;
set in_file;
run;
*/
 
data _null_;
        call symput('dataday',input("&rundate",yymmdd8.));
run;
 
%include "/sasdata/hsbc/dil/.COLL/.G9Strategic/PROD/ASP/Collections/saspgms/INC_mask.inc";
 
 
%mend;
 
/*-------------------------------------------------*/
/*  Master Macro Argument Definition               */
/*-------------------------------------------------*/
 
%MASKING_PROCESS(    file_type=D,
                     in_dataset=gcmmp,
                                 out_dataset=gcmmp,
                                 layout=none,
                                 account_number=ACCOUNT_NBR TRANSFER_ACCT USER_ACCT_NBR HI_REPAYMENT_ACCT_NUM ACH_ACCT_NBR DDA_ACCT_NBR,
                                 customer_number=CUSTOMER_NBR PRIM_CARD_NBR,
                                 phone_number=PHONE_RESERV_1 PHONE_RESERV_2 PHONE_RESERV_3 PHONE_RESERV_4 EMERGENCY_CONT_PHONE,
                                 social_security=CUST_SSN NATIONAL_ID,
                                 customer_address=CUST_NAME CUST_FIRST_NAME CUST_MDDLE_NAME CUST_LAST_NAME CUST_MAT_NAME CUST_SEC_NAME CUST_PRI_BUS_NAME CUST_FULL_NAME CUST_ADD_LINE_1      CUST_ADD_LINE_2 CUST_ADD_LINE_3 CUST_ADD_LINE_4 CUST_BUS_ADD_LINE_1 CUST_BUS_ADD_LINE_2 CUST_BUS_ADD_LINE_3 PC_CUST_MAT_NAME EMERGENCY_CONT_NAME EMERGENCY_CONT_ADDRESS EMERG_CONT_ADDR_2 EMERG_CONT_ADDR_CITY
                                );
 
C9_Process_CTA_GCMMP.ksh
 
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
 
Extract_CTA_GCMMP.ksh
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
 
Extract_CTA_VNM_GCMMP.sas
%LET CTRY = %SYSGET(CTRY);
%LET ST_SRC_LAND = %SYSGET(ST_SRC_LAND);
%LET ST_CNTY_STAGING = %SYSGET(ST_CNTY_STAGING);
%LET G9STRAT_BASE    = %SYSGET(G9STRAT_BASE);
%LET RUNDATE = %SYSGET(RUNDATE);
 
%put &RUNDATE;
 
 
data _null_;
  call symput('RUNDATEP',put(input("&rundate",yymmdd8.)-1,yymmddn8.));
run;
 
data _null_;
  call symput('RUNDATEN',put(input("&rundate",yymmdd8.)+1,yymmddn8.));
run;
 
%let exists_src = %sysfunc(fileexist("&ST_SRC_LAND./gcwmp_&RUNDATE..dat"));
%put &exists_src.;
 
libname stgp "&ST_CNTY_STAGING./&RUNDATEP.";
libname stg "&ST_CNTY_STAGING./&RUNDATE.";
libname stgn "&ST_CNTY_STAGING./&RUNDATEN.";
libname &ctry._ANA "/sasdata/hsbc/dil/.COLL/.G9/PROD/&CTRY./Collections/Analytics/sensitive/detailmart/&RUNDATEN.";
libname c9mart "/sasdata/hsbc/dil/.COLL/.G9Strategic/PROD/&CTRY./Collections/c9marts/&RUNDATEN.";
 
%macro extract_src;
 
%if &exists_src. = 1 %then %do;
%put *******extracting file...*******;
 
libname  stg  "&ST_CNTY_STAGING./&RUNDATE";
 
data stgn.GCMMP;
infile "&ST_SRC_LAND./gcwmp_&RUNDATE..dat" dlm='|' dsd missover ls=7370;
 
input
@1     APPLICATION     :2.
@4     ORGANIZATION    :3.
@8     ACCOUNT_NBR     :$19.
@28    LOGO    :3.
@32    COLL_ORG        :3.
@36    CUSTOMER_NBR    :$24.
@61    CUST_NAME       :$45.
@107   CUST_FIRST_NAME :$25.
@133   CUST_MDDLE_NAME :$25.
@159   CUST_LAST_NAME  :$35.
@195   CUST_MAT_NAME   :$35.
@231   CUST_PREFIX     :$4.
@236   CUST_SUFFIX     :$4.
@241   CUST_ADD_LINE_1 :$40.
@282   CUST_ADD_LINE_2 :$40.
@323   CUST_ADD_LINE_3 :$40.
@364   CUST_ADD_LINE_4 :$40.
@405   CUST_CITY       :$30.
@436   CUST_STATE      :$2.
@439   CUST_POST_CODE  :$9.
@449   CUST_COUNTY     :$30.
@480   CUST_ISO_COUNTRY_CODE   :$2.
@483   CUST_EMAIL      :$48.
@532   CUST_PRI_LANG_IND       :$2.
@535   CUST_SSN        :$9.
@545   CUST_DOB        :7.
@553   CUST_PRI_REL    :$1.
@555   CUST_PRI_ADDR_TYPE      :1.
@557   CUST_SEC_NAME   :$45.
@603   CUST_PRI_BUS_NAME       :$45.
@649   CUST_PRI_BUS_REL        :$1.
@651   CUST_PRI_BUS_ADD_TYPE   :1.
@653   CUST_BUS_ADD_LINE_1     :$35.
@689   CUST_BUS_ADD_LINE_2     :$35.
@725   CUST_BUS_ADD_LINE_3     :$35.
@761   CUST_BUS_CITY   :$30.
@792   CUST_BUS_STATE  :$2.
@795   CUST_BUS_POST_CODE      :$9.
@805   CUST_BUS_COUNTY :$30.
@836   CUST_BUS_ISO_CNTY_CDE   :$2.
@839   CUST_BUS_EMAIL  :$48.
@888   CUST_BUS_LANG_IND       :$2.
@891   PH_TYPE_1       :$1.
@893   PH_AVAIL_CDE_1  :$1.
@895   PH_AREA_CODE_1  :$3.
@899   PH_PREFIX_1     :$3.
@903   PH_SUFFIX_1     :$4.
@908   PH_EXT_1        :$10.
@919   PH_TYPE_2       :$1.
@921   PH_AVAIL_CDE_2  :$1.
@923   PH_AREA_CODE_2  :$3.
@927   PH_PREFIX_2     :$3.
@931   PH_SUFFIX_2     :$4.
@936   PH_EXT_2        :$10.
@947   PH_TYPE_3       :$1.
@949   PH_AVAIL_CDE_3  :$1.
@951   PH_AREA_CODE_3  :$3.
@955   PH_PREFIX_3     :$3.
@959   PH_SUFFIX_3     :$4.
@964   PH_EXT_3        :$10.
@975   PH_TYPE_4       :$1.
@977   PH_AVAIL_CDE_4  :$1.
@979   PH_AREA_CODE_4  :$3.
@983   PH_PREFIX_4     :$3.
@987   PH_SUFFIX_4     :$4.
@992   PH_EXT_4        :$10.
@1003  CUST_ID_TYPE    :$1.
@1005  CUST_ID_NBR     :$25.
@1031  CUST_PIB_NBR    :$19.
@1051  AMT_CREDIT_LIMIT        :18.
@1070  AMT_TOT_BAL     :18.
@1089  AMT_OVERLIMIT   :18.
@1108  AMT_DISPUTE     :18.
@1127  AMT_TOT_DUE     :18.
@1146  AMT_CUR_DUE     :18.
@1165  AMT_TOT_DELQ    :18.
@1184  AMT_LAST_PYMT   :18.
@1203  AMT_CHARGE_OFF  :18.
@1222  AMT_LAST_MONETARY       :18.
@1241  AMT_INT_LATE_CHARGE     :18.
@1260  AMT_DELQ_AGE_1  :18.
@1279  AMT_DELQ_AGE_2  :18.
@1298  AMT_DELQ_AGE_3  :18.
@1317  AMT_DELQ_AGE_4  :18.
@1336  AMT_DELQ_AGE_5  :18.
@1355  AMT_DELQ_AGE_6  :18.
@1374  AMT_DELQ_AGE_7  :18.
@1393  AMT_DELQ_AGE_8  :18.
@1412  AMT_COMMTT_FEE  :18.
@1431  AMT_TOT_OD_INT  :18.
@1450  AMT_OVRALL_CRLIM        :18.
@1469  DTE_CREDIT_LIMIT        :7.
@1477  DTE_CARD_EXPIRE :7.
@1485  DTE_CHARGE_OFF  :7.
@1493  DTE_ACCT_OPEN   :7.
@1501  DTE_WARN_BULLETIN       :7.
@1509  DTE_LAST_PYMT   :7.
@1517  DTE_CUST_SINCE  :7.
@1525  DTE_LAST_MONETARY       :7.
@1533  DTE_CR_CHG      :7.
@1541  DTE_SEC_VALUE   :7.
@1549  DTE_OD_SINCE    :7.
@1557  DTE_FCLTY_RVW   :7.
@1565  DTE_COMMITTE    :7.
@1573  AGE_HISTORY     :$12.
@1586  CNT_CYCLES_DELQ :3.
@1590  CYCLE   :2.
@1593  NBR_OF_CARDS    :$2.
@1596  NBR_OF_HUB_ACCTS        :2.
@1599  NBR_DAYS_DLQ    :3.
@1603  WARN_BULLETIN_ZONE      :$4.
@1608  SCORE_CREDIT    :$5.
@1614  SCORE_BEHAV     :$4.
@1619  TYPE_LAST_MONETARY      :$2.
@1622  CODE_VALUE      :$2.
@1625  CODE_RISK       :$2.
@1628  CODE_MRKT_SECTOR        :$5.
@1634  CODE_CO_REASON  :$2.
@1637  CODE_FCLT_CATGY :$3.
@1641  CODE_MORT_INS   :$2.
@1644  CODE_NATIONAL   :$2.
@1647  IND_INT_ONLY    :$1.
@1649  IND_GMIS_USER   :$2.
@1652  IND_OTHR_ADV    :$1.
@1654  IND_TNGBLE_SEC  :$1.
@1656  IND_ISLAMIC_PROD        :$1.
@1658  CODE_GHO_CLASS  :$3.
@1662  IND_CRDT_GRDE   :$1.
@1664  IND_RESTRICTION :$1.
@1666  IND_STATUS_CDE  :$1.
@1668  NBR_INST_OD     :2.
@1671  TRANSFER_ACCT   :$19.
@1691  AMT_BAL_LDGR    :18.
@1710  IND_HLD :$1.
@1712  USER_ACCT_NBR   :$19.
@1732  HUB_EXT_NBR     :$34.
@1767  AMT_REPO_CHARGE :18.
@1786  AMT_PYMT        :18.
@1805  AMT_PRINCIPAL_DELQ      :18.
@1824  AMT_INTEREST_DELQ       :18.
@1843  AMT_PRINCIPAL   :18.
@1862  AMT_ORIG_BALANCE        :18.
@1881  DTE_NEXT_DUE    :7.
@1889  DTE_REPO        :7.
@1897  DTE_MATURITY    :7.
@1905  DTE_REFINANCE   :7.
@1913  DTE_LAST_BILLING        :7.
@1921  DTE_RESCHDLE    :7.
@1929  NBR_OFFICER     :$6.
@1936  NBR_BRANCH      :$6.
@1943  NBR_DEALER      :$6.
@1950  ORIG_TERM       :$4.
@1955  RATE_ORIG_INT   :7.
@1963  RATE_INTEREST   :7.
@1971  RATE_LN_TO_VALUE        :7.
@1979  FREQ_PYMT       :$2.
@1982  IND_DEPOSIT     :$1.
@1984  IND_ON_BUDGET   :$1.
@1986  IND_DPA :$1.
@1988  CODE_CUT_OFF    :$3.
@1992  TYPE_ACCT       :$3.
@1996  TYPE_SERVICE    :$3.
@2000  AMT_BUDGET_PYMT :18.
@2019  AMT_TERMINATION :18.
@2038  DTE_CUT_OFF     :7.
@2046  DTE_TERM_EXPIRE :7.
@2054  NBR_ACLS_BANK   :5.
@2060  CODE_ACLS_APP   :3.
@2064  AMT_EST_MONTH_PYMT      :18.
@2083  IND_ACI :$1.
@2085  SERVICING_SYSTEM        :$8.
@2094  CURR_NATL       :$3.
@2098  CURR_BASE       :$3.
@2102  CURR_PREF       :$3.
@2106  FI_ACTION_IND   :$3.
@2110  FI_LETTER_IND   :$3.
@2114  FI_CONTRL_IND   :$1.
@2116  FI_COLL_STRATEGY_ID     :$3.
@2120  FI_COLL_SCENARIO_ID     :$3.
@2124  FI_SPID :$3.
@2128  FI_RETURNED_COLL_LTR    :$5.
@2134  FI_SPECIL_HNDLNG_IND    :$2.
@2137  FI_COLLECTION_IND       :$3.
@2141  AMT_BAL_AT_RISK :18.
@2160  BLOCK_CODE_1    :$1.
@2162  BLOCK_CODE_2    :$1.
@2164  DTE_BLK_CDE_1   :7.
@2172  DTE_BLK_CDE_2   :7.
@2180  DTE_INTO_COLL   :7.
@2188  REL_BILLING_LVL :$1.
@2190  NBR_MONTHS_OPEN :3.
@2194  AMT_USER_1      :18.
@2213  AMT_USER_2      :18.
@2232  AMT_USER_3      :18.
@2251  AMT_USER_4      :18.
@2270  AMT_USER_5      :18.
@2289  AMT_USER_6      :18.
@2308  AMT_USER_7      :18.
@2327  AMT_USER_8      :18.
@2346  AMT_USER_9      :18.
@2365  AMT_USER_10     :18.
@2384  DTE_USER_1      :7.
@2392  DTE_USER_2      :7.
@2400  DTE_USER_3      :7.
@2408  DTE_USER_4      :7.
@2416  DTE_USER_5      :7.
@2424  DTE_USER_6      :7.
@2432  DTE_USER_7      :7.
@2440  DTE_USER_8      :7.
@2448  DTE_USER_9      :7.
@2456  DTE_USER_10     :7.
@2464  IND_USER_1      :$2.
@2467  IND_USER_2      :$2.
@2470  IND_USER_3      :$2.
@2473  IND_USER_4      :$2.
@2476  IND_USER_5      :$2.
@2479  IND_USER_6      :$2.
@2482  IND_USER_7      :$2.
@2485  IND_USER_8      :$2.
@2488  IND_USER_9      :$2.
@2491  FLAG_FPD        :$1.
@2493  IND_RESCHEDULE_DEBT     :$2.
@2496  DTE_LAST_MAINT  :7.
@2504  UID_LAST_MAINT  :$3.
@2508  AUTO_SOLD_REPO  :$2.
@2511  EMPLOYER        :$35.
@2547  NATIONALITY     :$3.
@2551  CUST_PROFESSION :$42.
@2594  PHONE_RESERV_1  :$1.
@2596  PHONE_RESERV_2  :$1.
@2598  PHONE_RESERV_3  :$1.
@2600  PHONE_RESERV_4  :$1.
@2602  EMPLOYMENT_STATUS       :$1.
@2604  USER_FILLER     :$133.
@2738  HI_ISO_LANG_CODE        :$3.
@2742  HI_IND_EXCLUSION        :$1.
@2744  FILLER_1        :$1604.
@4349  HI_REPAYMENT_ACCT_NUM   :$19.
@4369  HI_OUTSTANDING_BAL      :18.
@4388  HI_OVERDUE_AMT  :18.
@4407  FILLER_2        :$329.
@4737  FILLER_3        :$1.
@4739  FILLER_4        :$3.
@4743  HI_HIST_REAGE_TYPE      :$1.
@4745  HI_NUM_OF_REAGE_X_YRS   :3.
@4749  HI_MNTH_SNC_LST_REAGE   :3.
@4753  HI_HIGHEST_DELQ_LEV     :2.
@4756  HI_LTR_DELV_PREF_FLAG   :$1.
@4758  NEW_RESTRUCTURE_ACCT    :$1.
@4760  SATISFICATION_FLAG      :$1.
@4762  BU_CORPORATE_ID :$10.
@4773  AGED_HISTORY    :$24.
@4798  PMT_PAST_DUE    :18.
@4817  HI_DESC_PRODUCT :$40.
@4858  HI_CHGOFF_STATUS        :1.
@4860  HI_POTEN_CHGOFF_DTE     :7.
@4868  HI_BUS_SECTOR_CODE      :$1.
@4870  NBR_TIMES_IN_COLL       :3.
@4874  PMT_XDAYS_CTR   :$4.
@4879  PMT_30DAYS_CTR  :$4.
@4884  PMT_60DAYS_CTR  :$4.
@4889  PMT_90DAYS_CTR  :$4.
@4894  PMT_120DAYS_CTR :$4.
@4899  PMT_150DAYS_CTR :$4.
@4904  PMT_180DAYS_CTR :$4.
@4909  PMT_210DAYS_CTR :$4.
@4914  HI_DAYS_SINCE_OVLM      :$3.
@4918  BU_FLAG3_1      :$3.
@4922  DATE_LAST_REAGE :7.
@4930  DATE_LAST_RTN_CHECK     :7.
@4938  LAST_CASH_ADV_AMT       :18.
@4957  TYPE_OF_CARD    :4.
@4962  DTE_LAST_EXPIRY :7.
@4970  LAST_DTE_OVLM   :7.
@4978  FIRST_MISS_PMT_DATE     :7.
@4986  LAST_MISS_PMT_DATE      :7.
@4994  BU_DATE_12      :7.
@5002  BU_PERCENT_1    :$9.
@5012  BU_TEXT15_1     :$15.
@5028  MIN_PYMNT_AMT   :18.
@5047  HI_ACH_STMT_BAL :18.
@5066  HI_AMT_INTEREST :18.
@5085  AMT_LATE_CHARGES        :18.
@5104  YTD_OVLM_CHG    :18.
@5123  AMT_YTD_MEMB_FEES       :18.
@5142  CARD_FEE_DUE_DTE        :$7.
@5150  AMT_LAST_YTD_INT        :7.
@5158  PRIM_CARD_NBR   :$19.
@5178  DDA_ACCT_NBR    :$19.
@5198  DIRECT_DEBIT_FLAG       :$1.
@5200  CHGOFF_RSN      :$2.
@5203  DATE_INTO_COLL  :7.
@5211  NBR_NSF :5.
@5217  CTA_ORG :3.
@5221  MONTHS_OPEN     :3.
@5225  OVERLIMIT_PCT   :3.
@5229  CUST_LEVEL_CREDIT_LIMIT :18.
@5248  CUST_LVL_OUTSTNDNG_AMT  :18.
@5267  CUST_LVL_OVRLMT_AMT     :18.
@5286  USER_CODE_25    :$2.
@5289  USER_CODE_START_DATE    :7.
@5297  USER_CODE_END_DATE      :7.
@5305  BAD_AND_DOUBT_STATUS    :1.
@5307  DATE_LAST_MAINT :7.
@5315  OPEN_TO_BUY     :18.
@5334  INSURANCE_SW    :$1.
@5336  CASH_BALANCE    :18.
@5355  CASH_CRLIM      :18.
@5374  CASH_AVAIL_CREDIT       :18.
@5393  LOAN_CRLIM      :18.
@5412  LOAN_AVAIL      :18.
@5431  LOAN_BALANCE    :18.
@5450  FIRST_DTE_OVLM  :7.
@5458  TOT_LOYALTY_POINTS      :9.
@5468  NATIONAL_ID     :$30.
@5499  PC_CUST_MAT_NAME        :$40.
@5540  STATEMENT_FLAG  :$1.
@5542  LAST_NSF_DATE   :7.
@5550  ACCOUNT_TYPE    :$3.
@5554  ACCT_AGE_IN_MONTHS      :$3.
@5558  VIP_STATUS      :1.
@5560  INT_STATUS      :$1.
@5562  DATE_LAST_STAT_CHG      :7.
@5570  PC_NBR_OF_CARDS :$3.
@5574  SSN_INDICATOR   :1.
@5576  BUSINESS_ADD1   :$40.
@5617  BUSINESS_ADD2   :$40.
@5658  MARITAL_STATUS  :$1.
@5660  GENDER  :$1.
@5662  EMPLOYEE_CODE   :$2.
@5665  INCOME  :18.
@5684  EMERGENCY_CONT_NAME     :$20.
@5705  EMERGENCY_CONT_PHONE    :$20.
@5726  EMERGENCY_CONT_ADDRESS  :$40.
@5767  EMERG_CONT_ADDR_2       :$40.
@5808  EMERG_CONT_ADDR_CITY    :$20.
@5829  EMERG_CONT_ADDR_CNTY    :$2.
@5832  CARD_STATUS     :$1.
@5834  CREDIT_GRADE    :$2.
@5837  OVERLIMIT_FLAG  :$1.
@5839  CHGOFF_STATUS   :$1.
@5841  TRIAD_COLL_IND  :$3.
@5845  CREDIT_SCORE    :$5.
@5851  NBR_PAY_SINCE_ENTRY     :3.
@5855  PRIOR_CREDIT_LIMIT      :18.
@5874  FEE_CHG_PORTION :18.
@5893  ORIG_INSTAL_AMT :18.
@5912  DATE_ACCT_CLOSED        :7.
@5920  CURR_BAD_DEBT_DATE      :7.
@5928  LAST_DELQ_DATE  :7.
@5936  PRESENT_BALANCE_AMT     :18.
@5955  ACH_ACCT_NBR    :$19.
@5975  CR_CLASS        :$2.
@5978  HI_BU_FILLER    :$94.
@6073  CUST_FULL_NAME  :$90.
@6164  HI_REGN_FILLER  :$10.
;
 
 
run;
 
 
%end;
 
%else %do;
        %put ******Files does not exist, non batch day...continuing batch....copying previous day file****** ;
        data stgn.GCMMP;
        set stg.GCMMP;
        run;
%end;
 
%mend;
 
%Extract_src;
 
data c9mart.GCMMP;
set stgn.GCMMP;
run;
 
data &ctry._ANA.GCMMP ;
set stgn.GCMMP (keep= IND_USER: account_nbr CUSTOMER_NBR COLL_ORG ORGANIZATION) ;
run;
 
 
INC_Lock.inc
 
options symbolgen mprint mlogic;
 
%macro q_trylock(member=, timeout=,retry=);
   %local starttime;
   %let starttime = %sysfunc(datetime());
   %do %until (&syslckrc = 0 or %sysevalf(%sysfunc(datetime())  (&starttime + &timeout)));
      %put trying to open ...;
      %put trying lock ...;
      lock &member;
      %if &syslckrc ne 0 %then %let rc=%sysfunc(sleep(60));
      %if &syslckrc ne 0 %then %do;
         sleep(60);
         data _null_;
                  slept=sleep(60,1);
         run;
           %end;
           %put syslckrc=&syslckrc;
   %end;
%mend q_trylock;
 
 
INC_make_file.inc
 
 
%macro makefile
  (
   dataset= ,  /* Dataset to write */
   filepath=,  /* File to write to */
   dlmr="}"       ,  /* Delimiter between values */
   qtes="no"      ,  /* Should SAS quote all character variables? */
   header="no"    ,  /* Do you want a header line w/ column names? */
   label="no"        /* Should labels be used instead of var names in header? */
  );
 
 
%let flname=&dataset.;
%include "/sasdata/hsbc/dil/.COLL/.G9Strategic/PROD/ASP/Collections/saspgms/INC_Metadata_Check.inc";
 
proc contents data=src.&dataset out=___out_;
run;
 
/*PA - 121022 Added to update BEST32. format on Numeric variables*/
 
data ___out__;
set ___out_;
where type=1 and format eq '';
/*call symputx('numvarcnt',_n_);*/
run;
 
 
proc sql;
select count(*) into: numvarcnt from ___out__;
quit;
 
 
%if &numvarcnt ge 1 %then %do;
 
proc sql;
select name into:num_var separated by ' '  from ___out_ where type=1 and format eq '';
quit;
%put &num_var.;
 
 
data src.&dataset;
set src.&dataset;
format  &num_var. BEST32.;
run;
 
%end;
 
/*PA - END here*/
 
/* Return to orig order */
 
proc contents data=src.&dataset out=___out_;
run;
 
/* Return to orig order */
 
proc sort data=___out_;
  by varnum;
run;
 
/* Build list of variable names */
 
data _null_;
  set ___out_ nobs=count;
  call symput("name"!!left(_n_),trim(left(name)));
  call symput("type"!!left(_n_),trim(left(type)));
 
  /* Use var name when label not present */
  /*if label=" " then label=name;       */
  call symput("lbl"!!left(_n_),trim(left(name)));
  if _n_=1 then call symput("numvars", trim(left(put(count, best.))));
  if _n_ =1 then call symput("numobs", trim(left(put(NOBS,best.))));
run;
 
/* Create file */
 
data _null_;
  %if %eval( &numobs >0) %then %do; set src.&dataset ; %end;
  file "&filepath./&dataset..txt" DSD lrecl=15000;
  %global temp;
  %if &qtes="yes" %then %let temp='"';
  %else %let temp=' ';
  %if &header="yes" %then %do;
 
    /* Conditionally add column names */
     if (  _n_=1  or  &numobs = 0 ) then do;
        put %if &label="yes" %then %do;
        %do i=1 %to &numvars-1;
          &temp  "%trim(%bquote(&&lbl&i)) " +(-1) &temp &dlmr
          %end;
        &temp "%trim(%bquote(&&lbl&numvars)) " &temp;
        %end;
    %else %do;
      %do i=1 %to &numvars-1;
        &temp "%trim(&&name&i) " +(-1) &temp &dlmr
        %end;
       &temp "%trim(&&name&numvars) " &temp ;
       %end;
    ;
    end;
  %end;
 
  /* Build PUT stmt to write values */
   %if %eval(&numobs > 0) %then
%do;
  put
     %do i = 1 %to &numvars -1;
       %if &&type&i ne 1 and &qtes="yes" %then %do;
         '"' &&name&i +(-1) '"' &dlmr
         %end;
       %else %do;
         &&name&i +(-1) &dlmr
         %end;
     %end;
     %if &&type&i ne 1 and &qtes="yes" %then %do;
 
       /* Write last varname */
       '"' &&name&numvars +(-1) '"';
       %end;
       %else %do;
 
         /* Write last varname */
         &&name&numvars;
       %end;
            %end;
  run;
 
/*Added below for creating control file*/
proc contents data =src.&dataset out=_ctl_out_;
run;
 
proc sort data=_ctl_out_;
by VARNUM;
run;
 
data _null_;
set _ctl_out_;
call symputx('nvar1',varnum);
call symputx('nobs1',nobs);
run;
 
%put &nobs1.;
%put &nvar1.;
 
data _null_;
file "&filepath./&dataset..ctl";
put "&rundate." '|' "&nobs1." '|' "&nvar1.";
run;
 
 
%mend makefile;
 
 
INC_makefile_VNM_GCMMP.sas
 
 
%LET RUNDATE = %SYSGET(RUNDATE);
%put &RUNDATE;
%LET RUNYYMM = %SYSGET(RUNYYMM);
%put &RUNYYMM;
%LET CTRY = %SYSGET(CTRY);
%put &CTRY;
%LET ENVIRONMENT = %SYSGET(ENVIRONMENT);
%PUT &ENVIRONMENT;
%LET ST_INGEST=%SYSGET(ST_CNTY_INGEST);
%LET Source = gcmmp;
%put &Source;
 
 
%macro Main_Program;
 
libname src "&ST_INGEST./nonsensitive/&RUNDATE." ;
%include "/sasdata/hsbc/dil/.COLL/.G9Strategic/&ENVIRONMENT./ASP/Collections/saspgms/INC_make_file.inc";
 
/* detail user marts */
%makefile(dataset=&Source.,         filepath=&ST_INGEST./filetrf/&RUNDATE.);
 
%mend;
 
%Main_Program;
 
INC_Metadata_Check.inc
%macro meta_val(ctry,flname);
 
%let ctry=%upcase(&ctry.);
%let flname=%upcase(&flname.);
 
data _ref_;
infile "/sasdata/hsbc/dil/.COLL/.G9Strategic/PROD/ASP/Collections/layouts_cdp47/&ctry._&flname..csv"
       LRECL=10000
       dlm = ","
       FIRSTOBS=2
       DSD MISSOVER;
 
input
varnum : 8.
memname : $Char50.
name :  $Char50.
update_date : $Char50.
;
run;
 
proc sort data=_ref_;
by varnum;
run;
 
/*libname ns "/sasdata/hsbc/dil/.COLL/.G9Strategic/PROD/&ctry./Collections/ingestion/nonsensitive/&rundate.";*/
/*SRC library defined in make file code*/
 
proc contents data=src.&flname. out=_outds_ varnum;
run;
 
proc sort data=_outds_(keep=memname name varnum);
by varnum;
run;
 
proc sql;
select count(*) into : ref_cnt from _ref_;
quit;
 
proc sql;
select count(*) into : out_cnt from _outds_;
quit;
 
proc sql;
create table mt_val as
select a.varnum as ref_num, a.memname as ref_memname, a.name as ref_name, b.name as out_name,
case when ref_name = out_name then 0 else 1 end as flag
from _ref_ a
left join _outds_ b on a.varnum=b.varnum and a.memname=b.memname;
quit;
 
proc sql;
select sum(flag) into : mismatch_cnt from mt_val;
quit;
 
%if %eval(&ref_cnt. ne &out_cnt.) or %eval(&mismatch_cnt. ge 1) %then %do;
%put "Metadata Mismatch for &ctry. &flname., Please check";
%abort;
%end;
%else %do;
%put "Metadata Validation Passed for &ctry. &flname.";
%end;
 
%mend;
 
%meta_val(&ctry.,&flname.);
 
 
st_cnty_vars.ksh
 
#!/bin/ksh
#. $(dirname $0)/st_vars.ksh
#. $(dirname $0)/st_funcs.ksh
set -x
if [ $# -ge 1 ] ; then
export CNTY=$1
else
echo " ********** No Country Parameter Provided for SDR Process **************"
echo " ********** No Country Parameter Provided for SDR Process **************"
echo " ********** No Country Parameter Provided for SDR Process **************"
exit 1
fi
 
#logstart
export JOBNAME_PARM1=`basename $0`
export JOBNAME_PARM=${JOBNAME_PARM1}_${CNTY}_
export PROG=ST_SDR_CNTY_LIST
sasbatch $ST_SASPGM $PROG ${JOBNAME_PARM}
retcode=$?
if [ $retcode -le 1 ]; then
   echo " Built the countries to execute ............"
   rm $ST_LOGS/$SASLOG
    continue
else
  echo "Cannot determine the countries for the batch"
#  logend 11
  exit 1
fi
 
export GA_SDR_BASE=/sasdata/hsbc/dil/.COLL/.G9/PROD/$CNTY/Collections
export GA_SDR_SEN_DET=${GA_SDR_BASE}/Analytics/sensitive/detailmart
export GA_SDR_NSEN_DET=${GA_SDR_BASE}/Analytics/nonsensitive/detailmart
export GA_SDR_NSEN_SUMMART=${GA_SDR_BASE}/Analytics/nonsensitive/summart
export GA_SDR_STAGING=/sasdata/hsbc/dil/.COLL/.G9/PROD/$CNTY/Collections/staging
export GA_SDR_DIM=/sasdata/hsbc/dil/.COLL/.G9/PROD/ASP/Collections/dimensions
 
export ST_CNTY_BASE=/sasdata/hsbc/dil/.COLL/.G9Strategic/${ENVIRONMENT}/$CNTY/Collections
export ST_CNTY_LOGS=$ST_CNTY_BASE/logs
export ST_CNTY_OPATH=$ST_CNTY_BASE/staging
export ST_CNTY_STAGING=$ST_CNTY_BASE/staging
export ST_CNTY_LANDING=$ST_CNTY_BASE/landing
export ST_CNTY_WORK=$ST_CNTY_BASE/work
export ST_CNTY_KEYGEN=$ST_CNTY_BASE/keygen
export ST_CNTY_SEQFILE=$ST_CNTY_BASE/seqfile
export ST_CNTY_SASLIST=$ST_CNTY_BASE/saslist
export ST_CNTY_SASMART_DETAIL=$ST_CNTY_BASE/detailmart
export ST_CNTY_C9MARTS=${ST_CNTY_BASE}/c9marts
export ST_CNTY_INGEST=${ST_CNTY_BASE}/ingestion
export ST_CNTY_FLTRF=${ST_CNTY_INGEST}/filetrf
export ST_CNTY_NSING=${ST_CNTY_INGEST}/nonsensitive
export ST_CNTY_SEN_DET=${ST_CNTY_BASE}/Analytics/sensitive/detailmart
export ST_CNTY_NSEN_DET=${ST_CNTY_BASE}/Analytics/nonsensitive/detailmart
export ST_CNTY_NSEN_SUMMART=${ST_CNTY_BASE}/Analytics/nonsensitive/summart
export ST_CNTY_ING_DET=${ST_CNTY_BASE}/ingestion/nonsensitive/detailmart
export ST_CNTY_ING_SUMMART=${ST_CNTY_BASE}/ingestion/nonsensitive/summart
export ST_CNTY_DIM=$ST_CNTY_BASE/dimensions
export ST_SRC_LAND=/sasdata/hsbc/landing/.G9Strategic/${ENVIRONMENT}/$CNTY
 
echo $ST_CNTY_BASE
 
if [ $# -ge 2 ]; then
  for last; do true; done
  export cutlast=`echo $last | cut -c1-3`
  if [ $cutlast == 201 ] ;then
   export ST_CNTY_WORK=$ST_CNTY_BASE/work/backwork
  fi
  echo $ST_CNTY_WORK
fi
 
 
st_funcs.ksh
 
#!/bin/ksh
#set -vx
logit() {
#!   print "$(date +%c) $(basename $0 .ksh) $*" >> $ST_LOG_FILE
print "$(date +%c)  $(basename $0 .ksh)_${CNTY} $RUNDATE $*" >> $ST_LOG_FILE
}
 
 
logstart() {
    logit Starting ...
}
 
logend() {
    if [ $# -eq 0 ]; then
        logit Completed normally.
    else
      logit ERROR termination with rc=$1
    fi
}
 
sasbatch()
{
export DIR=$1
export PGM=$2
export FLAG=$3
export SASLOG="${PGM}_${FLAG}${CNTY}_${RUNDATE}${CURTIME}.log"
sleep $((RANDOM%60+1))
 
 
SASRC=`/sasdata/sas/util/sasgsub -gridwork /sasdata/sas/gsub_log  -gridruncmd "(${SAS} ${DIR}/$PGM -log $ST_LOGS/$SASLOG -print ${ST_SASLIST}/${PGM}"_"${FLAG}${CNTY}_${RUNDATE}${CURTIME}.lst )" -gridwait`
 
#debug
echo $SASRC
 
#Get the path of log directory
SASRC=`echo $SASRC | grep 'Job directory' | cut -d '"' -f 2`
echo $SASRC
 
SASRC=`cat $SASRC/time.end.* | cut -d '=' -f 2`
echo $SASRC
 
#Return the “return code of sas job”
#retcode=$?
loginfo="$PGM","$SASLOG","$FLAG","$RUNDATE"
echo $loginfo >> $ST_WORK/logsas_$RUNDATE.txt
return  $SASRC
#exit $SASRC
 
 
#retcode=$?
#loginfo="$PGM","$SASLOG","$FLAG","$RUNDATE"
#echo $loginfo >> $ST_WORK/logsas_$RUNDATE.txt
#return  $retcode
}
 
 
get_prev_date()
{
export YEST=`perl -e 'print localtime(time() - 86400) . "\n"' | awk '{print $5 $2 $3}'`
export YYYY=`echo $YEST | cut -c 1-4`
export MON=`echo $YEST | cut -c 5-7`
export DD=`echo $YEST | cut -c 8-9`
if [ $DD -gt 9 ]; then
DD=$DD
else
DD="0"$DD
fi
set -A MONTHS Null Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
export i=0
while (( i <= 12 ));
do
if [ ${MONTHS[i]} = ${MON} ]; then
export FORMATTED_YEST
if [ ${i} -gt 9 ]; then
FORMATTED_YEST=$YYYY$i$DD
print $FORMATTED_YEST
else
FORMATTED_YEST=${YYYY}"0"$i$DD
print $FORMATTED_YEST
fi
fi
i=$(($i+1))
done
}
get_req_date()
{
export DATE_TIME=`expr $1 \* 86400`
export REQ_DATE=`perl -e 'print localtime(time() - '${DATE_TIME}') . "\n"' | awk '{print $5 $2 $3}'`
export REQ_YYYY=`echo $REQ_DATE | cut -c 1-4`
export REQ_MON=`echo $REQ_DATE | cut -c 5-7`
export REQ_DD=`echo $REQ_DATE | cut -c 8-9`
if [ $REQ_DD -gt 9 ]; then
REQ_DD=$REQ_DD
else
REQ_DD="0"$REQ_DD
fi
set -A MONTHS Null Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
export i=0
while (( i <= 12 ));
do
if [ ${MONTHS[i]} = ${REQ_MON} ]; then
export FORMATTED_YEST
if [ ${i} -gt 9 ]; then
FORMATTED_YEST=$REQ_YYYY$i$REQ_DD
print $FORMATTED_YEST
else
FORMATTED_YEST=${REQ_YYYY}"0"$i$REQ_DD
print $FORMATTED_YEST
fi
fi
i=$(($i+1))
done
}
 
grab_all_files()
{
export file_names=""
curdir=`pwd`
for f in `find . -follow -name "$1*" -print | grep $1`
do
newf=`echo $f | sed -e 's/\.\///g'`
file_names=$file_names"'"$curdir/$newf"'"
done
echo $file_names
}
 
grab_all_sas_marts()
{
export pattern=`echo $1 | tr [A-Z] [a-z]`
export file_names=""
curdir=`pwd`
for f in `find . -follow -name "${pattern}*.sas7bdat"  -print | grep $pattern`
do
newf=`echo $f | sed -e 's/\.\///g'`
file_names=$file_names"'"$curdir/$newf"' "
done
echo $file_names
}
get_prior_mths()
{
export P=$1
PMOD=$(( $P  % 12 ))
Y=$(( $P / 12 ))
export NEW=$(($RUNMM-$PMOD))
case $NEW in
-6 )
Y=$(($Y+1))
NEWMM=6
NEWYY=$(($RUNYYYY-$Y))
;;
-7 )
Y=$(($Y+1))
NEWMM=5
NEWYY=$(($RUNYYYY-$Y))
;;
-8 )
Y=$(($Y+1))
NEWMM=4
NEWYY=$(($RUNYYYY-$Y))
;;
-9 )
Y=$(($Y+1))
NEWMM=3
NEWYY=$(($RUNYYYY-$Y))
;;
-10 )
Y=$(($Y+1))
NEWMM=2
NEWYY=$(($RUNYYYY-$Y))
;;
-5 )
Y=$(($Y+1))
NEWMM=7
NEWYY=$(($RUNYYYY-$Y))
;;
-4 )
Y=$(($Y+1))
NEWMM=8
NEWYY=$(($RUNYYYY-$Y))
;;
-3 )
Y=$(($Y+1))
NEWMM=9
NEWYY=$(($RUNYYYY-$Y))
;;
-2 )
Y=$(($Y+1))
NEWMM=10
NEWYY=$(($RUNYYYY-$Y))
;;
-1 )
Y=$(($Y+1))
NEWMM=11
NEWYY=$(($RUNYYYY-$Y))
;;
0 )
Y=$(($Y+1))
NEWMM=12
NEWYY=$(($RUNYYYY-$Y))
;;
*)
NEWMM=$NEW
NEWYY=$(($RUNYYYY-$Y))
esac
if [ $NEWMM -le 9 ]; then
NEWMM="0"$NEWMM
fi
export NEWYYMM=$NEWYY$NEWMM
echo $NEWYYMM
 
}
 
 
getrunmth()
{
export RUNMTH
case $RUNMM in
01 )
RUNMTH=Jan
;;
02 )
RUNMTH=Feb
;;
03 )
RUNMTH=Mar
;;
04 )
RUNMTH=Apr
;;
05 )
RUNMTH=May
;;
06 )
RUNMTH=Jun
;;
07 )
RUNMTH=Jul
;;
08 )
RUNMTH=Aug
;;
09 )
RUNMTH=Sep
;;
10 )
RUNMTH=Oct
;;
11 )
RUNMTH=Nov
;;
12 )
RUNMTH=Dec
;;
esac
echo $RUNMTH
}
 
rundate_minus_1()
{
RUNDT=$1
export RUNYYYY=`echo $RUNDT | cut -c1-4`
export RUNYY=`echo $RUNDT | cut -c3-4`
export RUNMM=`echo $RUNDT | cut -c5-6`
export RUNDD=`echo $RUNDT | cut -c7-8`
NEWDD=$(($RUNDD-1))
if [ $NEWDD -eq 0 ]; then
case $RUNMM in
01 )
NEWYY=$(($RUNYYYY-1))
NEWMM=12
NEWDD=31
;;
03 )
NEWMM=02
if [ $RUNYYYY%4 -eq 0 ]; then
NEWDD=29
else
NEWDD=28
fi
NEWYY=$RUNYYYY
;;
02|04|06|09|11)
NEWMM=$(($RUNMM-1))
if [ $NEWMM -le 9 ]; then
NEWMM="0"$NEWMM
fi
NEWDD=31
NEWYY=$RUNYYYY
;;
05|07|08|10|12 )
NEWMM=$(($RUNMM-1))
if [ $NEWMM -le 9 ]; then
NEWMM="0"$NEWMM
fi
NEWDD=30
NEWYY=$RUNYYYY
;;
esac
echo $NEWYY$NEWMM$NEWDD
else
if [ $NEWDD -le 9 ]; then
NEWDD="0"$NEWDD
fi
echo $RUNYYYY$RUNMM$NEWDD
fi
}
 
rundate_plus_1()
{
RUNDT=$1
export RUNYYYY=`echo $RUNDT | cut -c1-4`
export RUNYY=`echo $RUNDT | cut -c3-4`
export RUNMM=`echo $RUNDT | cut -c5-6`
export RUNDD=`echo $RUNDT | cut -c7-8`
typeset -i NEWMM
typeset -i NEWDD
NEWDD=$(($RUNDD+1))
NEWMM=$RUNMM
NEWYY=$RUNYYYY
case $RUNMM in
01|03|05|07|08|10 )
if [ $NEWDD -eq 32 ]; then
NEWDD='01'
NEWMM=$(($RUNMM+1))
fi
;;
04|06|09|11 )
if [ $NEWDD -eq 31 ]; then
NEWDD='01'
NEWMM=$(($RUNMM+1))
fi
;;
12 )
if [ $NEWDD -eq 32 ]; then
NEWDD='01'
NEWYY=$(($RUNYYYY+1))
NEWMM='01'
fi
;;
02)
if [ $RUNYYYY%4 -eq 0 ]; then
if [ $NEWDD -eq 30 ]; then
NEWDD='01'
NEWMM=$(($RUNMM+1))
fi
else
if [ $NEWDD -eq 29 ]; then
NEWDD='01'
NEWMM=$(($RUNMM+1))
fi
fi
;;
esac
 
 
if [ $NEWMM -le 9 ]; then
CNEWMM="0"$NEWMM
else
CNEWMM=$NEWMM
fi
if [ $NEWDD -le 9 ]; then
CNEWDD="0"$NEWDD
else
CNEWDD=$NEWDD
fi
echo $NEWYY$CNEWMM$CNEWDD
}
 
 
grab_sas_marts_for_x_mths()
{
yyyymm24=`get_prior_mths 24`
export pattern=`echo $1 | tr [A-Z] [a-z]`
i=0
export file_names=""
until [[ $i -gt 24  ]];do
MTHYYMM=`get_prior_mths $i`
MTHYYMMint=MTHYYMM
yyyymm24int=yyyymm24
typeset -i MTHYYMMint yyyymm24int
if [ -d $MTHYYMM ] && [ $MTHYYMMint -ge $yyyymm24int ]; then
cd $MTHYYMM
curdir=`pwd`
for f in `find . -follow -name "${pattern}*.sas7bdat"  -print | grep $pattern`
do
newf=`echo $f | sed -e 's/\.\///g'`
file_names=$file_names"'"$curdir/$newf"' \n"
done
cd ..
fi
(( i += 1 ))
done
echo $file_names
}
 
grab_seq_files_for_x_mths()
{
yyyymmx=`get_prior_mths $2`
#export pattern=`echo $1 | tr [A-Z] [a-z]`
export pattern=`echo $1`
export DEST=$3
> $DEST/${pattern}.txt
i=0
export file_names=""
until [[ $i -gt $2  ]];do
MTHYYMM=`get_prior_mths $i`
MTHYYMMint=MTHYYMM
yyyymmxint=yyyymmx
typeset -i MTHYYMMint yyyymmxint
if [ -d $MTHYYMM ] && [ $MTHYYMMint -ge $yyyymmxint ]; then
cd $MTHYYMM
curdir=`pwd`
 
for f in `find . -follow -name "${pattern}.txt"  -print | grep $pattern`
do
newf=`echo $f | sed -e 's/\.\///g'`
if [ $i -eq 0 ]; then
cat $curdir/$newf >> $DEST/${pattern}.txt
else
LC=`cat $curdir/$newf | wc -l`
(( LC -= 1 ))
tail -$LC $curdir/$newf >> $DEST/${pattern}.txt
fi
done
cd ..
fi
(( i += 1 ))
done
}
 
grab_seq_files_for_x_mths_with_name()
{
yyyymmx=`get_prior_mths $2`
#export pattern=`echo $1 | tr [A-Z] [a-z]`
export pattern=`echo $1`
export DEST=$3
> $DEST/${pattern}.txt
i=0
export file_names=""
until [[ $i -gt $2  ]];do
MTHYYMM=`get_prior_mths $i`
MTHYYMMint=MTHYYMM
yyyymmxint=yyyymmx
typeset -i MTHYYMMint yyyymmxint
if [ -d $MTHYYMM ] && [ $MTHYYMMint -ge $yyyymmxint ]; then
cd $MTHYYMM
curdir=`pwd`
echo $curdir
for f in `find . -follow -name "${pattern}.txt"  -print | grep $pattern`
do
newf=`echo $f | sed -e 's/\.\///g'`
echo $newf
echo $i
if [ $i -eq 0 ]; then
cat $curdir/$newf >> $DEST/${pattern}.txt
else
LC=`cat $curdir/$newf | wc -l`
(( LC -= 1 ))
tail -$LC $curdir/$newf >> $DEST/${pattern}.txt
fi
done
cd ..
fi
(( i += 1 ))
done
}
 
grab_seq_mth_files_for_x_mths_with_name()
{
yyyymmx=`get_prior_mths $2`
export pattern=`echo $1`
export DEST=$3
> $DEST/${pattern}.txt
i=$(( $APRD_CUBE_DRETN + 1 ))
export file_names=""
until [[ $i -gt $2  ]];do
MTHYYMM=`get_prior_mths $i`
typeset -i MTHYYMMint yyyymmxint
MTHYYMMint=MTHYYMM
yyyymmxint=yyyymmx
echo $MTHYYMM $MTHYYMMint  $yyyymmxint
if [ -d $MTHYYMM ] && [ $MTHYYMMint -ge $yyyymmxint ]; then
cd $MTHYYMM
curdir=`pwd`
for f in `find . -follow -name "${pattern}.txt"  -print | grep $pattern`
do
newf=`echo $f | sed -e 's/\.\///g'`
echo $newf
echo $i
sed -e '1d' $curdir/$newf  >> $DEST/${pattern}.txt
done
cd ..
fi
(( i += 1 ))
done
}
 
 
FTP()
{
echo "Starting the FTP......."
FILENAME=$1
export trgfile=`basename $FILENAME .txt `
trgfile=$trgfile".trg"
echo $trgfile
echo $COG_FTP_ROUTE
if [ $COG_FTP_ROUTE = 'mailbox' ]; then
echo ${FILENAME}${COG_FILE_DLM}${RUNDATE} >> $ST_SEQ_COGNOS/${FILENAME}
continue
fi
 
case $COG_FTP in
sftp )
$COG_FTP -o Port=$COG_FTP_PORT ${COG_USER}@${COG_SERV} <<EOF
put $ST_SEQ_COGNOS/${FILENAME}
quit
EOF
retc=$?
return $retc
;;
scp )
scp ${ST_SEQ_COGNOS}/${FILENAME} ${COG_USER}@${COG_SERV}:${COG_TAR_LOC}/${FILENAME}
retc=$?
if [ $retc -eq 0 ]; then
  ssh ${COG_USER}@${COG_SERV} "touch ${COG_TAR_LOC}/$trgfile"
fi
retc=$?
return $retc
;;
esac
}
 
manage_marts()
{
for CNTY in `echo $CTRY`
do
FILEQ=$1
FILENAME=${FILEQ}.sas7bdat
TYPE=$2
FUNCT=$3
MART_TYPE=$4
SUBDIR=$5
case $FUNCT in
'RENAME')
echo "Renaming ......"
cd $ST_ENV/${CNTY}/Collections/Analytics/$TYPE/$MART_TYPE/$SUBDIR
#touch $FILENAME
pwd
if [ -f ${FILENAME} ]; then
  mv ${FILENAME} ${FILEQ}_preb.sas7bdat
# mv ${FILENAME} action_detail_mtd_PREB.sas7bdat
fi
;;
'DELETE')
cd $ST_ENV/${CNTY}/Collections/Analytics/$TYPE/$MART_TYPE/$SUBDIR
pwd
echo "Deleting ......"
if [ -f ${FILEQ}_preb.sas7bdat ]; then
  rm ${FILEQ}_preb.sas7bdat
fi
;;
'REVERT')
echo "Reverting ......"
cd $ST_ENV/${CNTY}/Collections/Analytics/$TYPE/$MART_TYPE/$SUBDIR
pwd
if [ -f ${FILEQ}_preb.sas7bdat  ]; then
  mv  ${FILEQ}_preb.sas7bdat ${FILENAME}
fi
;;
*)
echo "Invalid Function !!!!"
return 1
;;
esac
done
}
 
 
concat_country_data ()
{
counter=0
> $ST_CONCAT/$1.txt
set -x
 
for CNTY in `cat $ST_PARM/CNTYSDR`
        do
                export FLDIR_RUNDT=$ST_ENV/$CNTY/Collections/seqfile/$RUNDATE
                export FLDIR_YYMM=$ST_ENV/$CNTY/Collections/seqfile/$RUNYYMM
                export FLDIR_PRVDT=$ST_ENV/$CNTY/Collections/seqfile/$RUNDATE_minus
                export FLDIR=$ST_ENV/$CNTY/Collections/seqfile
 
                cd $FLDIR
        grab_seq_files_for_prev_x_mths $1 $SDR_CUBE_RETN ${ST_CONCAT} $CNTY
 
                if [ $counter -gt 0 ]; then
                                 if [ -f $ST_TRIG/trig_sdrbatch_${CNTY}_$RUNDATE.txt ]; then
                          echo 'in header exclusion loop'
                          cp $FLDIR_YYMM/$1.txt $FLDIR_RUNDT/$1.txt
                          sed '1d' $FLDIR_RUNDT/$1.txt >> $ST_CONCAT/$1.txt
                                retcode=$?
                        if [ retcode -le 1 ]; then
                        rm $FLDIR_PRVDT/$1.txt
                        else
                        echo "Pass"
                        fi
                  elif [ $RUNDD -eq 01 ]; then
                     echo "$CNTY Batch is not ready for 1st of the month"
                  else
                        echo "$RUNDATE trigger not available"
                        echo "Copying Previous day file to current day"
                        cp $FLDIR_PRVDT/$1.txt $FLDIR_RUNDT/$1.txt
                      sed '1d' $FLDIR_PRVDT/$1.txt >> ${ST_CONCAT}/$1.txt
                 fi
 
       else
 
                if [ -f $ST_TRIG/trig_sdrbatch_${CNTY}_$RUNDATE.txt ]; then
                     echo 'in header inclusion loop'
                         cp $FLDIR_YYMM/$1.txt $FLDIR_RUNDT/$1.txt
                         cat $FLDIR_RUNDT/$1.txt $ST_CONCAT/$1.txt > $ST_CONCAT/$1_temp.txt
                         cp $ST_CONCAT/$1_temp.txt $ST_CONCAT/$1.txt
                                retcode=$?
                        if [ retcode -le 1 ]; then
                                rm $FLDIR_PRVDT/$1.txt
                        else
                                echo "Pass"
                        fi
               elif [ $RUNDD -eq 01 ]; then
                     echo "$CNTY Batch is not ready for 1st of the month"
                     echo "Adding header to the $1 file"
                     head -1 $FLDIR_PRVDT/$1.txt >> $ST_CONCAT/$1.txt
                                         cat $ST_CONCAT/$1.txt
               else
                     echo "$RUNDATE trigger not available"
                     echo "Copying Previous day file to current day"
                     cp $FLDIR_PRVDT/$1.txt $FLDIR_RUNDT/$1.txt
                     cp $FLDIR_PRVDT/$1.txt ${ST_CONCAT}/$1.txt
               fi
 
       fi
     cat $ST_CONCAT/$1_$CNTY.txt >> $ST_CONCAT/$1.txt
         counter=`expr $counter + 1`
 
done
}
 
 
grab_seq_files_for_prev_x_mths()
{
yyyymmx=`get_prior_mths $2`
#export pattern=`echo $1 | tr [A-Z] [a-z]`
export pattern=`echo $1`
export DEST=$3
export CNTY=$4
> $DEST/${pattern}_$CNTY.txt
i=1
export file_names=""
until [[ $i -gt $2  ]];do
MTHYYMM=`get_prior_mths $i`
MTHYYMMint=MTHYYMM
yyyymmxint=yyyymmx
typeset -i MTHYYMMint yyyymmxint
if [ -d $MTHYYMM ] && [ $MTHYYMMint -ge $yyyymmxint ]; then
cd $MTHYYMM
curdir=`pwd`
 
for f in `find . -follow -name "${pattern}.txt"  -print | grep $pattern`
do
newf=`echo $f | sed -e 's/\.\///g'`
if [ $i -eq 0 ]; then
cat $curdir/$newf >> $DEST/${pattern}_$CNTY.txt
else
LC=`cat $curdir/$newf | wc -l`
(( LC -= 1 ))
tail -$LC $curdir/$newf >> $DEST/${pattern}_$CNTY.txt
fi
done
cd ..
fi
(( i += 1 ))
done
}
 
 
files_exist()
{
export LOCATION=$1
export FILELIST=`echo $2 | tr '|' ' '`
echo $LOCATION $FILELIST
cd $LOCATION
export EXIST=0
for FILE in $FILELIST
do
FILE=$FILE.sas7bdat
print $FILE
if  ! [ -f $FILE ]; then
(( EXIST += 1 ))
fi
echo $FILE "---> " $EXIST
done
echo $EXIST
if [ $EXIST -eq 0 ]; then                                                                                                                                   
 return 0
else
return 1
fi
}
 
temp_delete()
{
export LOCATION=$1
export FILELIST=`echo $2 | tr '|' ' '`
echo $LOCATION $FILELIST
cd $LOCATION
for FILE in $FILELIST
do
FILE=$FILE.sas7bdat*
if [ -f $FILE ]; then
rm -f $FILE
echo $FILE "Deleted...."
fi
done
}
 
st_vars.ksh
 
set -x
export ENVIRONMENT=$(cat $(dirname $0)/.ENVIRONMENT)
export CURTIME=`date +%H%M%S`
export ST_RT=/sasdata/hsbc/dil/.COLL/.G9Strategic/${ENVIRONMENT}
export ST_BASE_PART=/Collections
export ST_BASE=/sasdata/hsbc/dil/.COLL/.G9Strategic/${ENVIRONMENT}/ASP/Collections
export ST_ENV=/sasdata/hsbc/dil/.COLL/.G9Strategic/${ENVIRONMENT}
export ST_SCRIPTS=$ST_BASE/scripts
export ST_PARM=$ST_BASE/prm
export ST_LOGS=$ST_BASE/logs
export ST_CTMLOGS=$ST_BASE/logs
export ST_SASPGM=$ST_BASE/saspgms
export ST_OPATH=$ST_BASE/staging
export ST_STAGING=$ST_BASE/staging
export ST_LANDING=$ST_BASE/landing
export ST_WORK=$ST_BASE/work
export ST_SEQFILE=$ST_BASE/seqfile
export ST_BACKUP=$ST_BASE/backup
export ST_SASLIST=$ST_BASE/saslist
export ST_SASMART_DETAIL=$ST_BASE/detailmart
export ST_SASMART_DIM=$ST_BASE/dimensions
export ST_SAS_LAYOUT=$ST_BASE/layouts
export ST_EMPTY_MART=$ST_PARM/empty.sas7bdat
export ST_TRIG=$ST_BASE/trigger
#export SAS=/usr/bin/sas
#export SAS=/sas/sas93/SASHome/SASFoundation/9.3/sas
export SAS=/sasdata/sas/util/sas
export GMTDIFF="-28800"
export ST_REGION=ASP
export EMP_REGION=HBAP
export EMP_TMZN=43
export cycledatefile=${ST_PARM}/.RUNDATE
export RUNDATE=$(cat ${cycledatefile})
export RUNYYYY=`echo $RUNDATE | cut -c1-4`
export RUNYY=`echo $RUNDATE | cut -c3-4`
export RUNMM=`echo $RUNDATE | cut -c5-6`
export RUNDD=`echo $RUNDATE | cut -c7-8`
export RUNYYMM=$RUNYYYY$RUNMM
export RUNDATE_F=$RUNYYYY"/"$RUNMM"/"$RUNDD
export ST_LOG_FILE=${ST_LOGS}/$(date +%Y%m%d).log
export ST_FILE_START=1
export ST_FILE_EXT=dat
export ST_INB_IND=Y
export SERVERLIST=$ST_PARM/.SERVERLIST
export CTA_SOURCE_LOC=/hsbc/ccr/landing/CCRFTP/MYH/WHIRL/CTA
export UIP_SOURCE_LOC=/sasdata/hsbc/landing/ASP/DIALER
export UIP_SOURCE_LOC1_3=/hsbc/ccr/landing/CCRFTP/ASP/DIALER
export ALM_SOURCE_LOC=/sasdata/hsbc/landing/ASP/DIALER
export ALM_SOURCE_LOC1_3=/hsbc/ccr/landing/CCRFTP/ASP/DIALER
export PRESORT_LOC=/hsbc/ccr/landing/CCRFTP/ASP/DIALER
export ST_CONCAT=$ST_BASE/work/fileftp
export GA_BASE=/sasdata/hsbc/dil/.COLL/.G9/${ENVIRONMENT}/ASP/Collections
export GA_SASMART_DETAIL=${GA_BASE}/detailmart
export GA_SASMART_DIM=$GA_BASE/dimensions
echo "Terminal value is " $TERM
#export STENV1=/SAS/IM/FND/${ENVIRONMENT}
export STENV1=/SAS/IM/G9
export STENV2=Collections/detailmart
if [ $# -ne 0 ]; then
  for last; do true; done
  export cutlast=`echo $last | cut -c1-3`                                                                                                                   
  if [[ ($cutlast == 201) || ($cutlast == 202) ]] ; then                                                                                                    
   export RUNDATE=$last
   export ST_WORK=$ST_BASE/work/backwork
  fi
   echo $RUNDATE
fi
export RUNYYYY=`echo $RUNDATE | cut -c1-4`
export RUNYY=`echo $RUNDATE | cut -c3-4`
export RUNMM=`echo $RUNDATE | cut -c5-6`
export RUNDD=`echo $RUNDATE | cut -c7-8`
export RUNYYMM=$RUNYYYY$RUNMM
export RUNDATE_F=$RUNYYYY"/"$RUNMM"/"$RUNDD
export RUNDATE_YYYYMM=$RUNYYYY$RUNMM
export RUNDATEN=`date -d "$RUNDATE +1 days" +"%Y%m%d"`
export RUNDATEP=`date -d "$RUNDATE -1 days" +"%Y%m%d"`
 
 
#Added below CR3004772
#export RUNYYMMP=`date -d "$RUNDATE -1 month" +"%Y%m"`
#export RUNYYMMP=$(($RUNYYMM -1))
 
if [ "$RUNMM" == 01 ]; then
export RUNMMP=12
export RUNYYMMP=$(($RUNYYYY -1))$RUNMMP
else
export RUNYYMMP=$(($RUNYYMM -1))
fi
 
echo $RUNDATE $RUNDATE_YYYYMM
 
#########################
####RETENTION PERIODS####
#########################
export SASLOG_RETN=7
export SASLST_RETN=7
export LAND_RETN=7
export STG_RETN=14
export SEQ_RETN_MM=390
export SEQ_RETN_DD=30
export DETMART_RETN_MM=181
export DETMART_RETN_DD=60
export ANL_RETN_MM=390
export ANL_RETN_DD=60
 
export CTRY_LAND_RETN=7
export CTRY_STG_RETN=60
export CTRY_SEQ_RETN_MM=390
export CTRY_SEQ_RETN_DD=30
export CTRY_DETMART_RETN_MM=390
export CTRY_DETMART_RETN_DD=90
export CTRY_ANL_RETN_MM=390
export CTRY_ANL_RETN_DD=60
export wrapdatefile=${ST_PARM}/.wrapdate
export WRAPDATE=$(cat ${wrapdatefile})
export WRAPYYYY=`echo $WRAPDATE | cut -c1-4`
export WRAPYY=`echo $WRAPDATE | cut -c3-4`
export WRAPMM=`echo $WRAPDATE | cut -c5-6`
export WRAPDD=`echo $WRAPDATE | cut -c7-8`
export WRAPYYMM=$WRAPYYYY$WRAPMM
export ST_LANDING1_3=$ST_BASE/landing1_3
export ST_SAS_LAYOUT_v3=$ST_BASE/layouts/phase1.3
export UIP_ALM_DLM='▒'
export UIP_ALM_DLM1_3='~'
export ST_UIPLIST1_3=${ST_PARM}/UIPTABLELIST1_3.txt
export G9STRAT_BASE=/sasdata/hsbc/landing/.G9Strategic

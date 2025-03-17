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
libname KEYLIB "&KEYLOC";
 
%LET ST_INGEST=%SYSGET(ST_CNTY_INGEST);
Libname OUTLIB "&ST_INGEST./nonsensitive/&RUNDATE.";
 
%LET C9MARTS = %SYSGET(ST_CNTY_C9MARTS);
libname INLIB "&C9MARTS./&RUNDATEN.";
 
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
 

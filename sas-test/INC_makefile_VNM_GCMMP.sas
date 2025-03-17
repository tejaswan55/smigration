 
 
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
 

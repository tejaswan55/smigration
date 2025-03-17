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
 
 

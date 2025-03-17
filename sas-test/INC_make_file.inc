 
 
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
 
 

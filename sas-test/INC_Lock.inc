 
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
 
 

/*******************************************************************
* Program:  adsl.sas
* Purpose:  Derive ADSL (Subject-Level Analysis Dataset)
* Study:    CDISCPILOT01
* Inputs:   SDTM.DM, SDTM.EX, SDTM.DS
*******************************************************************/

libname sdtm "/study/cdiscpilot01/sdtm";
libname adam "/study/cdiscpilot01/adam";

/* First and last exposure dates */
proc sort data=sdtm.ex out=ex;
  by usubjid exstdtc;
  where exdose > 0 or (exdose = 0 and index(upcase(extrt), 'PLACEBO') > 0);
run;

data ex_first (keep=usubjid trtsdt) ex_last (keep=usubjid trtedt);
  set ex;
  by usubjid;
  format trtsdt trtedt date9.;
  if first.usubjid then do;
    trtsdt = input(substr(exstdtc, 1, 10), yymmdd10.);
    output ex_first;
  end;
  if last.usubjid then do;
    trtedt = input(substr(exendtc, 1, 10), yymmdd10.);
    output ex_last;
  end;
run;

/* End of study status */
data ds_eos (keep=usubjid eosstt);
  set sdtm.ds;
  where dscat = 'DISPOSITION EVENT';
  length eosstt $20;
  if dsdecod = 'COMPLETED' then eosstt = 'COMPLETED';
  else eosstt = 'DISCONTINUED';
run;

data adam.adsl;
  merge sdtm.dm (in=a) ex_first ex_last ds_eos;
  by usubjid;
  if a;
  if armcd ne 'Scrnfail';

  length trt01p trt01a $40 agegr1 $10 saffl ittfl $1;
  trt01p = arm;
  trt01a = actarm;

  if age < 65 then agegr1 = '<65';
  else if 65 <= age <= 80 then agegr1 = '65-80';
  else if age > 80 then agegr1 = '>80';

  ittfl = 'Y';
  if not missing(trtsdt) then saffl = 'Y';
  else saffl = 'N';

  if not missing(trtsdt) and not missing(trtedt) then trtdurd = trtedt - trtsdt + 1;
run;

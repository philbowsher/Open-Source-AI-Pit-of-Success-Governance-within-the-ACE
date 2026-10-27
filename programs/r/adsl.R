# Program: adsl.R
# Purpose: Derive ADSL (Subject-Level Analysis Dataset), CDISCPILOT01
# Source:  programs/sas/adsl.sas
# Author:  Posit Assistant (agent), reviewed by <programmer>
# Status:  Draft for programmer review
# Spec:    Derivations checked against the ADaM define.xml (study-metadata MCP).
#          TRT01A, TRTSDT and TRTEDT follow the define.xml where it differs from the SAS.

library(dplyr)
library(admiral)

if (!exists("dm")) source("programs/00_setup.R")
sv <- pharmaversesdtm::sv

ex_ext <- ex |>
  derive_vars_dt(new_vars_prefix = "EXEN", dtc = EXENDTC)

sv_v3 <- sv |>
  filter(VISITNUM == 3) |>
  derive_vars_dt(new_vars_prefix = "SVST", dtc = SVSTDTC)

ds_eos <- ds |>
  filter(DSCAT == "DISPOSITION EVENT") |>
  derive_vars_dt(new_vars_prefix = "DSST", dtc = DSSTDTC) |>
  mutate(EOSSTT = if_else(DSDECOD == "COMPLETED", "COMPLETED", "DISCONTINUED"))

adsl <- dm |>
  filter(ARMCD != "Scrnfail") |>
  # TRT01P: DM.ARM; TRT01A: same as TRT01P (define.xml)
  mutate(TRT01P = ARM, TRT01A = TRT01P) |>
  # TRTSDT: SV.SVSTDTC at visit 3 (define.xml)
  derive_vars_merged(
    dataset_add = sv_v3,
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(TRTSDT = SVSTDT)
  ) |>
  # TRTEDT: EX.EXENDTC on the last valid dose record
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars = exprs(STUDYID, USUBJID),
    filter_add = EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", toupper(EXTRT))),
    order = exprs(EXSTDTC, EXSEQ),
    new_vars = exprs(TRTEDT = EXENDT),
    mode = "last"
  ) |>
  # EOSSTT and discontinuation date
  derive_vars_merged(
    dataset_add = ds_eos,
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(EOSSTT, DCDT = DSSTDT)
  ) |>
  # TRTEDT: if missing and the subject discontinued, use the discontinuation date (define.xml)
  mutate(TRTEDT = if_else(is.na(TRTEDT) & EOSSTT == "DISCONTINUED", DCDT, TRTEDT)) |>
  select(-DCDT) |>
  # AGEGR1, ITTFL, SAFFL
  mutate(
    AGEGR1 = case_when(
      AGE < 65 ~ "<65",
      AGE >= 65 & AGE <= 80 ~ "65-80",
      AGE > 80 ~ ">80"
    ),
    ITTFL = if_else(!is.na(ARMCD) & ARMCD != "", "Y", "N"),
    SAFFL = if_else(ITTFL == "Y" & !is.na(TRTSDT), "Y", "N")
  ) |>
  # TRTDURD: TRTEDT - TRTSDT + 1
  derive_vars_duration(new_var = TRTDURD, start_date = TRTSDT, end_date = TRTEDT)

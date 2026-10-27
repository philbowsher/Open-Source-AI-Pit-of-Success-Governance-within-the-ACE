# Program: adsl.R
# Purpose: Derive ADSL (Subject-Level Analysis Dataset), CDISCPILOT01
# Source:  programs/sas/adsl.sas
# Author:  Posit Assistant (agent), reviewed by <programmer>
# Status:  Draft for programmer review

library(dplyr)
library(admiral)

if (!exists("dm")) source("programs/00_setup.R")

ex_ext <- ex |>
  derive_vars_dt(new_vars_prefix = "EXST", dtc = EXSTDTC) |>
  derive_vars_dt(new_vars_prefix = "EXEN", dtc = EXENDTC)

ds_eos <- ds |>
  filter(DSCAT == "DISPOSITION EVENT") |>
  mutate(EOSSTT = if_else(DSDECOD == "COMPLETED", "COMPLETED", "DISCONTINUED"))

adsl <- dm |>
  filter(ARMCD != "Scrnfail") |>
  # TRT01P, TRT01A
  mutate(TRT01P = ARM, TRT01A = ACTARM) |>
  # TRTSDT: start date of first valid dose
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars = exprs(STUDYID, USUBJID),
    filter_add = EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", toupper(EXTRT))),
    order = exprs(EXSTDT, EXSEQ),
    new_vars = exprs(TRTSDT = EXSTDT),
    mode = "first"
  ) |>
  # TRTEDT: end date of last valid dose
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars = exprs(STUDYID, USUBJID),
    filter_add = EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", toupper(EXTRT))),
    order = exprs(EXSTDT, EXSEQ),
    new_vars = exprs(TRTEDT = EXENDT),
    mode = "last"
  ) |>
  # EOSSTT: end of study status
  derive_vars_merged(
    dataset_add = ds_eos,
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(EOSSTT)
  ) |>
  # AGEGR1, ITTFL, SAFFL
  mutate(
    AGEGR1 = case_when(
      AGE < 65 ~ "<65",
      AGE >= 65 & AGE <= 80 ~ "65-80",
      AGE > 80 ~ ">80"
    ),
    ITTFL = "Y",
    SAFFL = if_else(!is.na(TRTSDT), "Y", "N")
  ) |>
  # TRTDURD: treatment duration in days
  derive_vars_duration(new_var = TRTDURD, start_date = TRTSDT, end_date = TRTEDT)

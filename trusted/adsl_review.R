# =============================================================================
# TRUSTED CODE BANK :: ADSL review measures (CDISCPILOT01)
# Status : APPROVED (v1.0.0)  -- green-shield code
# Owner  : Statistical Programming Standards
# Note   : Functions tagged @measure are exposed to the {commons} app.
# =============================================================================

#' Population counts by treatment
#'
#' Number of subjects in the ITT and safety populations for each planned
#' treatment in the converted ADSL. Uses ITTFL and SAFFL as defined in the
#' define.xml.
#'
#' @return A gt table, one row per treatment.
#' @provenance https://github.com/pharmaverse/examples/blob/main/adam/adsl.R
#' @measure
population_counts <- function(adam) {
  DBI::dbReadTable(adam, "adsl") |>
    dplyr::group_by(Treatment = TRT01P) |>
    dplyr::summarise(
      ITT = sum(ITTFL == "Y"),
      Safety = sum(SAFFL == "Y"),
      .groups = "drop"
    ) |>
    gt::gt() |>
    gt::tab_header("ADSL population counts by treatment")
}

#' Treatment duration by treatment
#'
#' Summary of TRTDURD (TRTEDT - TRTSDT + 1, days) for the safety population.
#'
#' @return A gt table with n, mean, median, min and max per treatment.
#' @measure
treatment_duration <- function(adam) {
  DBI::dbReadTable(adam, "adsl") |>
    dplyr::filter(SAFFL == "Y") |>
    dplyr::group_by(Treatment = TRT01P) |>
    dplyr::summarise(
      n = sum(!is.na(TRTDURD)),
      Mean = round(mean(TRTDURD, na.rm = TRUE), 1),
      Median = stats::median(TRTDURD, na.rm = TRUE),
      Min = min(TRTDURD, na.rm = TRUE),
      Max = max(TRTDURD, na.rm = TRUE),
      .groups = "drop"
    ) |>
    gt::gt() |>
    gt::tab_header("Treatment duration (days), safety population")
}

#' Converted ADSL vs reference ADSL
#'
#' Compares the ADSL converted from SAS with the pharmaverse reference ADSL,
#' matched on USUBJID, for key derived variables. Lists each subject that
#' differs so the programmer can decide which rule is right.
#'
#' @param variable `enum[TRTSDT, TRTEDT, TRTDURD, EOSSTT, SAFFL]` Variable to compare.
#' @return A gt table of differing subjects, or a one-row table if all match.
#' @provenance https://github.com/pharmaverse/pharmaverseadam
#' @measure
conversion_vs_reference <- function(variable = "TRTEDT", adam) {
  conv <- DBI::dbReadTable(adam, "adsl")
  ref <- DBI::dbReadTable(adam, "adsl_ref")
  both <- dplyr::inner_join(
    conv[, c("USUBJID", "EOSSTT", variable)],
    ref[, c("USUBJID", variable)],
    by = "USUBJID", suffix = c("_converted", "_reference")
  )
  a <- as.character(both[[paste0(variable, "_converted")]])
  b <- as.character(both[[paste0(variable, "_reference")]])
  diff <- both[!mapply(identical, a, b), ]
  if (nrow(diff) == 0) {
    diff <- tibble::tibble(Result = paste("All", nrow(both), "subjects match on", variable))
  }
  gt::gt(diff) |>
    gt::tab_header(paste(variable, ": converted ADSL vs reference ADSL"),
                   subtitle = paste(nrow(both), "subjects compared"))
}

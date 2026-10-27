---
name: sas-to-r
description: Company standard for converting SAS ADaM programs to R with admiral. Use when the user asks to convert, translate, rewrite or migrate a SAS program (.sas) to R.
---

# SAS to R conversion (Statistical Programming Standards v1.0)

Convert SAS ADaM programs into readable R that follows company standards. The goal is code a reviewer can read side by side with the SAS program.

## Approved packages

Use only these packages: dplyr, tidyr, stringr, lubridate, admiral, metacore, metatools, xportr, pharmaversesdtm, pharmaverseadam. If something else seems needed, stop and ask.

## Steps

1. Read the SAS program and list each derivation it performs (variable, source, rule) before writing any code. Show this list to the programmer.
2. Check each derived variable against the study spec with the `study-metadata` MCP tool `describe_variable` (one short call per variable). If the SAS logic and the define.xml disagree, say so in the list. Follow the define.xml unless the programmer says otherwise. Do not call the MCP in a loop for bulk checks; for that, load the define.xml in R with {metacore}.
3. Check that the SDTM inputs exist in the live R session (`dm`, `ex`, `ds`). If not, run `programs/00_setup.R`.
4. Write the R program to `programs/r/<same name>.R` using the mapping below.
5. Run it, then compare record counts and a few key variables against the SDTM data in the session.
6. Summarize what matched, anything that differs from the SAS logic, and any assumption you made.

## Mapping

| SAS pattern | R / admiral |
|---|---|
| `set sdtm.dm;` | start from `dm` |
| `proc sort` + `merge ... by usubjid` with `first.`/`last.` | `derive_vars_merged()` with `order` and `mode = "first"` or `"last"` |
| `input(--DTC, yymmdd10.)` | `derive_vars_dt()` or `convert_dtc_to_dt()` |
| `if/else if` groupings | `derive_vars_cat()` or `case_when()` |
| flags `= 'Y'` | `derive_var_merged_exist_flag()` or `if_else(..., "Y", NA_character_)` |
| `intck` / day counts | `derive_vars_duration()` |

## Style

- Start every program with a header: program name, purpose, source SAS program, author "Posit Assistant (agent), reviewed by <programmer>".
- One derivation per pipeline step, with a short comment naming the ADaM variable.
- Keep SAS variable names and order.
- Do not edit the SAS program.
- Do not call the output validated. It is a draft for programmer review.

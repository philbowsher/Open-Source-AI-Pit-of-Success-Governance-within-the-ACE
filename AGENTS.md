# Study CDISCPILOT01: ADaM programming

This project derives ADaM datasets and TLFs for the CDISC pilot study in R.

## Layout

- `programs/sas/`: existing SAS programs. Reference only. Do not edit, and do not try to run them; SAS is not installed.
- `programs/r/`: R programs. New and converted programs go here.
- `programs/00_setup.R`: loads the SDTM data into the session. Run it first if `dm` is not in the session.

## Rules

- When asked to convert, translate or rewrite a SAS program, load the `sas-to-r` skill.
- Use only packages on the approved list in the `sas-to-r` skill.
- Check derived datasets against the SDTM data in the live session before saying they are done.
- Report findings; the programmer decides.

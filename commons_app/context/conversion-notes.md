---
provenance: programs/r/adsl.R and the study-metadata MCP server (ADaM define.xml, CDISCPILOT01)
---

# SAS to R conversion decisions for ADSL

- The R program follows the define.xml where it differs from the SAS program.
- TRT01A equals TRT01P (define.xml); the SAS program used DM.ACTARM.
- TRTSDT is the SV visit 3 date (define.xml); the SAS program used the first EX date. Both give the same dates.
- TRTEDT: when the last dose has no end date and the subject discontinued, the DS disposition date is used (define.xml). The SAS program left it missing. Six discontinued subjects differ from the reference ADSL; the programmer decides.
- AGEGR1 groups are <65, 65-80, >80, matching the define.xml.

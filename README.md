# Open-Source AI Pit of Success: Governance within the ACE (AI Statistical Environment)

Code for the PHUSE 2026 paper. Slides: https://pub.current.posit.team/public/OpenSource_AI_Pit_of_Success/

Data is the mock CDISC pilot study from {pharmaversesdtm} and {pharmaverseadam}.

| Folder | What it is |
|---|---|
| `.posit/assistant/skills/sas-to-r/` | Company skill Posit Assistant uses to convert SAS ADaM programs to R |
| `AGENTS.md` | Project instructions Posit Assistant reads on startup |
| `programs/` | SAS program, its R conversion, and data setup |
| `reports/` | Quarto page comparing the SAS and R code, with checks |
| `mcp/define-metadata/` | FastMCP server for short define.xml lookups, deployed to Posit Connect |
| `trusted/` | Approved functions used by the {commons} app |
| `commons_app/` | {commons} chat app for reviewing the converted ADSL |
| `data/` | Converted and reference ADSL used by the app |

To use the MCP server, deploy `mcp/define-metadata/` to Posit Connect and add its `/mcp` URL under `mcpServers` in `.posit/assistant/settings.json`.

Run the app from the project root with `shiny::runApp("commons_app")`.

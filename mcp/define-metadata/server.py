"""Study metadata MCP server (CDISCPILOT01 ADaM define.xml).

Small, read-only lookups that return short answers. It does not move data.
For bulk or programmatic work, load the define.xml in R with {metacore}.
"""

import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse

from fastmcp import FastMCP

DEFINE = Path(__file__).parent / "ADaM_define_CDISC_pilot3.xml"
NS = {
    "odm": "http://www.cdisc.org/ns/odm/v1.3",
    "def": "http://www.cdisc.org/ns/def/v2.0",
}
MAX_CODES = 25
MAX_MATCHES = 10


def _text(el):
    if el is None:
        return ""
    t = el.find("odm:Description/odm:TranslatedText", NS)
    return " ".join(t.text.split()) if t is not None and t.text else ""


def _load():
    root = ET.parse(DEFINE).getroot()
    mdv = root.find(".//odm:MetaDataVersion", NS)
    items = {i.get("OID"): i for i in mdv.findall("odm:ItemDef", NS)}
    methods = {m.get("OID"): _text(m) for m in mdv.findall("odm:MethodDef", NS)}
    codelists = {c.get("OID"): c for c in mdv.findall("odm:CodeList", NS)}
    datasets = {}
    for ig in mdv.findall("odm:ItemGroupDef", NS):
        refs = []
        for ref in ig.findall("odm:ItemRef", NS):
            item = items.get(ref.get("ItemOID"))
            if item is not None:
                refs.append((item, ref))
        datasets[ig.get("Name")] = {
            "label": _text(ig),
            "class": ig.get("def:Class") or ig.get("{%s}Class" % NS["def"]) or "",
            "vars": {item.get("Name"): (item, ref) for item, ref in refs},
        }
    return datasets, methods, codelists


DATASETS, METHODS, CODELISTS = _load()

mcp = FastMCP(
    "CDISCPILOT01 study metadata",
    instructions=(
        "Answers short questions about the CDISCPILOT01 ADaM define.xml: dataset "
        "lists, one variable's definition, one codelist, or a keyword search. "
        "Use it for quick lookups only. For bulk or programmatic work (checking a "
        "dataset against the spec, building pointblank rules), do not call these "
        "tools in a loop; load the define.xml in R instead with "
        "metacore::define_to_metacore(system.file('extdata', "
        "'ADaM_define_CDISC_pilot3.xml', package = 'metacore'))."
    ),
)

READ_ONLY = {"readOnlyHint": True, "idempotentHint": True, "openWorldHint": False}


def _get(dataset, variable):
    ds = DATASETS.get(dataset.upper())
    if ds is None:
        return None, f"No dataset {dataset}. Datasets: {', '.join(DATASETS)}."
    hit = ds["vars"].get(variable.upper())
    if hit is None:
        return None, f"No variable {variable} in {dataset.upper()}."
    return hit, None


def _origin(item):
    o = item.find("def:Origin", NS)
    return o.get("Type", "") if o is not None else ""


@mcp.tool(annotations=READ_ONLY)
def list_datasets() -> str:
    """List the ADaM datasets in the define.xml, one line each."""
    return "\n".join(
        f"{name}: {d['label']} ({d['class']}, {len(d['vars'])} variables)"
        for name, d in DATASETS.items()
    )


@mcp.tool(annotations=READ_ONLY)
def describe_variable(dataset: str, variable: str) -> str:
    """Short definition of one variable: label, type, length, origin, codelist and derivation rule."""
    hit, err = _get(dataset, variable)
    if err:
        return err
    item, ref = hit
    name = f"{dataset.upper()}.{item.get('Name')}"
    lines = [
        f"{name}: {_text(item)}",
        f"Type: {item.get('DataType')}, length {item.get('Length', '-')}",
        f"Origin: {_origin(item) or '-'}",
    ]
    cl = item.find("odm:CodeListRef", NS)
    if cl is not None:
        lines.append(f"Codelist: {CODELISTS[cl.get('CodeListOID')].get('Name')} (use get_codelist for values)")
    rule = METHODS.get(ref.get("MethodOID"), "")
    if rule:
        lines.append(f"Derivation: {rule}")
        # Follow one "derived from DS.VAR" pointer so the short answer is complete
        m = re.search(r"derived from (\w+)\.(\w+)", rule, re.IGNORECASE)
        if m:
            src, _ = _get(m.group(1), m.group(2))
            if src and METHODS.get(src[1].get("MethodOID")):
                lines.append(f"  {m.group(1).upper()}.{m.group(2).upper()}: {METHODS[src[1].get('MethodOID')]}")
    return "\n".join(lines)


@mcp.tool(annotations=READ_ONLY)
def get_codelist(dataset: str, variable: str) -> str:
    """Allowed values for one variable's codelist (at most 25 shown)."""
    hit, err = _get(dataset, variable)
    if err:
        return err
    cl_ref = hit[0].find("odm:CodeListRef", NS)
    if cl_ref is None:
        return f"{dataset.upper()}.{variable.upper()} has no codelist."
    cl = CODELISTS[cl_ref.get("CodeListOID")]
    vals = [c.get("CodedValue") for c in cl.findall("odm:CodeListItem", NS)]
    vals += [e.get("CodedValue") for e in cl.findall("odm:EnumeratedItem", NS)]
    shown = vals[:MAX_CODES]
    out = f"{cl.get('Name')} ({len(vals)} values): " + ", ".join(shown)
    if len(vals) > MAX_CODES:
        out += f" ... {len(vals) - MAX_CODES} more. Load the define.xml in R with metacore for the full list."
    return out


@mcp.tool(annotations=READ_ONLY)
def find_variables(keyword: str, dataset: str = "") -> str:
    """Find variables whose name or label contains a keyword (at most 10 matches)."""
    kw = keyword.lower()
    pool = [dataset.upper()] if dataset else list(DATASETS)
    hits = [
        f"{ds}.{name}: {_text(item)}"
        for ds in pool if ds in DATASETS
        for name, (item, _) in DATASETS[ds]["vars"].items()
        if kw in name.lower() or kw in _text(item).lower()
    ]
    if not hits:
        return f"No variables match '{keyword}'."
    out = "\n".join(hits[:MAX_MATCHES])
    if len(hits) > MAX_MATCHES:
        out += f"\n... {len(hits) - MAX_MATCHES} more. Narrow the keyword or pick a dataset."
    return out


allowed_hosts = []
connect_server = os.environ.get("CONNECT_SERVER", "")
if connect_server:
    host = urlparse(connect_server).hostname
    if host:
        allowed_hosts.append(host)

app = mcp.http_app(
    stateless_http=True,
    json_response=True,
    host_origin_protection=True,
    allowed_hosts=allowed_hosts,
)

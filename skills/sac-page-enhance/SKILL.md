---
name: sac-page-enhance
description: Extract existing Huawei Cloud Solution Practice page content, refine evidence-backed marketing copy, compare page variants, and export structured Excel. Use only for page extraction, selling-point wording, merchandising reports, or Excel output; not for architecture or formal documents.
---

# SAC Page Enhance

Transform existing page evidence into structured content and clearer merchandising copy. Do not design an
architecture, alter deployment facts, recommend a solution, or generate formal multilingual documents.

## Inputs and outputs

Accept a user-provided page URL, saved page content, or structured project JSON. Retrieve network content only
when the user requests it or an authorized workflow already permits it. Prefer the page itself; use Huawei Cloud support documentation
only when dynamic deployment content is unavailable, and record that fallback source.

Produce only the requested artifacts:

- structured JSON for extracted page sections;
- enhanced JSON plus a before/after report for copy refinement;
- comparison report for multiple page variants;
- two-column rich-text Excel.

Use the schema and formatting accepted by the existing script; inspect its input contract when producing JSON
instead of duplicating that contract here.

## Workflow

1. Capture source URL/file, access time, and fallback sources.
2. Remove navigation, login, footer, duplicate DOM blocks, and unrelated page noise.
3. Separate multiple deployment variants; preserve each variant's components, cost, duration, and constraints.
4. Structure title, introduction, customers, advantages, architecture, scenarios, preparation, deployment,
   getting-started, uninstall, cost, and optimization sections when present.
5. For marketing enhancement, improve clarity and customer value without changing technical meaning.
6. Check missing constraints, variant coverage, parameter/code readability, cost context, and repeated content.
7. Generate only the requested JSON, report, or Excel and disclose missing or low-confidence fields.

## Evidence rules

Retain every cost, duration, percentage, performance figure, customer count, and comparative claim only with a
verifiable source. Do not calculate or infer a number from marketing context. Remove unsupported numbers or mark
them `待业务确认`; never present the marker as validated evidence.

Keep product names, resource names, commands, parameters, URLs, versions, regions, and deployment behavior
unchanged unless the verified source supports the edit. Conflicts between page content and implementation are
reported, not silently corrected.

## Excel

Run:

Use two columns (`项目`, `内容`), rich-text headings, numbered repeated items, wrapped text, and the formatting
implemented by the script. Return source coverage, generated files, unsupported claims removed or marked, and
unresolved conflicts.

# Repository Guidelines

## Project Structure & Module Organization
- Root holds XSL-FO/XSL templates (`*.xsl`), generated PDFs (`OR*.pdf`), agreements/policies (`*.md`), and supporting artifacts (e.g., Postman collections).
- Key examples: `template10071.xsl`, `OR117609-22.pdf`, `Uptime-VoIP-MSA.md`.
- No application runtime here; this repo focuses on document templates and rendered outputs.

## Build, Test, and Development Commands
- Generate a PDF (Apache FOP 2.6):
  - `fop -xsl template10071.xsl -xml sample.xml -pdf preview.pdf`
- Optional two-step (inspect FO):
  - `xsltproc template10071.xsl sample.xml > out.fo`
  - `fop -fo out.fo -pdf preview.pdf`
- Validate XML/XSL quickly:
  - `xmllint --noout template10071.xsl sample.xml`

## Coding Style & Naming Conventions
- Indentation: 2 spaces for XSL/XSL-FO; wrap lines ~120 chars.
- Attribute order (keep stable): `id`, layout attrs (size/margins), visual attrs (color/border), then content.
- Use `fo:` consistently; prefer explicit measurements (e.g., `pt`, `mm`).
- Filenames: rendered quotes follow `OR<orderId>-<sequence>.pdf` (e.g., `OR117609-22.pdf`).
- Do not add new `*.backup` files—use Git history for versioning.

## Testing Guidelines
- Use anonymized `sample.xml` (no customer data). Keep any samples in `testdata/` (if needed) with clear names (e.g., `sample_basic.xml`).
- Verify pagination, header/summary tables, borders/rounded corners, and totals layout across pages.
- Check PDF metadata for engine consistency (target: Apache FOP 2.6).

## Commit & Pull Request Guidelines
- Commits: imperative, present tense, concise subject (<=72 chars) with a rationale body if needed.
  - Example: `Fix rounded corners in summary tables`
- PRs: include before/after screenshots or PDFs when visual changes occur, brief description, and linked issue.
- Keep PRs focused; avoid mixing template, policy, and asset changes.

## Security & Configuration Tips
- Never commit PII or customer contracts. Redact or synthesize sample data.
- Fonts/assets: embed or document required environment; avoid network-dependent resources.
- If switching toolchain versions, note the exact FOP version and justify in the PR.


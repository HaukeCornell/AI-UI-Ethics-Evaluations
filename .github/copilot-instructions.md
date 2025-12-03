# Copilot Instructions for This Repo

This repository hosts the LaTeX source (and supporting markdown notes) for the CHI 2026 revise-and-resubmit of the paper **"Ethics-Focused User Metrics"**. Your main job as an AI agent is to help edit and keep the manuscript, R&R notes, and reviewer-driven changes in sync.

## Project Structure & Big Picture

- `overleaf-paper/main_acm_CHI_tempalte.tex` is the entry point for the CHI manuscript and `\input`s:
  - `00_abstract.tex`, `01_introduction.tex`, `02_literature.tex`, `03_method.tex`, `04_results.tex`, `05_discussion.tex`, `10_appendix.tex`.
- `overleaf-paper/markdown-documentation/` contains R&R coordination files:
  - `agents-guide.md`: high-level agent workflow for this CHI R&R (read this before large edits).
  - `paper-todo.md`: live checklist of reviewer-facing tasks.
  - `CHI-2026-reviews.md`: reviewer and meta-review text (read-only).
  - `terminology-glossary.md`: canonical wording for key terms.
  - `key_changes_done.md`: log of major, reviewer-visible changes.
- `overleaf-paper/library.bib` and `overleaf-paper/old bib/` contain bibliographic data; the main paper currently cites from `library.bib`.

## Build & Verification

- LaTeX builds are configured via `overleaf-paper/latexmkrc` to use a `build/` directory and `pdflatex`:
  - From the repo root: `cd overleaf-paper` then run `latexmk -pdf main_acm_CHI_tempalte.tex`.
  - If `latexmk` is unavailable, use `pdflatex` + `bibtex` manually, but keep outputs in `build/` (as configured).
- After non-trivial changes to citations, section structure, or macros, trigger a local build to catch compilation errors before committing.

## Workflow for Reviewer-Driven Edits

- For any change tied to reviews:
  - Start from `overleaf-paper/markdown-documentation/CHI-2026-reviews.md` to locate the concern.
  - Find the affected LaTeX section(s) via `main_acm_CHI_tempalte.tex` and its `\input` files.
  - Make focused edits in the relevant `.tex` file(s) only.
  - Update `paper-todo.md` (marking items done or refining scope) and, for substantial changes, append a short bullet to `key_changes_done.md` describing what changed and which reviewer concern it addresses.
- Keep edits small and scoped: prefer one reviewer issue or subsection per PR / change set.

## Writing & Style Conventions

- Always consult `overleaf-paper/markdown-documentation/terminology-glossary.md` before introducing or renaming key constructs (e.g., "questionnaire-based UX metrics", "autonomy-focused metrics", study names, outcome variables).
- Avoid em dashes (`---`) for structure; rewrite sentences into two shorter sentences, or use commas/semicolons, per `agents-guide.md`.
- Keep paragraphs cohesive, avoiding one-sentence paragraphs except for deliberate emphasis.
- When editing, preserve the existing macro usage in `main_acm_CHI_tempalte.tex` (e.g., `\hauke{}`, `\placeholder{}`, `\citetodo{}`) and use them rather than introducing new ad-hoc comment styles.

## LaTeX & Bibliography Practices

- The CHI paper uses the ACM class with `\bibliographystyle{ACM-Reference-Format}` and `\bibliography{library}`:
  - Add or fix references in `overleaf-paper/library.bib` unless a clear pattern indicates use of an older `.bib` file from `old bib/`.
- Do not edit `acmart.cls`, `ceurart.cls`, or `ACM-Reference-Format.bst` unless you are explicitly asked to debug a template issue.
- When adding figures or tables, follow existing patterns:
  - Figures live in `overleaf-paper/graphics/` and are referenced with `\includegraphics` (see the teaser figure in `main_acm_CHI_tempalte.tex`).
  - Tables for UEQ/UEQ-A are defined in `UEQ-Table.tex`; reuse this style for new questionnaire tables.

## Coordination Between Markdown Notes and LaTeX

- Conceptual and literature work often starts in markdown:
  - Deeper literature synthesis goes into `literature-notes.md` and `lit-research-result.md`.
  - Before rewriting sections like the Literature Review, update or consult these files to ensure arguments match the latest notes.
- When you port text from markdown into LaTeX:
  - Align terminology with `terminology-glossary.md`.
  - Remove drafting annotations and ensure citations use LaTeX `\cite{}` keys in `library.bib`.

## Agent Safety Rails

- Treat `overleaf-paper/markdown-documentation/CHI-2026-reviews.md` as read-only input.
- Do not remove or rename core files (e.g., the `01_...`–`05_...` section files, `main_acm_CHI_tempalte.tex`) without explicit instruction.
- Before large refactors, prefer suggesting a plan in a comment or PR description rather than directly restructuring many files at once.

If you are unsure about a term, outcome variable, or study label, check `terminology-glossary.md` and `agents-guide.md` first, then surface questions in comments instead of guessing. 
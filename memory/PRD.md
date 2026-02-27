# PRD - Slop & Code Doctor MVP

## Original Problem Statement
Build an AI-powered "Slop and Code Doctor" that is highly efficient and accurate at code issue detection and fix suggestions (targeting quality beyond Code Rabbit), with core support for slop detection, actionable fixes, documentation generation, severity customization, and integration capability with developer workflows.

## User Choices Captured
- Scope: **Web app MVP**
- AI Provider: **Ollama Cloud** (no API key)
- Priority features: **A (slop detection), C (auto fix suggestions), E (documentation generation), F (Git/CI integration stubs)**
- UI preference: **Clean professional dashboard**

## Architecture Decisions
- **Frontend**: React + React Router multi-page app (Dashboard, Repository Fixes, Reports, Report Detail, Integrations, Settings)
- **Backend**: FastAPI REST API with MongoDB persistence
- **Database**: Mongo collections for reports, settings, integration events, repository sessions
- **Analysis Strategy**: Rule-based slop/security/readability analysis as deterministic baseline + optional Ollama enhancement path
- **Ollama Integration**: Configurable via settings (`ollama_base_url`, `ollama_model`, `use_ollama`), no hard API key dependency
- **Reliability Fix**: Migrated blocking external calls off event loop using `asyncio.to_thread` for async route safety
- **Fix Safety Strategy**: Approval-gated fix application with syntax validation before persistence and zip export of patched repository

## Implemented in this Iteration
- End-to-end code analysis flow (paste/upload code -> analyze -> report saved)
- Slop detection rules: hardcoded secret-like values, dynamic execution risk, long lines, weak naming, magic numbers, duplication, deep nesting, file complexity hints
- Auto fix suggestions attached per issue
- Documentation generation output per analyzed file
- Custom severity thresholds with validation (`critical > high > medium >= low`)
- Report history APIs and UI list/detail pages with issues/fixes/docs tabs
- Integration stubs for Git webhook and CI event ingestion + recent events viewer
- Clean tactical dashboard UI, responsive layout, and `data-testid` coverage across app-owned interactive/critical elements
- Backend and frontend lint passed; backend and frontend flows verified via self tests + testing agent regression
- Multi-file repository scan endpoint (`/api/repository/analyze`) with auto-fix proposals for Python/JS hardcoded secrets and Python eval usage
- Approval workflows implemented: approve selected fixes and approve-all (`/api/repository/apply-fixes`)
- Functional safety guard implemented: block apply when syntax validation fails (Python compile-level check + JS `node --check`)
- Downloadable patched codebase endpoint (`/api/repository/sessions/{id}/download`) and UI flow in Repository Fix Approval Center
- Multi-provider model gateway capability: Ollama local/cloud + OpenAI-compatible + Gemini + Anthropic with configurable primary/fallback routing
- Settings UI upgraded for provider matrix management (enable/disable, base URL, model, API key inputs, clear-key option)
- API key handling improved: keys are encrypted before DB storage and never returned in plaintext; only masked metadata is returned
- Backward compatibility preserved: legacy settings payload (`use_ollama`, `ollama_base_url`, `ollama_model`) still accepted

## Prioritized Backlog
### P0
- Improve analysis accuracy with richer language-aware parsing (AST for JS/TS + deeper Python checks)
- Structured Ollama output contract with strict JSON schema validation and retry/circuit-breaker
- Conflict-aware patching (context hunks) and deterministic rollback previews before apply
- Move provider HTTP calls to fully async client stack for higher concurrency under load

### P1
- Repository-level risk scoring and per-directory quality heatmap
- Rule packs by stack (Python, Node, React, FastAPI) and optional secure defaults profile
- Better docs generation quality with section templates (API, edge cases, examples)

### P2
- Team collaboration (comments, assignees, status per issue)
- Export reports to markdown/PDF
- CI annotations format (e.g., SARIF-like output)

## Next Tasks
1. Expand auto-fix coverage (safe JS eval alternatives, naming refactors with reference tracking, constant extraction).
2. Add zip upload and Git ref ingestion paths in addition to folder upload.
3. Add preview diff viewer (before/after with hunk context) before approval.
4. Introduce rule packs and presets (strict, balanced, fast) for customizable analysis depth.
5. Add provider health dashboard and per-provider latency/error telemetry.

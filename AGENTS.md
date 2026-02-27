# DR.CODE-v2 — Agent & Collaborator Guide

> **READ THIS ENTIRE DOCUMENT BEFORE MAKING ANY CHANGE TO THIS CODEBASE.**
> Non-compliance is grounds for reverting your work.

---

## 1. What This Project Is

**DR.CODE-v2** is a self-hosted, AI-augmented code analysis platform ("Slop & Code Doctor").
It detects code quality issues, generates fix proposals, and produces documentation — delivered through a dark-mode React dashboard backed by a FastAPI/MongoDB backend.

**This is the upgrade branch.** The frozen original lives at `../DR.CODE/`.

---

## 2. The Upgrade Scope — NOTHING ELSE

This v2 branch exists to implement **exactly two features** and nothing more:

| # | Feature | Status |
|---|---|---|
| 1 | **Real GitHub PR Webhook Pipeline** — when GitHub sends a `pull_request` event, fetch changed files, run analysis, post inline review comments back to the PR | 🔄 In Progress |
| 2 | **GitHub Integration Settings UI** — token input, webhook URL display, setup guide in the frontend | 🔄 In Progress |

### ❌ Out of Scope — Do Not Touch

The following are **explicitly prohibited** in this branch. Open a separate branch if you think something else is needed:

- Adding new languages or extending the rule engine
- Changing the authentication model (the role/actor header system)
- Any new database collections beyond `integration_events` and `app_settings`
- Redesigning existing pages (Dashboard, Reports, Governance, Repository Fixes)
- Adding third-party packages not listed in `backend/requirements.txt` or `frontend/package.json` without explicit approval
- Modifying the `design_guidelines.json` design tokens
- Any CI/CD or deployment configuration changes
- Adding analytics, telemetry, or external tracking of any kind

---

## 3. Architecture — Strict Rules

### 3.1 Backend (`backend/server.py`)

- **Single file.** All backend logic lives in `server.py`. Do not create additional Python modules or split into packages unless explicitly directed.
- **FastAPI + Motor (async MongoDB).** Stick to the existing patterns. All DB writes use `await db.collection.insert_one(...)` or `update_one(...)`.
- **Encryption.** All secrets (tokens, API keys) MUST be encrypted with `encrypt_value()` before storing. Never store plaintext secrets in MongoDB. Never log them.
- **Pydantic models first.** Every new endpoint request/response must have a corresponding Pydantic model. No raw `dict` responses.
- **No new external HTTP libraries.** GitHub API calls use the `requests` library already in `requirements.txt`. Run them inside `asyncio.to_thread()` to avoid blocking the event loop.
- **Backward compatibility.** The existing `/integrations/git/webhook` stub tests in `backend/tests/test_api_regression.py` must still pass unchanged. New behavior is additive only.
- **HMAC verification:** if `webhook_secret` is configured, GitHub webhook signature MUST be verified. If not configured, skip verification with a warning log — do not reject the request.
- **Error handling.** All GitHub API call failures must be caught and logged as `IntegrationEvent` with `status: "error"`. Never let a webhook handler crash the server.
- **Governance events.** All new analysis runs triggered by webhooks must call `record_governance_event()` the same way the manual `/analyze` endpoint does.

### 3.2 Frontend (`frontend/src/`)

- **React + shadcn/ui only.** All components come from `frontend/src/components/ui/`. Do not install new UI libraries.
- **`api.js` is the only HTTP layer.** Never call `fetch()` or `axios` directly from a page or component. All API calls go through `frontend/src/services/api.js`.
- **Dark mode only.** The design system is dark-mode exclusive. `class="dark"` is forced on the HTML element. Do not add light-mode variants.
- **`data-testid` on every interactive element.** Every button, input, select, and card added must have a `data-testid` attribute. Follow the existing naming convention: `kebab-case`, scoped to the page (e.g. `github-token-input`, `github-save-button`).
- **Toasts for all user feedback.** Use `import { toast } from "@/components/ui/sonner"` for every success/error notification. No `alert()`, no `console.error()` as user feedback.
- **New pages require router registration.** If you need a new page, register it in `frontend/src/App.js` following the existing `<Route>` pattern.

### 3.3 Design System (Non-Negotiable)

All UI work MUST follow `design_guidelines.json`. Key rules:

| Element | Rule |
|---|---|
| Headings | Space Grotesk font, `tracking-tight` |
| Body text | Plus Jakarta Sans |
| Code / tokens | JetBrains Mono |
| Primary color | `#00E5FF` (cyan) |
| Cards | `bg-card border-border/50` |
| Buttons | `h-10 px-4 py-2` standard size |
| Borders | `border border-border` default |
| Glow effects | `shadow-[0_0_15px_rgba(0,229,255,0.3)]` for primary actions only |

---

## 4. Git Discipline

- **Branch naming:** `feature/github-webhook-pipeline`, `feature/github-settings-ui`
- **Commit messages:** `feat:`, `fix:`, `chore:`, `test:` prefixes. Be specific.
  - ✅ `feat: add HMAC signature verification to git webhook endpoint`
  - ❌ `update stuff` / `wip` / `fixes`
- **One logical change per commit.** Do not bundle unrelated changes.
- **Do not commit:** `.env` files, `node_modules/`, `__pycache__/`, any file with real API keys or tokens.
- **The `master` branch is the protected baseline** (commit `ff94cf1`). New work goes in feature branches, merged via PR.

---

## 5. Testing Requirements

Every backend change requires a corresponding test. Tests live in `backend/tests/`.

### Running Tests

```bash
# From backend directory:
cd "/home/whoshotya/Downloads/Antigravity/projects (1)/projects/DR.CODE-v2/backend"
REACT_APP_BACKEND_URL=http://localhost:8002 pytest tests/ -v
```

### Test Rules

- **Existing tests must pass.** If your change breaks an existing test, fix the code — not the test.
- **Mock all external calls.** GitHub API calls in tests must be mocked with `unittest.mock.patch`. No real network calls in the test suite.
- **New endpoints need tests.** Any new `@api_router` endpoint must have at least one test covering the happy path and one for graceful failure (e.g. missing token, malformed payload).
- **Test file naming:** `test_<feature>_regression.py`

---

## 6. Environment Variables

The v2 backend uses the same `.env` as the original plus these new variables:

```
# Existing (keep as-is):
MONGO_URL=...
DB_NAME=...
CORS_ORIGINS=...
OLLAMA_BASE_URL=...
OLLAMA_MODEL=...

# New for v2 (optional — can also be set via Settings UI):
GITHUB_TOKEN=...          # GitHub PAT with pull_requests:write scope
GITHUB_WEBHOOK_SECRET=... # Webhook secret configured in GitHub repo settings
```

> **NEVER hardcode these values in source code.** Use `os.environ.get()` with a safe default or `None`.

---

## 7. Port Convention (Side-by-Side Operation)

| Instance | Backend Port | Frontend Port |
|---|---|---|
| `DR.CODE` (original, frozen) | `8001` | `3000` |
| `DR.CODE-v2` (upgrade) | `8002` | `3001` |

Start v2 backend with:

```bash
cd "/home/whoshotya/Downloads/Antigravity/projects (1)/projects/DR.CODE-v2/backend"
uvicorn server:app --port 8002 --reload
```

Start v2 frontend with:

```bash
cd "/home/whoshotya/Downloads/Antigravity/projects (1)/projects/DR.CODE-v2/frontend"
REACT_APP_BACKEND_URL=http://localhost:8002 PORT=3001 npm start
```

---

## 8. Before Submitting Any Work

Run this checklist. All boxes must be checked:

- [ ] `pytest tests/ -v` passes with zero failures
- [ ] No new packages added without updating `requirements.txt` or `package.json`
- [ ] Every new interactive UI element has a `data-testid`
- [ ] No plaintext secrets appear anywhere in the diff (`git diff master`)
- [ ] No changes outside the defined upgrade scope (Section 2)
- [ ] Commit message follows the convention (Section 4)
- [ ] `AGENTS.md` is unchanged (do not modify this file without explicit owner approval)

---

## 9. Who to Sync With

**Project owner:** @whoshotya
**Reference build:** `../DR.CODE/` (do not modify)
**Implementation plan:** See `AGENTS.md` Section 2 and `implementation_plan.md` in the brain artifacts.

> Any feature, refactor, or "improvement" not described in Section 2 of this document requires **explicit written approval from the project owner** before a single line of code is written.

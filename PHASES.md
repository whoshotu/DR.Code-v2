# DR.CODE-v2 Development Roadmap

## Completed Work

### Phase 1: Docker Build Fixes
- Fixed CI Docker build context paths (relative paths)
- Added CI trigger on feature branches
- Added session files to .gitignore

### Phase 2: Test Generator
- `backend/generators/test_generator.py` - Test generation engine
  - AST parsing for Python functions
  - Regex parsing for JavaScript functions
  - Support for pytest, unittest (Python), vitest, jest (JS)
  - Edge case generation
  - Syntax validation
- `POST /api/generate/tests` endpoint
- 20 unit tests (all passing)

### Phase 3: Docstring Generator
- `backend/generators/docstring_generator.py` - Docstring generation
  - Google, NumPy, Sphinx styles
  - LLM-powered generation
- `POST /api/generate/docstrings` endpoint
- 10 unit tests (all passing)

### Phase 4: Sequence Diagram Generator
- `backend/generators/diagram_generator.py` - Mermaid diagram generation
  - Sequence diagrams
  - Flow diagrams (future)
- `POST /api/generate/diagram` endpoint

### Phase 5: Frontend UI
- Added 4-tab Dashboard: Analyze, Tests, Docs, Diagram
- `GenerateTestsPanel.jsx` - Test generation UI
- `GenerateDocstringsPanel.jsx` - Docstring generation UI
- `GenerateDiagramPanel.jsx` - Diagram generation UI (raw syntax only)

---

## Current Issues

1. **Diagram Panel shows raw Mermaid syntax** - Users can't see rendered diagram
2. **No Mermaid.js integration** - Need to add diagram rendering library

---

## Remaining Work

### Priority 1: Mermaid Rendering
- [x] Install mermaid.js package
- [x] Update GenerateDiagramPanel to render Mermaid syntax
- [x] Add copy functionality (already there)
- [ ] Test in browser

### Priority 2: Testing with Real LLM
- [ ] Start backend with Ollama
- [ ] Test all three generators with real code
- [ ] Verify output quality

### Priority 3: Integration Tests
- [ ] Add API endpoint tests (mock server)
- [ ] Add E2E tests for generation features

### Priority 4: Polish
- [ ] Add loading states
- [ ] Add error handling improvements
- [ ] Add more test frameworks (Jest for JS)

---

## Tech Stack

- **Backend**: FastAPI, Motor (MongoDB), Ollama
- **Frontend**: React, shadcn/ui, axios
- **Testing**: pytest, unittest.mock
- **CI**: GitHub Actions

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/analyze` | POST | Analyze code for slop |
| `/api/generate/tests` | POST | Generate unit tests |
| `/api/generate/docstrings` | POST | Generate docstrings |
| `/api/generate/diagram` | POST | Generate Mermaid diagram |

---

## Branch Strategy

- `main` - Production-ready code
- `feature/github-actions` - Previous feature branch (merged)

---

## Testing Commands

```bash
# Backend tests
cd backend
PYTHONPATH=. pytest tests/ -v

# Frontend build
cd frontend
npm run build

# Run locally
cd backend && uvicorn server:app --port 8002
cd frontend && REACT_APP_BACKEND_URL=http://localhost:8002 npm start
```

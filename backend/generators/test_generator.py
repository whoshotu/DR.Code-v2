import ast
import re
import subprocess
from typing import Any, Dict, List, Optional, Tuple

import requests


class FunctionInfo:
    def __init__(
        self,
        name: str,
        params: List[str],
        return_annotation: Optional[str],
        is_async: bool,
        decorators: List[str],
    ):
        self.name = name
        self.params = params
        self.return_annotation = return_annotation
        self.is_async = is_async
        self.decorators = decorators

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "params": self.params,
            "return_annotation": self.return_annotation,
            "is_async": self.is_async,
            "decorators": self.decorators,
        }


def extract_python_functions(code: str) -> List[FunctionInfo]:
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return []

    functions = []
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            params = [arg.arg for arg in node.args.args]
            return_annotation = None
            if node.returns:
                return_annotation = ast.unparse(node.returns)

            decorators = [ast.unparse(d) for d in node.decorator_list]

            functions.append(
                FunctionInfo(
                    name=node.name,
                    params=params,
                    return_annotation=return_annotation,
                    is_async=False,
                    decorators=decorators,
                )
            )
        elif isinstance(node, ast.AsyncFunctionDef):
            params = [arg.arg for arg in node.args.args]
            return_annotation = None
            if node.returns:
                return_annotation = ast.unparse(node.returns)

            decorators = [ast.unparse(d) for d in node.decorator_list]

            functions.append(
                FunctionInfo(
                    name=node.name,
                    params=params,
                    return_annotation=return_annotation,
                    is_async=True,
                    decorators=decorators,
                )
            )

    return functions


def extract_js_functions(code: str) -> List[FunctionInfo]:
    functions = []

    func_pattern = r"(?:function\s+(\w+)|const\s+(\w+)\s*=\s*(?:async\s*)?\(?.*?\)?\s*=>)"
    arrow_params_pattern = r"const\s+(\w+)\s*=\s*(?:async\s*)?\((.*?)\)"

    for match in re.finditer(r"function\s+(\w+)\s*\((.*?)\)", code):
        name = match.group(1)
        params_str = match.group(2)
        params = [p.strip().split(":")[0].strip() for p in params_str.split(",") if p.strip()]
        functions.append(
            FunctionInfo(
                name=name,
                params=params,
                return_annotation=None,
                is_async=False,
                decorators=[],
            )
        )

    for match in re.finditer(r"const\s+(\w+)\s*=\s*(?:async\s*)?\((.*?)\)\s*=>", code):
        name = match.group(1)
        params_str = match.group(2)
        params = [p.strip().split(":")[0].strip() for p in params_str.split(",") if p.strip()]
        functions.append(
            FunctionInfo(
                name=name,
                params=params,
                return_annotation=None,
                is_async=False,
                decorators=[],
            )
        )

    return functions


def extract_functions(code: str, language: str) -> List[FunctionInfo]:
    language = language.lower()
    if language in ("python", "py"):
        return extract_python_functions(code)
    elif language in ("javascript", "js", "typescript", "ts"):
        return extract_js_functions(code)
    return []


def build_test_prompt(
    code: str,
    language: str,
    framework: str,
    functions: List[FunctionInfo],
    include_edge_cases: bool,
) -> str:
    lang = language.lower()
    framework_lower = framework.lower()

    framework_info = {
        "pytest": "pytest - use `pytest.raises()` for exceptions, `assert` statements",
        "unittest": "unittest.TestCase - use `self.assertEqual()`, `self.assertRaises()`",
        "vitest": "vitest - use `expect()`, `test()`, `describe()`",
        "jest": "jest - use `expect()`, `test()`, `describe()`",
    }.get(framework_lower, "pytest")

    edge_case_instruction = ""
    if include_edge_cases:
        edge_case_instruction = """
Include edge cases:
- Empty values (empty string, empty list, 0, None)
- Maximum/minimum values
- Invalid input types (should raise appropriate errors)
- Boundary conditions"""

    prompt = f"""Generate unit tests for the following {lang} code.
Framework: {framework_info}

Source Code:
```{lang}
{code}
```

Functions to test: {", ".join(f.name for f in functions)}
{edge_case_instruction}

Return ONLY the test code, no explanations. Start with imports."""

    return prompt


def validate_python_syntax(code: str) -> Tuple[bool, Optional[str]]:
    try:
        ast.parse(code)
        return True, None
    except SyntaxError as e:
        return False, str(e)


def validate_js_syntax(code: str) -> Tuple[bool, Optional[str]]:
    try:
        result = subprocess.run(
            ["node", "-e", f"require('esm')({repr('module.exports = ' + code)})"],
            capture_output=True,
            timeout=5,
        )
        if result.returncode != 0:
            error = result.stderr.decode() if result.stderr else "Unknown error"
            return False, error
        return True, None
    except FileNotFoundError:
        return True, None
    except subprocess.TimeoutExpired:
        return False, "Timeout validating syntax"
    except Exception as e:
        return False, str(e)


def validate_syntax(code: str, language: str) -> Tuple[bool, Optional[str]]:
    language = language.lower()
    if language in ("python", "py"):
        return validate_python_syntax(code)
    elif language in ("javascript", "js", "typescript", "ts"):
        return validate_js_syntax(code)
    return True, None


def call_llm_for_tests(prompt: str, settings_doc: Optional[Dict[str, Any]] = None) -> Optional[str]:
    try:
        if settings_doc is None:
            import asyncio
            from server import get_or_create_settings_doc

            async def get_settings():
                return await get_or_create_settings_doc()

            settings_doc = asyncio.run(get_settings())

        providers = settings_doc.get("providers", {})
        routing = settings_doc.get("routing", {})
        primary = routing.get("primary_provider", "ollama")

        if primary == "ollama":
            ollama_conf = providers.get("ollama", {})
            base_url = ollama_conf.get("base_url", "http://localhost:11434")
            model = ollama_conf.get("model", "llama3.1:8b")

            response = requests.post(
                f"{base_url.rstrip('/')}/api/generate",
                json={"model": model, "prompt": prompt, "stream": False},
                timeout=60,
            )
            if response.status_code == 200:
                return response.json().get("response")
        return None
    except Exception:
        return None


def generate_tests(
    code: str,
    language: str,
    framework: str = "pytest",
    include_edge_cases: bool = True,
) -> Dict[str, Any]:
    functions = extract_functions(code, language)

    if not functions:
        return {
            "success": False,
            "error": "No functions found in code",
            "test_code": "",
            "test_count": 0,
            "functions_tested": [],
            "coverage_notes": "",
        }

    prompt = build_test_prompt(code, language, framework, functions, include_edge_cases)

    test_code = call_llm_for_tests(prompt)

    if not test_code:
        return {
            "success": False,
            "error": "Failed to generate tests - LLM unavailable",
            "test_code": "",
            "test_count": 0,
            "functions_tested": [],
            "coverage_notes": "",
        }

    valid, syntax_error = validate_syntax(test_code, language)
    if not valid:
        return {
            "success": False,
            "error": f"Generated code has syntax errors: {syntax_error}",
            "test_code": test_code,
            "test_count": 0,
            "functions_tested": [],
            "coverage_notes": "",
        }

    test_count = len([line for line in test_code.split("\n") if "def test_" in line or "it(" in line or "test(" in line])

    coverage_notes = f"Generated {test_count} test(s) for {len(functions)} function(s): {', '.join(f.name for f in functions)}"

    return {
        "success": True,
        "error": "",
        "test_code": test_code,
        "test_count": test_count,
        "functions_tested": [f.name for f in functions],
        "coverage_notes": coverage_notes,
    }

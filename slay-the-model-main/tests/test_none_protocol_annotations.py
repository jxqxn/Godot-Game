import ast
from pathlib import Path


ROOTS = ("actions", "cards", "powers", "relics", "enemies", "player", "rooms", "events", "engine")


def _python_files():
    for root in ROOTS:
        root_path = Path(root)
        if not root_path.exists():
            continue
        yield from root_path.rglob("*.py")


def test_no_legacy_list_action_annotations_on_none_protocol():
    offenders = []

    for path in _python_files():
        source = path.read_text(encoding="utf-8-sig", errors="replace")
        tree = ast.parse(source, filename=str(path))

        for node in ast.walk(tree):
            if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            if not (
                node.name == "execute"
                or node.name == "execute_intention"
                or node.name.startswith("on_")
            ):
                continue
            if node.returns is None:
                continue

            annotation = ast.unparse(node.returns)
            if "List" in annotation:
                offenders.append(f"{path}:{node.lineno}:{node.name}:{annotation}")

    assert not offenders, "Legacy List-return annotations remain:\n" + "\n".join(offenders)


def test_no_useless_terminal_return_in_none_functions():
    offenders = []

    for path in _python_files():
        source = path.read_text(encoding="utf-8-sig", errors="replace")
        tree = ast.parse(source, filename=str(path))

        for node in ast.walk(tree):
            if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            if node.returns is None or ast.unparse(node.returns) != "None":
                continue
            if not node.body:
                continue
            if not isinstance(node.body[-1], ast.Return) or node.body[-1].value is not None:
                continue

            offenders.append(f"{path}:{node.lineno}:{node.name}")

    assert not offenders, "Terminal bare returns remain in None functions:\n" + "\n".join(offenders)

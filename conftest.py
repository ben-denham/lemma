import hy
from _pytest.python import Module


def pytest_collect_file(path, parent):
    """Load .hy test modules."""
    if path.ext == ".hy" and (path.basename.startswith("test_") or path.basename.endswith("_test")):
        return Module.from_parent(parent, fspath=path)

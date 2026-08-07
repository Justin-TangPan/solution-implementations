import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.tests import runner


class RunnerLayoutTest(unittest.TestCase):
    def test_find_unlisted_practices(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "formal").mkdir()
            (root / "draft").mkdir()
            config = {
                "formal": {"practices": ["formal"]},
                "quality_gate": {"reject_unlisted_practice_dirs": True},
            }
            with patch.object(runner, "PRACTICES_DIR", root):
                self.assertEqual(runner.find_unlisted_practices(config), ["draft"])

    def test_discovers_implicit_standard_and_explicit_variants(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            standard = root / "demo/cn/cn-north-4"
            ha = root / "demo/intl/ap-southeast-1/ha"
            standard.mkdir(parents=True)
            ha.mkdir(parents=True)
            (standard / "deploying-demo.tf").write_text("")
            (ha / "deploying-demo.tf").write_text("")
            config = {"formal": {"practices": ["demo"]}}
            with patch.object(runner, "PRACTICES_DIR", root), patch.object(runner, "load_project_config", return_value=config):
                entries = runner.discover_practices()
            self.assertEqual(
                [(entry["site"], entry["region"], entry["deploy_type"]) for entry in entries],
                [("cn", "cn-north-4", "standard"), ("intl", "ap-southeast-1", "ha")],
            )


if __name__ == "__main__":
    unittest.main()

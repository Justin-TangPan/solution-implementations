import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.tests.checks import tf_syntax


TF = '''
terraform { required_providers { huaweicloud = { source = "huawei.com/provider/huaweicloud" } } }
provider "huaweicloud" { region = "cn-north-4" }
resource "huaweicloud_compute_instance" "ecs" {
  user_data = <<-EOF
    #!/bin/bash
    echo ok
  EOF
}
'''


class QualityGateTest(unittest.TestCase):
    def fixture(self, *texts):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        for index, text in enumerate(texts):
            (root / f"deploying-demo{index}.tf").write_text(text)
        self.addCleanup(tmp.cleanup)
        return root

    def test_requires_one_parseable_template(self):
        self.assertFalse([result for result in tf_syntax.run(self.fixture(TF), {}) if not result.passed])
        results = tf_syntax.run(self.fixture(TF, TF), {})
        self.assertTrue(any(not result.passed and "只有一个" in result.message for result in results))

    def test_allows_confirmed_provider_set(self):
        ha = TF.replace(
            'huaweicloud = { source = "huawei.com/provider/huaweicloud" }',
            'huaweicloud = { source = "huawei.com/provider/huaweicloud" } '
            'kubernetes = { source = "hashicorp/kubernetes" }',
        )
        config = {"quality_gate": {"architecture_exceptions": {
            "demo/*/ha": {"allowed_providers": ["huaweicloud", "kubernetes"]}
        }}}
        entry = {"name": "demo", "site": "cn", "region": "test", "deploy_type": "ha"}
        with patch.object(tf_syntax, "load_project_config", return_value=config):
            results = tf_syntax.run(self.fixture(ha), entry)
        self.assertFalse([result for result in results if not result.passed])

if __name__ == "__main__":
    unittest.main()

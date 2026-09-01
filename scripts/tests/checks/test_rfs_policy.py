import hashlib
import tempfile
import unittest
from pathlib import Path

from . import rfs_policy


class ExternalBootstrapPolicyTest(unittest.TestCase):
    def test_accepts_checked_external_bootstrap(self):
        with tempfile.TemporaryDirectory() as tmp:
            practice = Path(tmp)
            script = practice / "scripts" / "install_demo.sh"
            script.parent.mkdir()
            script.write_text("#!/bin/bash\nexit 0\n", encoding="utf-8")
            checksum = hashlib.sha256(script.read_bytes()).hexdigest()
            (practice / "deploying-demo.tf").write_text(
                f'''locals {{
  install_script_url    = "https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/deploying-demo/userdata/install_demo.sh"
  install_script_sha256 = "{checksum}"
}}
resource "example" "demo" {{
  user_data = <<-EOT
#!/bin/bash
curl -fL "${{local.install_script_url}}" -o /tmp/install_demo.sh
echo "${{local.install_script_sha256}}  /tmp/install_demo.sh" | sha256sum -c -
/tmp/install_demo.sh
EOT
}}
''',
                encoding="utf-8",
            )

            results = rfs_policy.run(practice, {"name": "demo"})

            self.assertTrue(all(result.passed for result in results), results)


if __name__ == "__main__":
    unittest.main()

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.tests.checks import rfs_policy


POLICY = {
    "single_active_template": True,
    "inline_user_data": True,
    "forbidden_variables": ["frontend_port"],
    "eip": {"default_bandwidth": 300, "charging_mode": "postPaid", "bandwidth_charge_mode": "traffic"},
    "official_default_interface": {"port": 5173, "remote_ip_prefix": "0.0.0.0/0", "do_not_override_runtime_port": True},
}

VALID = '''
variable "bandwidth_size" { default = 300 }
resource "huaweicloud_networking_secgroup_rule" "web" {
  ports = 5173
  remote_ip_prefix = "0.0.0.0/0"
}
resource "huaweicloud_vpc_eip" "eip" {
  bandwidth { charge_mode = "traffic" }
  charging_mode = "postPaid"
}
resource "huaweicloud_compute_instance" "ecs" { user_data = "inline" }
'''


class RfsPolicyTest(unittest.TestCase):
    def run_policy(self, text=VALID):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "openjiuwen/cn/cn-north-4/jiuwenswarm"
            root.mkdir(parents=True)
            (root / "deploying-jiuwenswarm_v3.tf").write_text(text)
            config = {"quality_gate": {"practice_policies": {"openjiuwen/cn/cn-north-4/jiuwenswarm": POLICY}}}
            with patch.object(rfs_policy, "load_project_config", return_value=config):
                return rfs_policy.run(root, {})

    def test_valid_policy(self):
        self.assertTrue(all(result.passed for result in self.run_policy()))

    def test_forbidden_variable_fails(self):
        results = self.run_policy(VALID + '\nvariable "frontend_port" { default = 5173 }')
        self.assertTrue(any(not result.passed and "frontend_port" in result.message for result in results))

    def test_cross_variable_validation_fails(self):
        text = VALID + '\nvariable "charging_period" { validation { condition = var.charging_unit == "month" } }'
        results = self.run_policy(text)
        self.assertTrue(any(not result.passed and "其他变量" in result.message for result in results))

    def test_external_requirements_fails(self):
        text = VALID + '\nresource "x" "y" { user_data = "curl https://example.com/requirements.lock" }'
        results = self.run_policy(text)
        self.assertTrue(any(not result.passed and "依赖锁" in result.message for result in results))


if __name__ == "__main__":
    unittest.main()

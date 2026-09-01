#!/usr/bin/env python3
"""
SAC Workflow Engine
===================
编排多阶段 Practice 开发工作流。

用法:
  python workflows/engine.py start new-practice --inputs '{"project_name": "redis", "site": "cn", "region": "cn-north-4"}'
  python workflows/engine.py status
  python workflows/engine.py next
  python workflows/engine.py complete --phase architect --results '{"architecture_contract": {...}}'
  python workflows/engine.py validate --phase builder --results '{...}'
  python workflows/engine.py reset

状态文件: .var/workflow-state.json
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

try:
    import yaml
except ImportError:
    yaml = None

# ── 路径 ──────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
STATE_FILE = ROOT / ".var" / "workflow-state.json"
WORKFLOWS_DIR = ROOT / "workflows"
SCHEMAS_DIR = WORKFLOWS_DIR / "schemas"


# ── 工具函数 ──────────────────────────────────────────
def _load_yaml(path: Path) -> Optional[dict]:
    if not yaml:
        print(json.dumps({"error": "PyYAML 未安装，请执行: pip install pyyaml"}))
        return None
    if not path.exists():
        return None
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def _load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    return {}


def _save_state(state: dict):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def _run_cmd(cmd: list[str], cwd: Optional[Path] = None) -> dict:
    """运行 shell 命令并返回结果。"""
    try:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=60)
        return {
            "command": " ".join(cmd),
            "exit_code": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
        }
    except FileNotFoundError:
        return {"command": " ".join(cmd), "exit_code": 127, "stderr": "命令未找到"}
    except subprocess.TimeoutExpired:
        return {"command": " ".join(cmd), "exit_code": -1, "stderr": "超时"}


# ── Gate 验证器 ──────────────────────────────────────
def _validate_contract_complete(results: dict) -> dict:
    """验证架构合同是否包含所有必填字段。"""
    contract = results.get("architecture_contract", {})
    required = ["project", "site", "region", "variant", "components",
                "variables", "bootstrap_url", "bootstrap_sha256"]
    missing = [f for f in required if f not in contract]
    if missing:
        return {"passed": False, "errors": [f"缺少必填字段: {missing}"]}
    # 验证 SHA-256 格式
    sha = contract.get("bootstrap_sha256", "")
    if sha and not (len(sha) == 64 and all(c in "0123456789abcdefABCDEF" for c in sha)):
        return {"passed": False, "errors": ["bootstrap_sha256 格式不正确（需 64 位十六进制）"]}
    return {"passed": True, "errors": []}


def _validate_terraform_valid(results: dict, practice_dir: Optional[str] = None) -> dict:
    """验证 Terraform 文件。"""
    errors = []
    warnings = []

    # 1. terraform fmt -check
    if practice_dir and Path(practice_dir).exists():
        fmt_result = _run_cmd(["terraform", "fmt", "-check", practice_dir])
        if fmt_result["exit_code"] != 0:
            errors.append(f"terraform fmt -check 失败: {fmt_result['stderr']}")

        # 2. bash -n 检查 bootstrap 脚本
        script_path = results.get("bootstrap_script")
        if script_path and Path(script_path).exists():
            bash_result = _run_cmd(["bash", "-n", script_path])
            if bash_result["exit_code"] != 0:
                errors.append(f"bash -n 失败: {bash_result['stderr']}")

        # 3. rfs_policy 检查
        from scripts.tests.checks.rfs_policy import run as rfs_check
        # 构造 entry
        entry = {"name": Path(practice_dir).parent.name}
        check_results = rfs_check(Path(practice_dir), entry)
        for cr in check_results:
            if cr.level == "ERROR":
                errors.append(f"rfs_policy: {cr.message}")
            elif cr.level == "WARNING":
                warnings.append(f"rfs_policy: {cr.message}")

        # 4. 运行测试 runner
        runner_result = _run_cmd([
            sys.executable, "-m", "scripts.tests.runner"
        ], cwd=ROOT)
        if runner_result["exit_code"] != 0:
            errors.append(f"测试 runner 失败: {runner_result['stderr']}")
    else:
        warnings.append("practice_dir 未指定或不存在，跳过部分检查")

    return {"passed": len(errors) == 0, "errors": errors, "warnings": warnings}


def _validate_no_blocker(results: dict) -> dict:
    """验证审查结果中无 blocker。"""
    findings = results.get("review_findings", [])
    blockers = [f for f in findings if f.get("severity") == "blocker"]
    if blockers:
        return {
            "passed": False,
            "errors": [f"发现 {len(blockers)} 个 blocker: {[b['id'] for b in blockers]}"]
        }
    return {"passed": True, "errors": []}


def _validate_docs_valid(results: dict) -> dict:
    """验证文档是否生成。"""
    docs = results.get("documents", {})
    required = ["deployment_guide", "solution_details"]
    missing = [d for d in required if d not in docs]
    if missing:
        return {"passed": False, "errors": [f"缺少文档: {missing}"]}
    return {"passed": True, "errors": []}


def _validate_delivery_complete(results: dict) -> dict:
    """验证交付是否完成。"""
    if not results.get("delivery_archive"):
        return {"passed": False, "errors": ["缺少 delivery_archive"]}
    if not results.get("checksums"):
        return {"passed": False, "errors": ["缺少 checksums"]}
    return {"passed": True, "errors": []}


GATE_VALIDATORS = {
    "contract_complete": _validate_contract_complete,
    "terraform_valid": _validate_terraform_valid,
    "no_blocker": _validate_no_blocker,
    "docs_valid": _validate_docs_valid,
    "delivery_complete": _validate_delivery_complete,
}


# ── Workflow Engine 类 ────────────────────────────────
class WorkflowEngine:
    def __init__(self, state_file: Path = STATE_FILE):
        self.state_file = state_file
        self.state = _load_state()

    def _get_workflow(self, name: str) -> Optional[dict]:
        wf_file = WORKFLOWS_DIR / f"{name}.yaml"
        if not wf_file.exists():
            return None
        return _load_yaml(wf_file)

    def _get_current_phase(self) -> Optional[dict]:
        if not self.state or not self.state.get("current_phase"):
            return None
        wf = self.state.get("workflow", {})
        for p in wf.get("phases", []):
            if p["id"] == self.state["current_phase"]:
                return p
        return None

    def start(self, workflow_name: str, inputs: dict) -> dict:
        wf = self._get_workflow(workflow_name)
        if not wf:
            return {"error": f"工作流不存在: {workflow_name}", "available": self._list_workflows()}

        if not wf.get("phases"):
            return {"error": f"工作流无阶段定义: {workflow_name}"}

        workflow_id = f"{workflow_name}-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        self.state = {
            "workflow_id": workflow_id,
            "workflow_name": workflow_name,
            "workflow": wf,
            "status": "in_progress",
            "current_phase": wf["phases"][0]["id"],
            "completed_phases": [],
            "created_at": datetime.now().isoformat(),
            "inputs": inputs,
            "outputs": {},
            "gates": {p["id"]: "pending" for p in wf["phases"]}
        }
        _save_state(self.state)
        return {
            "status": "started",
            "workflow_id": workflow_id,
            "workflow_name": workflow_name,
            "current_phase": self.state["current_phase"],
            "total_phases": len(wf["phases"]),
        }

    def _list_workflows(self) -> list[str]:
        return [f.stem for f in WORKFLOWS_DIR.glob("*.yaml")]

    def status(self) -> dict:
        if not self.state:
            return {"status": "no_active_workflow", "available": self._list_workflows()}
        wf = self.state.get("workflow", {})
        return {
            "status": "active",
            "workflow_id": self.state["workflow_id"],
            "workflow_name": self.state["workflow_name"],
            "current_phase": self.state["current_phase"],
            "completed_phases": self.state["completed_phases"],
            "total_phases": len(wf.get("phases", [])),
            "gates": self.state.get("gates", {}),
            "created_at": self.state.get("created_at"),
        }

    def next(self) -> dict:
        if not self.state:
            return {"error": "无活跃工作流，请先 start"}

        if self.state.get("status") == "completed":
            return {"error": "工作流已完成"}

        phase = self._get_current_phase()
        if not phase:
            return {"error": "当前阶段不存在"}

        gate = phase.get("gate", {})
        return {
            "phase": phase["id"],
            "skill": phase.get("skill"),
            "description": phase.get("description", ""),
            "inputs": phase.get("inputs", []),
            "outputs": phase.get("outputs", []),
            "gate": {
                "type": gate.get("type"),
                "schema": gate.get("schema"),
            },
            "instructions": self._build_instructions(phase),
        }

    def _build_instructions(self, phase: dict) -> str:
        """为 Agent 构建阶段执行指令。"""
        skill = phase.get("skill", "")
        inputs = phase.get("inputs", [])
        outputs = phase.get("outputs", [])
        gate_type = phase.get("gate", {}).get("type", "")

        lines = [
            f"# 阶段: {phase['id']}",
            f"# 加载技能: {skill}",
            "",
            f"1. 读取 {skill}/SKILL.md 并执行其中的业务规则",
        ]
        if inputs:
            lines.append(f"2. 输入参数: {', '.join(inputs)}")
        if outputs:
            lines.append(f"3. 输出产物: {', '.join(outputs)}")
        if gate_type:
            lines.append(f"4. 完成后调用: python workflows/engine.py complete --phase {phase['id']} --results '{{...}}'")
            lines.append(f"5. 引擎将验证 gate: {gate_type}")
        return "\n".join(lines)

    def complete(self, phase_id: str, results: dict) -> dict:
        if not self.state:
            return {"error": "无活跃工作流"}

        if self.state.get("status") == "completed":
            return {"error": "工作流已完成"}

        if phase_id != self.state["current_phase"]:
            return {
                "error": f"阶段不匹配",
                "expected": self.state["current_phase"],
                "got": phase_id,
            }

        # 存储结果
        self.state["outputs"][phase_id] = results

        # 验证 gate
        phase = self._get_current_phase()
        gate_config = phase.get("gate", {}) if phase else {}
        gate_type = gate_config.get("type")

        if gate_type and gate_type in GATE_VALIDATORS:
            # 提取 practice_dir 用于 terraform 验证
            extra = {}
            if gate_type == "terraform_valid":
                extra["practice_dir"] = results.get("practice_dir")
            gate_result = GATE_VALIDATORS[gate_type](results, **extra)
        else:
            gate_result = {"passed": True, "errors": []}

        if gate_result["passed"]:
            # 通过：进入下一阶段
            self.state["completed_phases"].append(phase_id)
            self.state["gates"][phase_id] = "passed"

            wf = self.state["workflow"]
            phases = wf.get("phases", [])
            current_idx = next(
                (i for i, p in enumerate(phases) if p["id"] == phase_id), -1
            )

            if current_idx + 1 < len(phases):
                self.state["current_phase"] = phases[current_idx + 1]["id"]
                _save_state(self.state)
                return {
                    "status": "phase_complete",
                    "phase": phase_id,
                    "gate": "passed",
                    "next_phase": self.state["current_phase"],
                }
            else:
                self.state["status"] = "completed"
                self.state["current_phase"] = None
                _save_state(self.state)
                return {
                    "status": "workflow_complete",
                    "phase": phase_id,
                    "gate": "passed",
                    "all_phases": [p["id"] for p in phases],
                }
        else:
            # 未通过：停留在当前阶段
            self.state["gates"][phase_id] = "failed"
            _save_state(self.state)
            return {
                "status": "gate_failed",
                "phase": phase_id,
                "gate": "failed",
                "errors": gate_result.get("errors", []),
                "warnings": gate_result.get("warnings", []),
            }

    def validate(self, phase_id: str, results: dict) -> dict:
        """验证阶段结果但不推进。"""
        phase = None
        wf = self.state.get("workflow", {}) if self.state else {}
        for p in wf.get("phases", []):
            if p["id"] == phase_id:
                phase = p
                break
        if not phase:
            return {"error": f"阶段不存在: {phase_id}"}

        gate_type = phase.get("gate", {}).get("type")
        if not gate_type or gate_type not in GATE_VALIDATORS:
            return {"passed": True, "errors": [], "warnings": [], "gate": None}

        extra = {}
        if gate_type == "terraform_valid":
            extra["practice_dir"] = results.get("practice_dir")
        result = GATE_VALIDATORS[gate_type](results, **extra)
        result["gate"] = gate_type
        return result

    def reset(self) -> dict:
        self.state = {}
        if STATE_FILE.exists():
            STATE_FILE.unlink()
        return {"status": "reset"}


# ── CLI ───────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="SAC Workflow Engine")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # start
    p_start = subparsers.add_parser("start", help="启动工作流")
    p_start.add_argument("workflow", help="工作流名称")
    p_start.add_argument("--inputs", type=json.loads, default={}, help="JSON 格式输入参数")

    # status
    subparsers.add_parser("status", help="查看当前状态")

    # next
    subparsers.add_parser("next", help="获取下一阶段")

    # complete
    p_complete = subparsers.add_parser("complete", help="完成当前阶段")
    p_complete.add_argument("--phase", required=True, help="阶段 ID")
    p_complete.add_argument("--results", type=json.loads, default={}, help="JSON 格式结果")

    # validate
    p_validate = subparsers.add_parser("validate", help="验证阶段结果（不推进）")
    p_validate.add_argument("--phase", required=True, help="阶段 ID")
    p_validate.add_argument("--results", type=json.loads, default={}, help="JSON 格式结果")

    # reset
    subparsers.add_parser("reset", help="重置工作流")

    args = parser.parse_args()
    engine = WorkflowEngine()

    if args.command == "start":
        result = engine.start(args.workflow, args.inputs)
    elif args.command == "status":
        result = engine.status()
    elif args.command == "next":
        result = engine.next()
    elif args.command == "complete":
        result = engine.complete(args.phase, args.results)
    elif args.command == "validate":
        result = engine.validate(args.phase, args.results)
    elif args.command == "reset":
        result = engine.reset()

    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

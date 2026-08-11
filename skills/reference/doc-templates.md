# 文档模板结构（公共参考文档）

> 本文档定义了 SAC 项目交付文档的标准章节结构。各 Agent 通过引用本文档避免重复。

## 部署指南（Deployment Guide）

标准文件名：
- 中文正文：`{Name}-部署指南_zh.md`
- 英文正文：`{Name}-Deployment-Guide_en.md`

参考模板：基于 LiteLLM 部署指南提取的标准结构

```
1. 方案概述 / Solution Overview
   1.1 应用场景 / Use Cases（3 个场景）
   1.2 方案架构 / Architecture（单机版 + 高可用版架构图 + 资源清单）
   1.3 方案优势 / Key Advantages（3-4 个核心优势）
   1.4 约束与限制 / Constraints（3-5 条注意事项）

2. 资源与成本规划 / Resources & Cost Planning
   2.1 单机版部署
       — 使用 `query-huawei-cloud-prices` 技能/脚本对每个已确定的计费资源进行系统询价
       — 展示接口返回的按需（on-demand）、包月（monthly）、包年（yearly）三种计费模式价格
       — 价格表保留接口返回的币种、计量单位、阶梯价格和数量关系，标注查询日期及”参考报价，最终以账单为准”
       — 接口无法解析的产品/区域/规格时，对应行标记为”待询价 / Price to be confirmed”并记录查询错误到人工审校项，不得估算或沿用历史价格
   2.2 高可用版部署（可选，同上规则）

3. 实施步骤 / Deployment Steps
   3.1 准备工作 / Preparation（账号检查、委托创建、API Key 获取）
   3.2 快速部署 / Quick Deploy（RFS 参数配置 + 部署操作）
   3.3 开始使用 / Getting Started（配置引导 + 功能验证）
   3.4 快速卸载 / Uninstall（RFS 资源栈删除）

4. 附录 / Appendix
   4.1 名词解释 / Glossary
   4.2 参考文档 / References

5. 修订记录 / Revision History
```

## 方案详情（Solution Details）

标准文件名：
- 中文正文：`{Name}-方案详情_zh.md`
- 英文正文：`{Name}-Solution-Details_en.md`

```
1. 解决方案概述 / Solution Overview
2. 方案优势 / Key Advantages
3. 架构与部署方式 / Architecture & Deployment Options
4. 应用场景 / Use Cases
5. 相关解决方案 / Related Solutions
6. 支持区域 / Available Regions
7. 预估成本 / Estimated Cost
8. 服务亮点 / Service Highlights
```

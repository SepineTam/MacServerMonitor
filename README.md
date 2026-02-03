# MacServerMonitor

专业的 macOS 设备监控解决方案，支持单设备和多设备场景。

<p align="center">
  <img src="Resources/MacServerMonitor_Logo.png" alt="MacServerMonitor Logo" width="200"/>
</p>

[![Release](https://img.shields.io/github/v/release/SepineTam/MacServerMonitor)](https://github.com/SepineTam/MacServerMonitor/releases)
[![License](https://img.shields.io/github/license/SepineTam/MacServerMonitor)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos)

> **Note:** This project was developed with assistance from AI tools.

MacServerMonitor 是一个轻量级的 macOS 设备监控工具，专为作为服务器使用的 Mac 设备设计。

它专注于关键系统资源，提供：
- 清晰的实时监控
- 可配置的阈值告警
- 局域网多设备统一监控
- 完善的告警历史管理

同时保持低能耗和最小的系统开销。

---

## ✨ 主要功能

### 📊 资源监控
- **内存使用** - 实时内存占用和百分比
- **CPU 使用** - CPU 使用率监控
- **磁盘使用** - 磁盘空间百分比
- **网络状态** - 网络连接检测

### 🔔 智能告警
- **可配置阈值** - 内存、CPU、磁盘、网络独立配置
- **告警历史** - 完整的告警事件记录（最多 1000 条，保留 30 天）
- **告警级别** - 警告/严重两级自动分类
- **告警静默** - 快速静默（1h/4h/24h/永久）和定时静默
- **声音提醒** - 系统通知声音，可配置重复间隔
- **数据导出** - 支持 CSV 和 JSON 格式

### 🖥️ 多设备监控
- **自动发现** - 自动发现局域网内的设备
- **统一视图** - 卡片/列表两种展示模式
- **设备管理** - 设备管理器（⌘+D）
- **实时数据** - HTTP API 获取远程设备数据

### 🎨 界面体验
- **深色模式** - Light/Dark 双主题支持
- **简洁设计** - 直观的可视化指标
- **快速刷新** - 可选 5s/10s/30s 刷新间隔
- **快捷键** - ⌘+, 设置 / ⌘+D 设备 / ⌘+H 告警历史

---

## 🎯 设计原则

- **简单优先** - 零配置，开箱即用
- **性能至上** - 低资源占用，快速响应
- **可靠稳定** - 崩溃恢复，数据安全
- **用户驱动** - 根据反馈快速迭代
- **开放扩展** - API 优先，插件友好

---

## 🚀 快速开始

### 方法 1: 下载安装（推荐）

从 [Releases](https://github.com/SepineTam/MacServerMonitor/releases) 页面下载最新版本：

1. **DMG 安装**（推荐）
   - 下载 `MacServerMonitor-VERSION.dmg`
   - 双击挂载
   - 拖拽到 Applications 文件夹

2. **ZIP 安装**
   - 下载 `MacServerMonitor-VERSION.zip`
   - 解压
   - 移动到 Applications 文件夹

### 方法 2: 从源码构建

```bash
# 克隆仓库
git clone https://github.com/SepineTam/MacServerMonitor.git
cd MacServerMonitor

# 构建发布版本
./build.sh v1.2.0

# 输出文件：
# - build/MacServerMonitor.app
# - build/MacServerMonitor-v1.2.0.zip
# - build/MacServerMonitor-v1.2.0.dmg
```

---

## 📖 使用指南

### 基本监控

启动应用后，会自动显示本地设备的实时监控数据：
- 内存使用率
- CPU 使用率
- 磁盘使用率
- 网络连接状态

### 配置告警

1. 点击右上角齿轮图标（或按 ⌘+,）
2. 调整各项指标的阈值
3. 配置告警行为（连续采样次数、重复间隔）
4. 启用/禁用 HTTP 服务器

### 多设备监控

1. 确保所有设备在同一局域网
2. 所有设备启动 MacServerMonitor
3. 应用会自动发现彼此
4. 点击设备管理器（⌘+D）查看和管理设备

### 告警历史

1. 点击铃铛图标（或按 ⌘+H）
2. 查看所有历史告警事件
3. 按设备、类型、级别、状态筛选
4. 导出为 CSV 或 JSON 格式

### 告警静默

1. 打开设置 → Alert Silence → 设置
2. 选择快速静默选项
3. 或添加定时静默规则（如夜间 22:00-08:00）

---

## 🛠️ 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI
- **系统**: macOS 13.0+
- **架构**: MVVM + 单例模式
- **存储**: UserDefaults
- **网络**: URLSession + HTTP Server

---

## 🗺️ 开发路线

详见 [ROADMAP.md](ROADMAP.md)

### 已完成 ✅
- v1.0.0 - 核心监控功能
- v1.0.2 - 深色模式
- v1.1.0 - 多设备监控
- v1.2.0 - 告警增强

### 计划中 📋
- v1.3.0 - 数据可视化
- v1.4.0 - 设备发现优化
- v1.5.0 - 性能与稳定性

---

## 📝 项目说明

### AI 工具

本项目在开发过程中使用了以下 AI 工具：

- **代码生成**: [Claude Code](https://claude.com/claude-code) by Anthropic
- **Logo 设计**: [Lovart.ai](https://lovart.ai)

特别感谢这些 AI 工具让本项目成为可能。

### 架构特点

- 低能耗设计，适合长时间运行
- 最小系统权限，无需后台守护进程
- 聚焦关键指标，避免信息过载
- 清晰的代码架构，易于扩展

---

## 🤝 贡献

欢迎贡献！请查看 [CLAUDE.md](CLAUDE.md) 了解开发指南。

优先实现的功能：
1. 数据可视化图表
2. 性能优化
3. 文档完善

---

## 📄 许可证

[MIT License](LICENSE)

---

## 📧 联系方式

- **Owner**: Sepine Tam
- **Email**: sepinetam@gmail.com
- **GitHub**: [@SepineTam](https://github.com/SepineTam)

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐️ Star**

</div>

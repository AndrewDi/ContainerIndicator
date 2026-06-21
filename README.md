<p align="center">
  <img src="icons/icon_256x256.png" alt="ContainerIndicator" width="128" />
</p>

<h1 align="center">ContainerIndicator</h1>

<p align="center">
  <strong>中文</strong> | <a href="#english">English</a>
</p>

---

## 中文说明

一个轻量级的 macOS 菜单栏应用，用于监控和管理容器服务、容器实例和虚拟机。

### 功能特性

#### 核心功能

- **系统状态监控**：实时监控容器服务运行状态
- **容器管理**：查看、启动、停止容器实例
- **虚拟机管理**：查看、启动、停止虚拟机
- **自动刷新**：每 5 秒自动检查状态变化，仅在数据更新时刷新界面
- **性能优化**：智能刷新机制，避免不必要的 UI 重绘
- **实时图表**：运行中的容器显示 I/O、CPU、内存、网络四项实时性能图表

#### 界面特性

- **菜单栏集成**：在系统菜单栏显示状态图标，不在 Dock 显示
- **快速操作**：通过菜单栏快速启动/停止容器和虚拟机
- **详细视图**：完整的管理界面，显示所有容器和虚拟机的详细信息
- **多语言支持**：自动根据系统语言切换中文/英文界面
- **窗口可调**：管理窗口支持自由调整大小
- **操作反馈**：操作完成后显示 Toast 提示

### 系统要求

- macOS 13.0 或更高版本
- 需要安装 `container` 命令行工具

### 安装

1. 从 [Releases](<repository-url>/releases) 页面下载最新的 `.dmg` 文件。
2. 打开 `.dmg` 文件，将 `ContainerIndicator` 拖入 `应用程序` 文件夹。
3. 首次运行时，请前往 `系统设置 > 隐私与安全性` 允许应用运行。

---

<div id="english"></div>

## English

A lightweight macOS menu bar application for monitoring and managing container services, container instances, and virtual machines.

### Features

#### Core Features

- **System Status Monitoring** – Real-time monitoring of container service status.
- **Container Management** – View, start, and stop container instances.
- **Virtual Machine Management** – View, start, and stop virtual machines.
- **Auto-refresh** – Automatically checks for status changes every 5 seconds; refreshes the UI only when data updates.
- **Performance Optimized** – Smart refresh mechanism avoids unnecessary UI redraws.
- **Real-time Charts** – Running containers display live charts for I/O, CPU, memory, and network.

#### Interface

- **Menu Bar Integration** – Shows a status icon in the menu bar; does not appear in the Dock.
- **Quick Actions** – Start/stop containers and VMs right from the menu bar.
- **Detailed View** – Full management window showing detailed information for all containers and VMs.
- **Localization** – Automatically switches between Chinese and English based on system language.
- **Resizable Window** – The management window can be freely resized.
- **Operation Feedback** – Toast notifications after each action.

### System Requirements

- macOS 13.0 or later
- `container` command-line tool must be installed

### Installation

1. Download the latest `.dmg` file from the [Releases](<repository-url>/releases) page.
2. Open the `.dmg` file and drag `ContainerIndicator` into the `Applications` folder.
3. On first launch, go to `System Settings > Privacy & Security` to allow the app to run.

# Leigod Plugin — SteamDeck 网络加速器 | 通用 Linux 移植版

[雷神加速器](https://www.leigod.com) 的 SteamDeck 插件，修改后可在 **任意 x86_64 Linux 发行版**（Ubuntu / Debian / Fedora / Arch / openSUSE 等）上运行。伪装为 SteamDeck 硬件，通过手机 App 绑定后即可对游戏进行网络加速。

## 原理

| 机制 | 手段 |
|------|------|
| **硬件伪装** | systemd `BindReadOnlyPaths` 劫持 `/sys/class/dmi/id/product_name` → `Jupiter` |
| **系统伪装** | 同上劫持 `/etc/os-release` → `SteamOS` |
| **网卡伪装** | 创建 `dummy` 类型虚拟 `wlan0`，克隆物理网卡 MAC |
| **路径修复** | `/home/leigod` → `/opt/leigod` 符号链接 |
| **进程管理** | systemd `KillMode=control-group` 确保重启时清理所有子进程 |

## 系统要求

- **架构**: x86_64 (amd64)
- **内核**: Linux（支持 `dummy`、`tun`、`iptables` 模块）
- **init**: systemd v227+
- **依赖**: `ipset`、`curl`

## 快速安装

### 方式一：Debian 系（Ubuntu / Debian / Mint / Kali）

```bash
sudo dpkg -i leigod-plugin_1.2.2.15_amd64.deb
sudo apt install -f   # 自动补全依赖
```

### 方式二：通用 Linux（Arch / Fedora / openSUSE 等）

```bash
tar xzf leigod-plugin_1.2.2.15_amd64.tar.gz
cd leigod-plugin-1.2.2.15
sudo ./install.sh     # 安装脚本自动检测包管理器
```

安装后打开手机雷神加速器 App → 扫码绑定设备 → 开始加速。

## 文件结构

```
leigod-plugin/
├── install.sh                    # 通用安装脚本
├── uninstall.sh                  # 通用卸载脚本
├── opt/leigod/
│   ├── acc-gw.router.amd64       # 雷神加速主程序（静态编译）
│   ├── acc_upgrade_monitor       # 升级监控程序（与主程序相同）
│   ├── steamdeck_acc_monitor.sh  # 进程守护脚本
│   ├── plugin_common.sh          # 雷神官方安装脚本库
│   ├── leigod_uninstall.sh       # 雷神官方卸载脚本
│   ├── fake_os-release           # 伪造 SteamOS 信息
│   ├── fake_product_name         # 伪造 Jupiter 硬件名
│   └── config/
│       ├── accelerator.ini       # 雷神加速器配置
│       ├── accelerator           # OpenWrt 兼容占位文件
│       ├── acc_version.ini       # 版本信息
│       ├── new_upgrade_conf.json # 升级策略配置
│       └── ipdatacloud_country.xdb  # IP 地理位置数据库
├── systemd/
│   └── leigod_plugin.service     # systemd 服务单元
├── debian/                       # dpkg-deb 打包文件
│   ├── control
│   ├── preinst
│   ├── postinst
│   ├── prerm
│   └── postrm
├── packages/
│   ├── build-deb.sh              # 构建 .deb 包
│   └── build-tar.sh              # 构建 .tar.gz 包
└── README.md
```

## 服务管理

```bash
sudo systemctl status  leigod_plugin.service   # 查看状态
sudo systemctl restart leigod_plugin.service   # 重启
sudo systemctl stop    leigod_plugin.service   # 停止
sudo journalctl -xeu   leigod_plugin.service   # 查看日志
```

## 卸载

```bash
# 方式一：Deb 包卸载
sudo dpkg -r leigod-plugin          # 保留配置
sudo dpkg --purge leigod-plugin     # 完全清除

# 方式二：通用卸载
cd leigod-plugin-1.2.2.15
sudo ./uninstall.sh
```

## 从零构建

### 准备

```bash
sudo apt install ipset curl         # Debian 系
sudo pacman -S ipset curl           # Arch 系
sudo dnf install ipset curl         # Fedora 系
```

### 构建安装包

```bash
cd packages
bash build-deb.sh                   # 生成 .deb
bash build-tar.sh                   # 生成 .tar.gz
```

### 直接手动安装（不打包）

```bash
sudo mkdir -p /opt/leigod/config
sudo cp -r opt/leigod/* /opt/leigod/
sudo ln -sf /opt/leigod /home/leigod
sudo cp systemd/leigod_plugin.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now leigod_plugin.service
```

## 常见问题

**Q: 加速无法启动，App 显示错误？**
查看日志定位原因：
```bash
journalctl -xeu leigod_plugin.service
tail -f /tmp/acc/log/acc_daemon.log
```

**Q: 重启后加速失效？**
这是正常行为。加速状态不会持久化，每次需要从 App 重新开启。

**Q: 可以用于 ARM 设备（树莓派）吗？**
不能。雷神只提供了 amd64 二进制。

**Q: 更换网卡后绑定会丢失吗？**
MAC 地址回退到 `/etc/machine-id` 派生值，只要系统未重装则不变。绑定信息同时保存在雷神云端。

## 免责声明

本项目仅供学习研究。雷神加速器是其各自所有者的商标。请遵守当地法律法规。

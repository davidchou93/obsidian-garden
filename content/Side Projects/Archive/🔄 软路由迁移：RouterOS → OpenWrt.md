---

---
**迁移日期**: 待安排

**执行人**: David

**预计耗时**: 2-4 小时

**风险等级**: 中（断网风险）

---

## 📋 迁移前准备（必须完成）

### 1. 备份 PPPoE 拨号信息

**重要性**: ⭐⭐⭐⭐⭐

**操作步骤**:

1. 登录 RouterOS WinBox / WebFig
2. 进入 `Interfaces` → `PPP` → `PPPoE Client`
3. 导出配置: `/interface pppoe-client export`
4. **记录账号密码**（密码可能无法直接查看，需提前保存）

**备用方案**:

- 拨打电信客服 10000 重置密码
- 查看光猫背面标签（部分旧设备有默认账号）

### 2. 备份现有网络配置

**RouterOS 导出命令**:

# 导出完整配置

/system backup save name=routeros-backup-2025

# 导出可读脚本

/export file=routeros-config.rsc

# 查看 PPPoE 账号（密码加密）

/interface pppoe-client print detail

# 导出 DHCP 配置

/ip dhcp-server network print

/ip dhcp-server lease print

# 导出端口转发

/ip firewall nat print where chain=dstnat

# 导出防火墙规则

/ip firewall filter print

### 3. 准备 OpenWrt 固件

**推荐固件**: iStoreOS（基于 OpenWrt，适合中国用户）

**下载地址**: https://fw.koolcenter.com/iStoreOS/

**选择版本**: x86_64（适用于 x86 软路由）

**烧录工具**: Rufus (Windows) / balenaEtcher (macOS)

### 4. 硬件准备

- [ ] 备用路由器（防止配置失败断网）
- [ ] 网线 x3
- [ ] U 盘 / 硬盘（用于烧录固件）
- [ ] 显示器 + 键盘（首次配置用）

---

## 🌐 当前网络拓扑

光猫（桥接模式）

│ PPPoE 拨号

▼

RouterOS 软路由 (10.0.9.1)

│ 网关/DHCP/DNS

▼

├───── Amplifi WiFi (桥接) 10.0.9.113/120

├───── MacMini 10.0.9.101

├───── PVE 10.0.9.110

├───── NAS 10.0.9.121

└───── SmartDNS Container 10.0.9.2

子网: 10.0.9.0/24

DHCP 范围: 待确认

---

## 🔧 迁移步骤

### Phase 1: 安装 OpenWrt

5. 烧录 iStoreOS 固件到 U 盘/硬盘
6. 软路由设置从 U 盘/硬盘启动
7. 首次启动，连接显示器配置：
- 默认 IP: `192.168.100.1`
- 默认密码: `password`
8. 进入 Web 界面 (`http://192.168.100.1`)

### Phase 2: 配置 WAN (PPPoE)

9. 网络 → 接口 → WAN
10. 协议: PPPoE
11. 填写电信账号密码
12. 保存并应用
13. 验证: 状态 → 网络 → 检查 IPv4 连接

### Phase 3: 配置 LAN

14. 网络 → 接口 → LAN
15. 静态地址: `10.0.9.1`
16. 子网掩码: `255.255.255.0`
17. DHCP 服务器:
- 起始: `10.0.9.100`
- 结束: `10.0.9.200`
- 租期: 12小时

### Phase 4: 配置透明代理 (OpenClash)

18. iStore → 应用商店 → 安装 OpenClash
19. 导入现有 Clash 配置（从 Mac mini 复制）
20. 模式: Redir-Host 或 Fake-IP
21. 测试: Apple TV 访问 Netflix/YouTube

### Phase 5: 配置静态 DHCP (保留 IP)

**需要保留的设备**:

- MacMini: `10.0.9.101`
- PVE: `10.0.9.110`
- NAS: `10.0.9.121`
- Amplifi #1: `10.0.9.113`
- Amplifi #2: `10.0.9.120`

### Phase 6: 配置端口转发

**从 RouterOS 导出并迁移**

---

## 🔄 更新：实际网络拓扑（2026-04-13）

### 实际拓扑 vs 原假设

**原假设：** 光猫直连物理软路由设备

**实际拓扑：**

光猫 → 交换机 → PVE Host (物理机)

│

├─► Router VM (RouterOS) 10.0.9.1

└─► NAS VM 10.0.9.121

### VLAN 配置对迁移的影响

由于 Router VM 在 PVE 内部，WAN 流量通过交换机进入 PVE，然后交给 Router VM，这意味着：

**1. PVE 网桥 + VLAN 配置必须保留**

- 检查 `/etc/network/interfaces` 中的 VLAN 设置
- 查看哪些网卡 tagged/untagged

**2. Router VM 的虚拟网卡配置是关键**

- WAN 口：通常是一个桥接接口，带 VLAN tag（如 `eth0.101` 或类似）
- LAN 口：可能是另一个桥接，或者同一网卡不同 VLAN

**3. 迁移方式需要调整**

- 不需要物理替换设备，只需要在 PVE 上新建 OpenWrt VM
- 可以并行运行，通过修改 PVE 网桥连接切换流量

### 建议的新迁移策略

与其"替换设备"，不如：

22. **在 PVE 上新建 OpenWrt VM**（不删除 RouterOS VM）
23. **配置 WAN/LAN 使用同样的虚拟网卡结构**
24. **测试阶段：** 关闭 Router VM，启动 OpenWrt VM，验证网络
25. **回滚简单：** 如果出问题，关闭 OpenWrt，启动 RouterOS 即可

### 下一步行动

- [ ] 查看 RouterOS VM 在 PVE 中的网卡配置
- PVE 面板 → Router VM → Hardware → Network
- [ ] 记录现有 VLAN 配置
- [ ] 导出 RouterOS 完整配置备份

---

## 📋 迁移完成日志（2026-04-15）

### **✅ 已完成**

- 新 VM (ID 102) 创建并运行 iStoreOS
- PPPoE 拨号配置成功，外网连通
- LAN IP: 10.0.9.1/24，DHCP 服务器正常
- RouterOS VM (101) 已禁用自启动（保留备份）
- SmartDNS 配置完成（国内外分流）
- OpenClash 基础安装（TUN 模式）

### **❌ 待解决**

- OpenClash 访问控制：仅 10.0.9.113 走代理，其他设备直连（TUN 模式路由表待调试）
- MetaCubeXD 节点测速失败
- 局域网设备无法访问 YouTube（路由器本身可以）

### **🔄 下一步**

- 调试 OpenClash TUN 模式路由表
- 验证特定 IP 代理是否生效
- 测试 Netflix/YouTube 解锁
- 一周后删除 RouterOS VM (101)
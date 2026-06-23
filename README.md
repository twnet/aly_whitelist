# SSH IP 白名单动态更新系统

通过 GitHub/Gitea 存储加密的 IP 白名单，每 3 分钟自动拉取并更新服务器防火墙规则。
仅允许白名单内的 IP 访问 SSH 22 端口，未授权 IP 一律拒绝。

## 工作原理

```
┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│ whitelist.json│ → 加密 → │ whitelist.enc│ → git push → │  远程仓库     │
│ (本地编辑)    │     │ (加密产物)   │     └──────────────┘
└──────────────┘     └─────────────┘           │
                                               │ curl 拉取
┌──────────────┐     ┌─────────────┐           │
│ ipset+iptables │ ←  │update_firewall│← 解密 ← ┘
│ (防火墙规则)  │     │ .sh (cron/3m) │
└──────────────┘     └─────────────┘
```

## 快速开始

### 1. 在管理机上：生成密码并加密

```bash
cd aly/ssh/

# 生成随机密码
./generate_password.sh

# 创建 .env 文件
cp .env.example .env
# 编辑 .env，设置 ENCRYPTION_PASSWORD 和 REMOTE_URL
vim .env

# 加密 whitelist.json
./encrypter.sh

# 提交到 Git
./auto_update.sh "首次提交白名单"
```

### 2. 在服务器上：一键部署

```bash
# 克隆仓库并进入目录
cd aly/ssh/
sudo ./install.sh
```

安装脚本会：
- 安装依赖（openssl, jq, ipset, iptables, curl, dnsutils）
- 复制脚本到 `/opt/ssh-whitelist/`
- 初始化 `.env`（与加密端使用相同密码和 URL）
- 配置 cron 每 3 分钟执行
- 设置 logrotate

### 3. 更新白名单

在管理机上编辑 `whitelist.json`，然后：

```bash
cd aly/ssh/
./auto_update.sh "添加新IP xxx"
```

服务器将在 3 分钟内自动生效。

## 文件说明

| 文件 | 说明 | 提交 Git |
|------|------|----------|
| `whitelist.json` | 明文白名单配置 | ❌ |
| `whitelist.enc` | 加密后的白名单 | ✅ |
| `.env` | 加密密码和配置 | ❌ |
| `.env.example` | .env 模板 | ✅ |
| `.gitignore` | 忽略规则 | ✅ |
| `generate_password.sh` | 生成随机密码 | ✅ |
| `encrypter.sh` | 加密脚本 | ✅ |
| `decrypter.sh` | 解密脚本 | ✅ |
| `verify_json.sh` | JSON 校验脚本 | ✅ |
| `auto_update.sh` | 加密+提交+推送 | ✅ |
| `update_firewall.sh` | 核心更新脚本 | ✅ |
| `install.sh` | 一键安装 | ✅ |

## 白名单格式 (whitelist.json)

```json
{
  "version": "1.0",
  "updated_at": "2026-06-22T14:30:00Z",
  "description": "Production SSH whitelist",
  "sources": {
    "domains": [
      {"value": "example.com", "note": "描述", "enabled": true}
    ],
    "ips": [
      {"value": "1.2.3.4", "note": "描述", "enabled": true}
    ],
    "urls": [
      {"value": "https://api.example.com/whitelist.json", "note": "远程来源", "enabled": true}
    ]
  }
}
```

- `domains` — DNS 域名，运行时会解析为 IP
- `ips` — 直接 IP 地址
- `urls` — 远程 JSON 端点，应返回 `{"ips": ["1.2.3.4", ...]}`
- `enabled: false` 可临时禁用某个来源

## 常用命令

```bash
# 查看当前 ipset 白名单
ipset list ssh-whitelist

# 查看 iptables SSH 相关规则
iptables -L INPUT -n | head -5

# 查看日志
tail -f /var/log/ssh-whitelist.log

# 手动执行更新
sudo /opt/ssh-whitelist/update_firewall.sh

# 临时添加单个 IP
ipset add ssh-whitelist 1.2.3.4
```

## 安全注意事项

- `.env` 文件存储密码，权限应为 600，绝不提交到 Git
- 加密使用 AES-256-CBC + PBKDF2 (100000 次迭代)
- 如果 `.env` 密码泄露，重新生成密码并重新加密所有文件
- 确保已建立连接规则在 DROP 规则之前，避免锁死

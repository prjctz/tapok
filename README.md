# Tapok Installer

## 3x-ui, TeleMT, MTProtoProxy, RealiTLScanner auto installer
Tested on Debian 12

## Important Notice
This repository contains automation scripts intended **only for educational, research, and system administration purposes**.
The user is solely responsible for how these scripts are used and must ensure compliance with all applicable local laws and regulations.
The author does **not provide any service, access, or guarantee of bypassing restrictions**, and does not encourage or support unlawful usage.

---

## Description
This script automates deployment and configuration of networking tools inside a controlled server environment.

- Uses Docker containers (except 3x-ui)
- Configures encrypted proxy services
- Opens required ports
- Scans network for domain masking candidates
- Applies firewall rules (UFW)
- Generates configuration guide
- Adds additional SSH ports for recovery access

---

## Installation order
The script installs:

- https://github.com/prjctz/installer4
- https://github.com/prjctz/installer2
- https://github.com/prjctz/installer3
- https://github.com/MHSanaei/3x-ui

Refer to official repositories for detailed documentation.

---

## Requirements
- Debian 12
- 1 GB RAM

---

## Quick Start

Run the following command via SSH:

`bash <(wget -qO- https://raw.githubusercontent.com/prjctz/tapok/refs/heads/main/install5.sh)`

---

## Help

`bash <(wget -qO- https://raw.githubusercontent.com/prjctz/tapok/refs/heads/main/install5.sh) --help`

---

## Custom Parameters

`bash <(wget -qO- https://raw.githubusercontent.com/prjctz/tapok/refs/heads/main/install5.sh) --port1=8443 --port2=993 --domain=google.com --ip=203.0.113.10`

Interactive mode is available if you prefer manual input.

---

## Domain Configuration

To configure domain for MTProxy (fake TLS):

- Use `--domain=example.com`
- Or configure manually in interactive mode

If not specified, default value will be used.

---

## Manual Script Editing

```bash
nano script.sh
chmod +x script.sh
./script.sh
```

---

## Firewall Notice

During installation, UFW may prompt for confirmation.
Press Enter to proceed.

---

## SSH Ports

The following ports will be opened:

- 22
- 8445
- 56342

---

## MTProxy Limits

Local control endpoint:

```
http://127.0.0.1:9091/
```

Example request:

```bash
curl -X PATCH http://127.0.0.1:9091/v1/users/bob \
-H "Content-Type: application/json" \
-d '{
    "max_tcp_conns": 5,
    "max_unique_ips": 2
}'
```

---

## Cascading Setup (Theory)

If using multiple servers:

1. Install script on both servers
2. Configure proxy chain via 3x-ui
3. Adjust routing between servers

---

## Disclaimer

This software is provided **“as is” without warranties of any kind**.
The author is not responsible for misuse, damages, or legal consequences resulting from usage.
Users must independently verify legality in their jurisdiction before deployment.

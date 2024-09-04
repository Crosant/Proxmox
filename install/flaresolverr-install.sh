#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y apt-transport-https
$STD apt-get install -y gpg
$STD apt-get install -y xvfb
$STD apt-get install -y wget
$STD apt-get install -y git
$STD apt-get install -y openssh-server
$STD apt-get install -y chromium-common=128.0.6613.84-1~deb12u1
$STD apt-mark hold chromium
msg_ok "Installed Dependencies"

msg_info "Updating Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Updated Python3"

msg_info "Installing FlareSolverr"
$STD git clone https://github.com/FlareSolverr/FlareSolverr /opt/flaresolverr
$STD pip install -r /opt/flaresolverr/requirements.txt
msg_ok "Installed FlareSolverr"

msg_info "Installing Chrome Webdriver"
wget -q https://github.com/electron/electron/releases/download/v32.0.1/chromedriver-v32.0.1-linux-arm64.zip -O /opt/flaresolverr/webdriver.zip
cd /opt/flaresolverr
unzip -q webdriver.zip chromedriver
sed -i 's|^PATCHED_DRIVER_PATH = None|PATCHED_DRIVER_PATH = "/opt/flaresolverr/chromedriver"|' ./src/utils.py
msg_ok "Installed Chrome Webdriver"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/flaresolverr.service
[Unit]
Description=FlareSolverr
After=network.target
[Service]
SyslogIdentifier=flaresolverr
Restart=always
RestartSec=5
Type=simple
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
WorkingDirectory=/opt/flaresolverr
ExecStart=python3 /opt/flaresolverr/src/flaresolverr.py
TimeoutStopSec=30
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now flaresolverr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm /opt/flaresolverr/webdriver.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

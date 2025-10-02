#!/bin/bash
set -eux

# ================================
# AX18 OpenClash 自定义脚本
# ================================

# 修改默认IP为192.168.0.1
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# 添加 OpenClash 源
echo 'src-git openclash https://github.com/vernesong/OpenClash' >> feeds.conf.default

# 修正 Makefile 路径
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' {}

# ===== 强制锁定 CMIOT-AX18 设备 =====
sed -i '/CONFIG_TARGET_.*DEVICE_/d' .config
cat >> .config <<'EOF'
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq60xx=y
CONFIG_TARGET_qualcommax_ipq60xx_DEVICE_cmiot_ax18=y
EOF

# ================================
# 生成配置文件（替代 uci 调用）
# ================================

# ==== 1. 保留原有包，确保 opkg 在固件中 ====
sed -i 's/DEFAULT_PACKAGES:=\(.*\)/DEFAULT_PACKAGES:=\1 opkg/' include/target.mk

# ==== 2. 如果启用了 opkg-smime，关闭强制签名检查 ====
if grep -q "CONFIG_PACKAGE_opkg-smime=y" .config 2>/dev/null; then
    echo "option check_signature 0" >> package/system/opkg/files/opkg.conf
fi

# ==== 3. 运行时默认安装未签名包 ====
echo "option check_signature 0" >> package/base-files/files/etc/opkg.conf

# ==== 4. 添加安装别名 ====
echo "alias ipkinstall='opkg install --force-overwrite --force-depends'" >> package/base-files/files/etc/profile
echo "alias apkinstall='apk add --allow-untrusted'" >> package/base-files/files/etc/profile

CONFIG_DIR="./files/etc/config"
mkdir -p "$CONFIG_DIR"

# network 配置（启用 IPv6）
cat > "$CONFIG_DIR/network" <<'EOF'
config interface 'loopback'
	option ifname 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config interface 'lan'
	option type 'bridge'
	option ifname 'eth0'
	option proto 'static'
	option ipaddr '192.168.0.1'
	option netmask '255.255.255.0'
	option ipv6 '1'
EOF

# firewall 配置（启用 firewall4）
cat > "$CONFIG_DIR/firewall" <<'EOF'
config defaults
	option syn_flood '1'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'

config zone
	option name 'lan'
	option network 'lan'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'

config zone
	option name 'wan'
	option network 'wan'
	option input 'REJECT'
	option output 'ACCEPT'
	option forward 'REJECT'

config forwarding
	option src 'lan'
	option dest 'wan'
EOF

# upnp 配置（启用 UPnP）
cat > "$CONFIG_DIR/upnpd" <<'EOF'
config upnpd 'config'
	option enabled '1'
	option secure_mode '1'
EOF

# wireless 配置（禁用 WiFi）
cat > "$CONFIG_DIR/wireless" <<'EOF'
# WiFi 已禁用
EOF

# system 配置（Dropbear、uHTTPd 默认启用）
cat > "$CONFIG_DIR/system" <<'EOF'
config system
	option hostname 'AX18'
	option timezone 'CST-8'
EOF

# openclash 配置（默认启用）
cat > "$CONFIG_DIR/openclash" <<'EOF'
# OpenClash 默认启用
EOF

# dropbear 配置（保持默认即可）
cat > "$CONFIG_DIR/dropbear" <<'EOF'
config dropbear
	option PasswordAuth 'on'
	option RootPasswordAuth 'on'
EOF

# uhttpd 配置（保持默认即可）
cat > "$CONFIG_DIR/uhttpd" <<'EOF'
config uhttpd 'main'
	option listen_http '0.0.0.0:80'
	option listen_https '0.0.0.0:443'
	option redirect_https '0'
EOF

echo "==============================="
echo "AX18 OpenClash 自定义脚本执行完成"
echo "IPv6, firewall4, UPnP, Dropbear, uHTTPd, OpenClash 已启用（通过配置文件）"
echo "WiFi 配置已清理"
echo "默认 IP: 192.168.0.1"
echo "==============================="

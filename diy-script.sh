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
# 启用必要服务和功能
# ================================

# 启用 IPv6
uci set network.lan.ipv6='1'
uci commit network

# 启用 firewall4
/etc/init.d/firewall enable
/etc/init.d/firewall restart

# 启用 UPnP
uci set upnpd.config.enabled='1'
uci commit upnpd
/etc/init.d/upnpd enable
/etc/init.d/upnpd restart

# 清理 WiFi 配置（AX18 禁用 WiFi）
uci delete wireless
uci commit wireless

# 启用 Dropbear 和 uHTTPd
/etc/init.d/dropbear enable
/etc/init.d/dropbear restart
/etc/init.d/uhttpd enable
/etc/init.d/uhttpd restart

# 启用 OpenClash
/etc/init.d/openclash enable
/etc/init.d/openclash start

echo "==============================="
echo "AX18 OpenClash 自定义脚本执行完成"
echo "IPv6, firewall4, UPnP, OpenClash 已启用"
echo "WiFi 配置已清理"
echo "默认 IP: 192.168.0.1"
echo "==============================="

#!/bin/bash
set -eux

# 修改默认IP为192.168.0.1
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# 添加 OpenClash 源
echo 'src-git openclash https://github.com/vernesong/OpenClash' >> feeds.conf.default

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

# 修正 Makefile 路径
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' {}

./scripts/feeds update -a
./scripts/feeds install -a

# ===== 强制锁定 CMIOT-AX18 设备 =====
sed -i '/CONFIG_TARGET_.*DEVICE_/d' .config
cat >> .config <<'EOF'
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq60xx=y
CONFIG_TARGET_qualcommax_ipq60xx_DEVICE_cmiot_ax18=y
EOF

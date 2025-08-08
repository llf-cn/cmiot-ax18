#!/bin/bash
set -eux

# 修改默认 LAN IP 为 192.168.0.1
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# 添加 OpenClash 源
echo 'src-git openclash https://github.com/vernesong/OpenClash' >> feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a
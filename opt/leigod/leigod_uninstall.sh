#!/bin/sh

# 获取脚本所在目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# this script is use to install leigod plugin
ver_name="version"
init_file_name="acc"
binary_prefix="acc-gw.router"
#common_file_name="plugin_common.sh"
common_file_name="${SCRIPT_DIR}/plugin_common.sh"
download_base_url="http://119.3.40.126"


# include common file 
. ${common_file_name}

# preinstall_check 
# check and set env
preinstall_check

if [ ${is_steamdeck} ]; then
    echo "systemctl stop leigod_plugin"
    systemctl stop leigod_plugin

    echo "rm /etc/systemd/system/leigod_plugin.service"
    rm /etc/systemd/system/leigod_plugin.service

    pids=$(ps ax | grep "acc-gw.router.amd64" | awk '{print $1}')
    for pid in $pids; do
      if [ -d "/proc/$pid" ]; then
        echo "steamdeck kill $pid"
        kill -9 "$pid"
      fi
    done

    pids=$(ps ax | grep "acc_upgrade_monitor" | awk '{print $1}')
    for pid in $pids; do
      if [ -d "/proc/$pid" ]; then
        echo "steamdeck kill acc_upgrade_monitor $pid"
        kill -9 "$pid"
      fi
    done

    echo "iptables -t mangle -F"
    iptables -t mangle -F
fi

if [ ${is_openwrt} ]; then
  echo "remove openwrt config"
  remove_openwrt_series_config
  remove_openwrt_series_init
fi

# remove_binary remove binary
remove_binary

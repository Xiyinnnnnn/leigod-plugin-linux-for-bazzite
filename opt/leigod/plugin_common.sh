# this script is use to install leigod plugin
# sbin_dir="/usr/sbin/leigod"
ver_name="acc_version.ini"
init_file_name="acc"
binary_prefix="acc-gw.router"
common_file_name="plugin_common.sh"
uninstall_file_name="leigod_uninstall.sh"
download_base_url="http://119.3.40.126"
xdb_file_name="ipdatacloud_country.xdb"

if [ ${install_env} == "test" ]; then
  echo "Current using test environment"
  download_base_url="http://119.3.40.126"
fi

# get_device_os
# current support os: Linux
get_device_os() {
  os=$(uname)
  if [ $? == "0" ]; then
    return 0
  fi
  echo "os cant be get"
  return -1
}

# get_device_arch, 
# current support arch: arm64 arm x86_64 mips 
get_device_arch() {
  arch=$(uname -m)
  if [ $? == "0" ]; then
    return 0
  fi
  echo "arch cant be get"
  return -1
}

# get_xiaomi_name check if is xiaomi 
get_xiaomi_name() {
  echo "check xiaomi, start exec cmd: uci get misc.hardware.displayName"
  local name=$(uci get misc.hardware.displayName)
  if [ "$?" -eq 0 ] && [ -n "$name" ]; then
    echo "router is xiaomi series, name: ${name}"
    sbin_dir="/userdisk/appdata/leigod"
    init_dir="/userdisk/appdata/leigod"
    is_xiaomi=true

    # stop old acc if exist
    uninstall_xiaomi_monitor
    /userdisk/appdata/leigod/acc stop
    sleep 1
    local pids=$(ps | grep "$binary_prefix.$arch" | awk '{print $1}')
      for pid in $pids; do
        if [ -d "/proc/$pid" ]; then
        echo "kill $pid"
        kill -9 "$pid"
      fi
    done
    return 0
  fi
  echo "check xiaomi, end exec cmd: uci get misc.hardware.displayName"

  echo "check xiaomi, start exec cmd: uci get misc.hardware.model"
  local name=$(uci get misc.hardware.model)
  if [ "$?" -eq 0 ] && [ -n "$name" ]; then
    echo "router is xiaomi series, name: ${name}"
    sbin_dir="/userdisk/appdata/leigod"
    init_dir="/userdisk/appdata/leigod"
    is_xiaomi=true

    uninstall_xiaomi_monitor
    /userdisk/appdata/leigod/acc stop
    sleep 1
    local pids=$(ps | grep "$binary_prefix.$arch" | awk '{print $1}')
      for pid in $pids; do
        if [ -d "/proc/$pid" ]; then
        echo "kill $pid"
        kill -9 "$pid"
      fi
    done
    return 0
  fi
  echo "check xiaomi, end exec cmd: uci get misc.hardware.model"

  echo "router is not xiaomi, use general openwrt"
  sbin_dir="/usr/sbin/leigod"
  init_dir="/etc/init.d"
  # stop openwrt service first
  echo "stop openwrt acc service first, in casue install failed"
  /etc/init.d/acc stop
  sleep 1
  local pids=$(ps | grep "$binary_prefix.$arch" | awk '{print $1}')
  for pid in $pids; do
    if [ -d "/proc/$pid" ]; then
      echo "kill $pid"
      kill -9 "$pid"
    fi
  done
  
  #show_openwrt_suggestion
  return 0
}

# get_asus_name get asus name
get_merlin_party() {
  if [[ -d "/koolshare" ]]; then
    echo "router is merlin series, name: $(nvram get build_name)"
    nvram set 3rd-party=merlin
    is_merlin=true
    sbin_dir="/koolshare/leigod/acc"
    init_dir="/koolshare/init.d"
  fi

  if [[ -d "/jffs/softcenter" ]]; then
    echo "router is swrt series, name: $(nvram get build_name)"
    is_merlin=false
    is_swrt=true
    nvram set 3rd-party=swrt
    sbin_dir="/jffs/softcenter/leigod/acc"
    init_dir="/jffs/softcenter/init.d"
  fi
  
  if [ ${is_merlin} ] || [ ${is_swrt} ]; then
    echo "stop asus acc service first"
    local pids=$(ps | grep "acc-gw.linux.$arch" | awk '{print $1}')
    if [ ${arch} == "mipsel" ]; then
      pids=$(ps | grep "acc-gw.linux.mipsle" | awk '{print $1}')
    fi
    for pid in $pids; do
      if [ -d "/proc/$pid" ]; then
        echo "asus kill old acc $pid"
        kill -9 "$pid"
      fi
    done

    pids=$(ps | grep "$binary_prefix.$arch" | awk '{print $1}')
    for pid in $pids; do
      if [ -d "/proc/$pid" ]; then
        echo "asus kill acc $pid"
        kill -9 "$pid"
      fi
    done

    pids=$(ps | grep "acc_upgrade_monitor" | awk '{print $1}')
    for pid in $pids; do
      if [ -d "/proc/$pid" ]; then
        echo "asus kill acc_upgrade_monitor $pid"
        kill -9 "$pid"
      fi
    done

    pids=$(ps | grep "plugin_asus_monitor.sh" | awk '{print $1}')
    for pid in $pids; do
      if [ -d "/proc/$pid" ]; then
        echo "asus kill plugin_asus_monitor.sh $pid"
        kill -9 "$pid"
      fi
    done
  fi

  # check merlin
  echo "route is merlin, use general asus"
  return 0
}

get_steamdeck_party () {
    local user_dir="/home/deck"
    if [ -d ${user_dir} ] ; then
        sbin_dir="$user_dir/leigod"
        init_dir="$user_dir/leigod"
    else
        sbin_dir="/home/leigod"
        init_dir="/home/leigod"
    fi

    echo "steamdeck plugin install directory is $sbin_dir"
}

is_steamdeck_decice() {
    if [ -f "/sys/class/dmi/id/product_name" ]; then
        product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr -d '\n')
        if [ "$product_name" = "Jupiter" ]; then
            echo "product_name:$product_name"
            return 0
        fi
    fi

    if [ -f "/etc/os-release" ] && grep -q -i "steamdeck" /etc/os-release 2>/dev/null; then
        echo "/etc/os-release:steamdeck"
        return 0
    fi

    return 1
}

# get_device_firmware get device firmware
# current support firmware: openwrt merlin
get_device_firmware() {
  # openwrt file exist
  if [ -f "/etc/openwrt_release" ]; then
    echo "firmware is openwrt series"
    is_openwrt=true
    get_xiaomi_name
  elif [[ -f "/etc/image_version" ]] || [[ -d "/koolshare" ]] || [[ -d "/jffs/softcenter" ]]; then
    echo "firmware is asus series"
    is_asus=true
    get_merlin_party
  elif is_steamdeck_decice; then
    is_steamdeck=true
    get_steamdeck_party
  fi
}

# install_openwrt_package install openwrt 
install_binary() {
  # remove old acc file
  local old_acc_bin=${sbin_dir}/acc-gw.linux.$arch
  if [ ${arch} == "mipsel" ]; then
    old_acc_bin=${sbin_dir}/acc-gw.linux.mipsle
  fi
  if [ -f "$old_acc_bin" ]; then
    echo "remove old acc bin file"
    rm $old_acc_bin -rf
  fi
  # create sbin dir
  mkdir -p ${sbin_dir}
  # create name 
  local acc_name=${binary_prefix}.${arch}
  local download_bin_url=${download_base_url}/${acc_name}
  echo "download ${acc_name} to ${sbin_dir}..."
  # download file 
  curl -o ${sbin_dir}/${acc_name} ${download_bin_url}
  if [ $? != "0" ]; then
    echo "download and install binary failed"
    return -1
  fi
  echo "download ${acc_name} binary success"
  chmod +x ${sbin_dir}/${acc_name}
  if [ $? != "0" ]; then
    echo "add binary permission failed"
    return -1
  fi
  echo "chmod ${acc_name} permission success"

  # copy upgrade_monitor
  echo "copy acc binary to acc_upgrade_monitor..."
  cp ${sbin_dir}/${acc_name} ${sbin_dir}/acc_upgrade_monitor
  echo "copy acc binary to acc_upgrade_monitor finish"
  
  # download ipdatacloud_country.xdb
  echo "download xdb file..."
  local config_dir="/etc/config"
  if [ ${is_asus} ] || [ ${is_steamdeck} ]; then
    config_dir="${sbin_dir}/config"
    if [ ! -d "$config_dir" ]; then
        mkdir -p ${config_dir}
    fi
  fi
  local download_xdb_url=${download_base_url}/${xdb_file_name}
  curl -o ${config_dir}/${xdb_file_name} ${download_xdb_url}
  if [ $? != "0" ]; then
    echo "download and install xdb file failed"
    return -1
  fi
  echo "download xdb file success"

  # download common file 
  echo "download install common file..."
  local download_common_url=${download_base_url}/${common_file_name}
  curl -o ${sbin_dir}/${common_file_name} ${download_common_url}
  if [ $? != "0" ]; then
    echo "download and install common file failed"
    return -1
  fi
  echo "download install common file success"

  # remote uninstall_file_name
  echo "download uninstall file..."
  local remote_uninstall_file_name=${download_base_url}/"plugin_uninstall.sh"
  curl -o ${sbin_dir}/${uninstall_file_name} ${remote_uninstall_file_name}
  if [ $? != "0" ]; then
    echo "download and install uninstall file failed"
    return -1
  fi
  chmod +x ${sbin_dir}/${uninstall_file_name}
  echo "download uninstall file success"

  local ver_file=${config_dir}/${ver_name}
  echo "create $ver_file..."
  touch ${ver_file}
  if [ $? != "0" ]; then
    echo "create version file failed"
    return -1
  fi
  echo "create $ver_file success"
  # add version to file 
  echo "add version 1.2.2.15 to $ver_file..."
  echo "
[info]
version="1.2.2.15"
  " > ${ver_file}

  echo "add version 1.2.2.15 to $ver_file success"
  return 0
}

# remove_binary remove binary
remove_binary() {
  rm -r ${sbin_dir}
}

uninstall_xiaomi_monitor() {
  sed -i '/\*\/1 \* \* \* \* \/userdisk\/appdata\/leigod\/plugin_monitor\.sh/d' /etc/crontabs/root
  if [ $? != "0" ]; then
    echo "no monitor to cron"
    return
  fi
  echo "del monitor to cron success"
}

# install xiaomi monitor 
install_xiaomi_monitor() {
  local cron_path="/etc/crontabs/root"
  local monitor_file_name="plugin_monitor.sh"
  local download_monitor_url=${download_base_url}/${monitor_file_name}
  curl -o ${sbin_dir}/${monitor_file_name} ${download_monitor_url}
  if [ $? != "0" ]; then
    echo "download monitor file failed"
    return -1
  fi
  chmod +x ${sbin_dir}/${monitor_file_name}
  # download 
  echo "download monitor file success"
  echo "*/1 * * * * ${sbin_dir}/${monitor_file_name}" >> ${cron_path}
  if [ $? != "0" ]; then
    echo "add monitor to cron failed"
    return -1
  fi
  echo "add monitor to cron success"
}

start_leigod_plugin_service() {
  echo "Start create leigod plugin service..."

  SERVICE_NAME="leigod_plugin.service"
  SERVICE_FILE="/etc/systemd/system/leigod_plugin.service"

  if [ ${install_env} == "test" ]; then
    EXEC_BIN="${sbin_dir}/steamdeck_acc_monitor.sh test"
  else
    EXEC_BIN="${sbin_dir}/steamdeck_acc_monitor.sh"
  fi

  #1.create_service_file
    cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=Leigod Plugin Service
Wants=network-online.target
After=network.target network-online.target

[Service]
ExecStart=${EXEC_BIN}
KillMode=process
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

  #2.reload_systemd
  systemctl daemon-reload
  if [ $? -eq 0 ]; then
      echo "daemon-reload successful"
  else
      echo "daemon-reload failed"
      return 1
  fi

  #3.enable_and_start_service
  systemctl enable "${SERVICE_NAME}"
  if [ $? -eq 0 ]; then
      echo "systemctl enable ${SERVICE_NAME} successful"
  else
      echo "systemctl enable ${SERVICE_NAME} failed"
      return 1
  fi

  systemctl start "${SERVICE_NAME}"
  if [ $? -eq 0 ]; then
      echo "systemctl start ${SERVICE_NAME} successful"
  else
      echo "systemctl start ${SERVICE_NAME} failed"
      return 1
  fi

  echo "End create leigod plugin service"
  return 0
}

# install_openwrt_series_config save openwrt config 
install_openwrt_series_config() {
  # create accelerator config
  touch /etc/config/accelerator
  if [ $? != "0" ]; then
    echo "make acc config file failed"
    return -1
  fi
  if [ ${install_env} == "test" ]; then
    # use uci to add config 
    uci set accelerator.base=system
    uci set accelerator.bind=bind
    uci set accelerator.device=hardware
    uci set accelerator.Phone=acceleration
    uci set accelerator.PC=acceleration
    uci set accelerator.Game=acceleration
    uci set accelerator.Unknown=acceleration
    uci set accelerator.base.url='https://test-opapi.nn.com/speed/router/plug/check'
    uci set accelerator.base.heart='https://test-opapi.nn.com/speed/router/heartbeat'
    uci set accelerator.base.base_url='https://test-opapi.nn.com/speed'
    uci commit accelerator
  elif [ ${install_env} == "test1" ]; then
    # use uci to add config 
    uci set accelerator.base=system
    uci set accelerator.bind=bind
    uci set accelerator.device=hardware
    uci set accelerator.Phone=acceleration
    uci set accelerator.PC=acceleration
    uci set accelerator.Game=acceleration
    uci set accelerator.Unknown=acceleration
    uci set accelerator.base.url='https://test1-opapi.nn.com/speed/router/plug/check'
    uci set accelerator.base.heart='https://test1-opapi.nn.com/speed/router/heartbeat'
    uci set accelerator.base.base_url='https://test1-opapi.nn.com/speed'
    uci commit accelerator
  else
    # use uci to add config 
    uci set accelerator.base=system
    uci set accelerator.bind=bind
    uci set accelerator.device=hardware
    uci set accelerator.Phone=acceleration
    uci set accelerator.PC=acceleration
    uci set accelerator.Game=acceleration
    uci set accelerator.Unknown=acceleration
    uci set accelerator.base.url='https://opapi.nn.com/speed/router/plug/check'
    uci set accelerator.base.heart='https://opapi.nn.com/speed/router/heartbeat'
    uci set accelerator.base.base_url='https://opapi.nn.com/speed'
    uci commit accelerator
  fi
  if [ $? != "0" ]; then
    echo "create openwrt config unit failed"
    return -1
  fi
  echo "create openwrt config unit success"
}

# install_openwrt_series_luasrc install openwrt lua src
install_openwrt_series_luasrc() {
  lua_base="/usr/lib/lua/luci"
  # download index file
  curl --create-dirs -o ${lua_base}/controller/acc.lua ${download_base_url}/openwrt/controller/acc.lua
  if [ $? != "0" ]; then
    echo "download acc.lua failed"
    return -1
  fi
  # download service view file
  curl --create-dirs -o ${lua_base}/model/cbi/leigod/service.lua ${download_base_url}/openwrt/model/cbi/leigod/service.lua
  if [ $? != "0" ]; then
    echo "download service.lua failed"
    return -1
  fi
  # download device view file
  curl --create-dirs -o ${lua_base}/model/cbi/leigod/device.lua ${download_base_url}/openwrt/model/cbi/leigod/device.lua
  if [ $? != "0" ]; then
    echo "download device.lua failed"
    return -1
  fi
  # download notice view file
  curl --create-dirs -o ${lua_base}/model/cbi/leigod/notice.lua ${download_base_url}/openwrt/model/cbi/leigod/notice.lua
  if [ $? != "0" ]; then
    echo "download notice.lua failed"
    return -1
  fi
  # download service view file
  curl --create-dirs -o ${lua_base}/view/leigod/notice.htm ${download_base_url}/openwrt/view/leigod/notice.htm
  if [ $? != "0" ]; then
    echo "download notice.htm failed"
    return -1
  fi
  # download service view file
  curl --create-dirs -o ${lua_base}/view/leigod/service.htm ${download_base_url}/openwrt/view/leigod/service.htm
  if [ $? != "0" ]; then
    echo "download service.htm failed"
    return -1
  fi
  # download service translate file
  curl --create-dirs -o ${lua_base}/i18n/acc.zh-cn.lmo ${download_base_url}/openwrt/po/zh-cn/acc.zh-cn.lmo
  if [ $? != "0" ]; then
    echo "download acc.zh-cn.lmo failed"
    return -1
  fi
  echo "download lua src success"
}

uninstall_openwrt_series_luasrc() {
  lua_base="/usr/lib/lua/luci"
  
  if [ -f "${lua_base}/controller/acc.lua" ]; then
    rm ${lua_base}/controller/acc.lua
    echo "uninstall ${lua_base}/controller/acc.lua success"
  fi
  
  if [ -f "${lua_base}/model/cbi/leigod/service.lua" ]; then
    rm ${lua_base}/model/cbi/leigod/service.lua
    echo "uninstall ${lua_base}/model/cbi/leigod/service.lua success"
  fi
  
  if [ -f "${lua_base}/model/cbi/leigod/device.lua" ]; then
    rm ${lua_base}/model/cbi/leigod/device.lua
    echo "uninstall ${lua_base}/model/cbi/leigod/device.lua success"
  fi

  if [ -f "${lua_base}/model/cbi/leigod/notice.lua" ]; then
    rm ${lua_base}/model/cbi/leigod/notice.lua
    echo "uninstall ${lua_base}/model/cbi/leigod/notice.lua success"
  fi

  if [ -f "${lua_base}/view/leigod/notice.htm" ]; then
    rm ${lua_base}/view/leigod/notice.htm
    echo "uninstall ${lua_base}/view/leigod/notice.htm success"
  fi

  if [ -f "${lua_base}/view/leigod/service.htm" ]; then
    rm ${lua_base}/view/leigod/service.htm
    echo "uninstall ${lua_base}/view/leigod/service.htm success"
  fi

  if [ -f "${lua_base}/i18n/acc.zh-cn.lmo" ]; then
    rm ${lua_base}/i18n/acc.zh-cn.lmo
    echo "uninstall ${lua_base}/i18n/acc.zh-cn.lmo success"
  fi
  echo "uninstall lua src success"
}

install_openwrt_series_web() {
  local luci_base="/usr/lib/lua/luci"
  
}

# remove_openwrt_series_config remove openwrt config 
remove_openwrt_series_config() {
  rm /etc/config/accelerator
  rm /etc/config/accelerator.ini
  rm /etc/config/acc_version.ini
}

# install asus series config 
install_series_config() {
  local config_dir="/etc/config"
  if [ ${is_asus} ] || [ ${is_steamdeck} ]; then
    config_dir="${sbin_dir}/config"
    if [ ! -d "$config_dir" ]; then
        mkdir -p ${config_dir}
    fi
  fi
  if [ ${install_env} == "test" ]; then
  # install test asus config
  echo "
[base]
url="https://test-opapi.nn.com/speed/router/plug/check"
channel="2"
appid="nnMobile_d0k3duup"
heart="https://test-opapi.nn.com/speed/router/heartbeat"
base_url="https://test-opapi.nn.com/speed"

[update]
domain="https://test-opapi.nn.com/nn-version/version/plug/upgrade"

[device]
  " > ${config_dir}/accelerator.ini
  elif [ ${install_env} == "test1" ]; then
  # install test1 asus config
  echo "
[base]
url="https://test1-opapi.nn.com/speed/router/plug/check"
channel="2"
appid="nnMobile_d0k3duup"
heart="https://test1-opapi.nn.com/speed/router/heartbeat"
base_url="https://test1-opapi.nn.com/speed"

[update]
domain="https://test1-opapi.nn.com/nn-version/version/plug/upgrade"

[device]
  " > ${config_dir}/accelerator.ini
  else
  # install release asus config
  echo "
[base]
url="https://opapi.nn.com/speed/router/plug/check"
channel="2"
appid="nnMobile_d0k3duup"
heart="https://opapi.nn.com/speed/router/heartbeat"
base_url="https://opapi.nn.com/speed"

[update]
domain="https://opapi.nn.com/nn-version/version/plug/upgrade"

[device]
  " > ${config_dir}/accelerator.ini

  fi

  echo "create init config success"
}

# remove_asus_series_config remove asus config 
remove_asus_series_config() {
  rm -r ${init_dir}
}

# install_openwrt_init install openwrt to init 
install_openwrt_series_init() {
  local remote_init_name="openwrt_init.sh"
  local download_init_url=${download_base_url}/${remote_init_name}
  # download init file 
  curl -o ${init_dir}/${init_file_name} ${download_init_url}
  if [ $? != "0" ]; then
    echo "download init file failed"
    return -1
  fi
  echo "download init file success"
  #  add permission to file 
  chmod +x ${init_dir}/${init_file_name}
  if [ $? != "0" ]; then
    echo "add init permission failed"
    return -1
  fi
  echo "add init file permission success"
  ${init_dir}/${init_file_name} enable
  echo "set accelerator autostart success"
  ${init_dir}/${init_file_name} start
  if [ $? != "0" ]; then
    echo "start accelerator failed"
    return -1 
  fi
  echo "start accelerator success"
}

# remove_openwrt_series_init remove openwrt init
remove_openwrt_series_init() {
  ${init_dir}/${init_file_name} disable
  ${init_dir}/${init_file_name} stop
  rm ${init_dir}/${init_file_name}
}

# install merlin init 
install_merlin_init() {
  local remote_init_name="asus_init.sh"
  local download_init_url=${download_base_url}/${remote_init_name}
  # download init file 
  echo "download asus_init.sh file..."
  curl -o ${sbin_dir}/${init_file_name} ${download_init_url}
  if [ $? != "0" ]; then
    echo "download init file failed"
    return -1
  fi
  # add permission 
  chmod +x ${sbin_dir}/${init_file_name}
  echo "download asus_init.sh success"

  # create link 
  local link_init_name="S99LeigodAcc.sh"
  local link_init_file=${init_dir}/${link_init_name}
  ln -sf ${sbin_dir}/${init_file_name} ${link_init_file}
  if [ $? != "0" ]; then
    echo "create merlin init link failed"
    return -1
  fi
  echo "create merlin S99LeigodAcc.sh link file success"

  # download monitor script
  echo "download plugin_asus_monitor.sh file..."
  local remote_monitor_file="plugin_asus_monitor.sh"
  local download_monitor_url=${download_base_url}/${remote_monitor_file}
  curl -o ${sbin_dir}/${remote_monitor_file} ${download_monitor_url}
  if [ $? != "0" ]; then
    echo "download monitor file failed"
    return -1    
  fi
  chmod +x ${sbin_dir}/${remote_monitor_file}
  echo "download plugin_asus_monitor.sh success"

  ${link_init_file} start
  echo "acc start success"
}

install_steamdeck_init() {
  # download monitor script
  echo "download steamdeck_acc_monitor.sh file..."
  local remote_monitor_file="steamdeck_acc_monitor.sh"
  local download_monitor_url=${download_base_url}/${remote_monitor_file}
  curl -o ${sbin_dir}/${remote_monitor_file} ${download_monitor_url}
  if [ $? != "0" ]; then
    echo "download monitor file failed"
    return -1    
  fi
  chmod +x ${sbin_dir}/${remote_monitor_file}
  echo "download steamdeck_acc_monitor.sh success"
}

# show_openwrt_suggestion show openwrt install suggest
show_openwrt_suggestion() {
  echo "
  雷神OpenWrt插件安装建议:

  当前雷神路由器支持两种加速模式,
  1. tproxy加速模式(速度更快, CPU占用率更低)
  2. tun加速模式(需要依赖少, 安装灵活)
  
  需要您根据以上的加速模式, 安装对应的依赖库, 
  如下列出两种模式对应的安装依赖: 
  1. TProxy模式:  libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-tproxy kmod-netem(可选) tc-full(可选) kmod-ipt-ipset ipset curl
  2. Tun模式:     libpcap iptables kmod-tun kmod-ipt-nat kmod-ipt-ipset ipset curl

  如何安装依赖:
  1. 升级依赖:   opkg update 
  2. 安装依赖:   opkg install xxx

  为了安装方便, 请选择一个模式, 复制以下命令到终端运行: 
  Tproxy模式: 
  opkg update 
  opkg install libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset ipset

  Tun模式:
  opkg update 
  opkg install libpcap iptables kmod-tun kmod-ipt-nat kmod-ipt-ipset ipset curl

  关于steamdeck的支持说明
  steamdeck设备请选择加速电脑游戏
  
  关于手机设备的支持:
  1. 安卓支持说明 
  当前代理仅支持ipv4代理, 请更改dhcp配置，更改完配置请重启路由器，
  配置路径在 /etc/config/dhcp 
  config dhcp 'lan'
    ... 此处是一些其他配置
    ra 'disable'
    dhcpv6 'disable'
    list ra_flags 'none'
    ... 此处是一些其他配置

  2. 关于ios设备的支持说明
  ios设备, 安装完插件后, 为了精准识别, 请在ios上选择忘记wifi, 然后重新连接即可
  "
}

# preinstall_check check env
preinstall_check() {
  # check os 
  get_device_os
  if [ ${os} != "Linux" ]; then
    echo "current os not support, os: ${os}"
    return -1
  fi
  # check arch
  get_device_arch
  if [[ ${arch} != "x86_64" && ${arch} != "aarch64" && ${arch} != "arm" && ${arch} != "mips" && ${arch} != "armv7l" ]];then
    echo "current arch not support, arch: ${arch}"
    return -1
  fi
  # fix arch 
  if [ ${arch} == "x86_64" ]; then
    echo "match x86_64 -> amd64"
    arch="amd64"
  elif [ ${arch} == "aarch64" ]; then
    echo "match aarch64 -> arm64"
    arch="arm64"
  elif [ ${arch} == "mips" ]; then
    echo "match mips -> mipsel"
    arch="mipsel"
  elif [ ${arch} == "armv7l" ]; then
    arch="arm"
  fi
  # support plugin
  echo "current system support plugin, system: ${os}-${arch}"
  get_device_firmware
  return 0
}

# 检查模块是否已安装
is_package_installed() {
    local pkg=$1
    opkg list-installed | grep -q "^${pkg} "
    return $?
}

# 安装单个模块
install_package() {
    local pkg=$1
    echo "will to setup: ${pkg}..."
    if opkg install "${pkg}"; then
        echo "has setup: ${pkg}"
        return 0
    else
        echo "setup failed: ${pkg}"
        return 1
    fi
}

openwrt_proxy_check() {
    local missing_packages=0
    local failed_packages=0
    # 需要检查的模块列表
    local required_packages="libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset ipset"
    # 首先更新软件包列表
    echo "updating packages..."
    if opkg update; then
        echo "update successful."
        #return 0
    else
        echo "update failed."
        return 1
    fi

    for pkg in $required_packages; do
        if is_package_installed "$pkg"; then
            echo "has setup: ${pkg}"
        else
            echo "has no module: ${pkg}"
            if ! install_package "$pkg"; then
                failed_packages=$((failed_packages + 1))
            fi
            missing_packages=$((missing_packages + 1))
        fi
    done

    if [ "$failed_packages" -gt 0 ]; then
        echo "error: has ${failed_packages} modules to setup failed."
        return 1
    elif [ "$missing_packages" -gt 0 ]; then
        echo "setup ${missing_packages} modules successful."
    else
        echo "all modules has setup."
    fi

    return 0
}

# 检查模块是否已加载
check_module_loaded() {
    local module=$1
    if lsmod | grep -q "^${module}\s"; then
        echo "module already loaded: $module"
        return 1  # 已加载返回1
    else
        echo "module not loaded: $module"
        return 0  # 未加载返回0
    fi
}

# 尝试动态加载模块
load_module() {
    local module=$1
    echo "will to modprobe: $module"
    modprobe "$module"
    if [ $? -eq 0 ]; then
        echo "load successful: $module"
        return 0
    else
        echo "load failed: $module"
        return 1
    fi
}

asus_proxy_check() {
  # 需要检查的模块列表
  local required_packages="xt_set ip_set ip_set_hash_net ip_set_list_set xt_TPROXY"
  
  for module in $required_packages; do
    check_module_loaded "$module"
    if [ $? -eq 1 ]; then
      echo "has loaded: $module"
    else
      echo "ready to load: $module"
      load_module "$module"
      if [ $? -eq 1 ]; then
         echo "load module failed: $module"
      fi
    fi
  done
  
  return 0
}
  

# show_install_success show install has been installed 
show_install_success() {
  echo "install success"
  if [ ! ${is_steamdeck} ]; then
    echo "雷神路由器新版插件安装已完成"
  else
    echo "雷神Steam Deck插件安装已完成"
  fi
  echo "请加群936393529体验"
}


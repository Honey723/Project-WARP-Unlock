#!/bin/bash

# > System:Ubuntu 20

source /etc/profile

function Start {
    echo -e " Cloudflare WARP 一键流媒体解锁脚本[汉化版]"
    echo -e " 测试系统:Ubuntu 20,Debian 11"
    echo -e " 开源项目:https://github.com/GeorgeXie2333/Project-WARP-Unlock"
    echo -e " Telegram频道:https://t.me/cutenicobest"
    echo -e " 版本:2021-11-03-1"
    echo -e " 若你的服务器系统内核版本小于5.6,请按 Ctrl + C 退出..."
    Check_System_Depandencies
}

function Check_System_Depandencies {
    echo -e " [信息] 正在安装依赖..."
    apt-get update >/dev/null
    apt-get install -yq ipset dnsmasq wireguard resolvconf mtr >/dev/null 2>&1
    Download_Profile
    Generate_WireGuard_WARP_Profile
}

function Download_Profile {
    wget -qO /etc/dnsmasq.d/warp.conf https://raw.githubusercontent.com/GeorgeXie2333/Project-WARP-Unlock/main/dnsmasq/warp.conf
    wget -qO /etc/wireguard/up https://raw.githubusercontent.com/GeorgeXie2333/Project-WARP-Unlock/main/scripts/up
    wget -qO /etc/wireguard/down https://raw.githubusercontent.com/GeorgeXie2333/Project-WARP-Unlock/main/scripts/down
    chmod +x /etc/wireguard/up
    chmod +x /etc/wireguard/down
}

function Generate_WireGuard_WARP_Profile {
    echo -e " [信息] 正在生成 WARP 配置文件,请稍后..."
    wget -qO /etc/wireguard/wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.8/wgcf_2.2.8_linux_amd64
    chmod +x /etc/wireguard/wgcf
    /etc/wireguard/wgcf register --accept-tos --config /etc/wireguard/wgcf-account.toml >/dev/null 2>&1
    sleep 10
    /etc/wireguard/wgcf generate --config /etc/wireguard/wgcf-account.toml --profile /etc/wireguard/wg.conf >/dev/null 2>&1
    sleep 10
    sed -i '7 i Table = off' /etc/wireguard/wg.conf
    sed -i '8 i PostUp = /etc/wireguard/up' /etc/wireguard/wg.conf
    sed -i '9 i Predown = /etc/wireguard/down' /etc/wireguard/wg.conf
    sed -i '15 i PersistentKeepalive = 5' /etc/wireguard/wg.conf
    sed -i "s/engage.cloudflareclient.com/162.159.192.1/g" /etc/wireguard/wg.conf
    Routing_WireGuard_WARP
}

function Routing_WireGuard_WARP {
    local rt_tables_status="$(cat /etc/iproute2/rt_tables | grep warp)"
    if [[ ! -n "$rt_tables_status" ]]; then
        echo '250   warp' >>/etc/iproute2/rt_tables
        echo -e " [信息] 路由创建中..."
    fi
    systemctl disable systemd-resolved --now >/dev/null 2>&1
    sleep 2
    systemctl enable dnsmasq --now >/dev/null 2>&1
    sleep 2
    systemctl enable wg-quick@wg --now >/dev/null 2>&1
    sleep 2
    systemctl restart dnsmasq >/dev/null 2>&1
    echo 'nameserver 127.0.0.1' > /etc/resolv.conf
    Check_finished
}

function Check_finished {
    local wireguard_status="$(ip link | grep wg)"
    if [[ "$wireguard_status" != *"wg"* ]]; then
        echo -e " [信息] WireGuard 未运行,尝试重启..."
        systemctl restart wg-quick@wg
    else
        echo -e " [信息] WireGuard 运行中，正在检查连接..."
    fi
    local connection_status="$(ping 1.1.1.1 -I wg -c 1 2>&1)"
    if [[ "$connection_status" != *"unreachable"* ]] && [[ "$connection_status" != *"Unreachable"* ]] && [[ "$connection_status" != *"SO_BINDTODEVICE"* ]] && [[ "$connection_status" != *"100% packet loss"* ]]; then
        echo -e " [信息] 连接已建立..."
    else
        echo -e " [错误] 连接被拒绝,请手动检查!"
        exit
    fi
    local routing_status="$(mtr -4wn -c 1 youtube.com)"
    if [[ "$routing_status" != *"172.16.0.1"* ]]; then
        echo -e " [错误] 路由配置有误，请重新检查!"
    else
        echo -e " [信息] 已成功接入Warp!"
        echo -e " [原项目作者赞助信息] USDT-TRC20:TCXfFzEQ7s968s4XiWzjNGdjuuew3CzLiF"
    fi
}

Start

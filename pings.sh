#!/usr/bin/env bash

set -e
set -u
#set -x
set -o pipefail

usage="$(basename "$0") ip_start [range] -- check hosts status

where:
    ip_start  the ip of the first host
    range    how many hosts preceed

examples:
    $(basename "$0") 192.168.1.1 5"

# 测试丢包率
testPing(){
    local lost_rate=`ping  -c 3 -w 3 "$1" \
    |grep 'packet loss' \
    |awk -F 'packet loss' '{print $1}' \
    |awk '{print $NF}' \
    |sed 's/%//g'`
    echo "$lost_rate"
#    return "$lost_rate"
}

#数值越大表示连通性越差，100表示不可通
testHost(){
    lost_rate=$(testPing "$1")
    printf "%-16s%d\n" "$1"  "$lost_rate"
}

main() {
    local range=-1
    local host_ip=0.0.0.0

    while getopts ':h' option; do
        case "$option" in
            h) echo "$usage"
                exit
                ;;
        esac
    done

    if [[ "$#" -lt 1 ]]
    then
        echo "$usage"
        exit
    elif [[ "$#" -eq 1 ]]
    then
        host_ip="$1"
    elif [[ "$#" -eq 2 ]]
    then
        host_ip="$1"
        range="$2"
    fi

    # 子网抽取与IP组合
    local subnet=$(echo "$host_ip" | sed 's/\.[0-9]*$//')
    local start=$(echo "$host_ip" | sed 's/.*\.//')
    for (( x=0; x<"$range"+1; x++ ))
    do
        : $((end=$start + $x))
        testHost "$subnet"."$end"
    done

    exit
}

main "$@"
#!/bin/bash
#
# MNT Reform 0.4+ Daemon for Battery, Lid and Fan Control
# Copyright 2018 MNT Media and Technology UG, Berlin
# SPDX-License-Identifier: GPL-3.0-or-later
#

set_fan_speed () {
    set +e; echo 0 > /sys/class/pwm/pwmchip1/export 2>/dev/null ; set -e
    echo 10000 > /sys/class/pwm/pwmchip1/pwm0/period
    echo "$1" > /sys/class/pwm/pwmchip1/pwm0/duty_cycle
    echo 1 > /sys/class/pwm/pwmchip1/pwm0/enable
}

function setup_serial {
    # 2400 baud 8N1, raw
    # cargoculted by exporting parameters with stty after using screen
    stty 406:0:8bb:8a30:3:1c:7f:15:4:2:64:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0 -F /dev/ttymxc1
}

function disable_echo {
    setup_serial
    exec 99<>/dev/ttymxc1
    :<&99
    printf "0e\r" >&99 
    exec 99>&-
    set +e; timeout 2 head /dev/ttymxc1; set -e
}

function get_battery_state {
    setup_serial
    exec 99<>/dev/ttymxc1
    :<&99
    printf "p\r" >&99
    IFS=$':\t\r'
    read -r -t 1 msg bat_capacity bat_volts bat_amps <&99
    exec 99>&-
}

function get_soc_temperature {
    read soc_temperature < /sys/class/thermal/thermal_zone0/temp
}

function get_lid_state {
    setup_serial
    exec 99<>/dev/ttymxc1
    :<&99
    printf "l\r" >&99
    IFS=$':\t\r'
    read -r -t 1 msg lid_state <&99
    lid_state=$(echo "$lid_state" | tr -dc '0-9')
    
    exec 99>&-
}

function reset_bat_capacity {
    setup_serial
    exec 99<>/dev/ttymxc1
    :<&99
    printf "0600b\r" >&99
    exec 99>&-
}

function system_suspend {
    setup_serial
    
    # wake up on serial port 2 traffic
    echo enabled > /sys/devices/soc0/soc/2100000.aips-bus/21e8000.serial/tty/ttymxc1/power/wakeup
    
    # drain serial port
    set +e; timeout 1 head /dev/ttymxc1; set -e

    # zzZzzZ
    # TODO enable this to actually suspend
    #systemctl suspend
}

function regulate_fan {
    get_soc_temperature

    if [ "$soc_temperature" -lt 65000 ]
    then
        set_fan_speed 5000
    fi

    if [ "$soc_temperature" -gt 70000 ]
    then
        set_fan_speed 10000
    fi
}

voltage_alert=0
function regulate_voltage {
    # TODO low voltage/capacity alert
    echo "not yet implemented"
}

function main {
    # 1. if the system is getting too hot, we want to cool it with the fan
    regulate_fan

    # 2. log all stats, especially battery stats, to a TSV file
    # so it can be graphed and we can estimate remaining running time
    # TODO actually append to log and rotate it out
    # TODO interval?
    timestamp=$(date +%Y-%m-%dT%H:%M:%S)
    get_soc_temperature
    get_battery_state
    get_lid_state

    if [ "$bat_amps" == "0.00A" ]
    then
        reset_bat_capacity
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$timestamp" "$soc_temperature" "$bat_capacity" "$bat_volts" "$bat_amps" "$voltage_alert" "$lid_state"
    printf '%s,%s,%s,%s,%s,%s,%s\n' "$timestamp" "$soc_temperature" "$bat_capacity" "$bat_volts" "$bat_amps" "$voltage_alert" "$lid_state" > /var/log/reformd

    # 3. if the lid is closed, we want to suspend the system
    # important: this works only if the kernel option no_console_suspend=1 is set!
    # also, requires kernel patch when using PCIe cards: https://github.com/sakaki-/novena-kernel-patches/blob/master/0017-pci-fix-suspend-on-i.MX6.patch
    # (workaround for erratum "PCIe does not support L2 Power Down")
    if [ "$lid_state" ] && [ "$lid_state" -eq "1" ]
    then
        system_suspend
        exit
    fi
}

brightnessctl s 5
disable_echo

while true; do
    main
    sleep 1
done

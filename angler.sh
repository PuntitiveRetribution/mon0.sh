#!/system/bin/sh
#config
iface=wlan0
rmac=$(hexdump -n3 -e’/3 “00:20:91” 3/1 “:%02X”’ /dev/random) #lol
rhost=$(hexdump -n3 -e’/3 “LOCAL-”3/1 “%02X”’ /dev/random)
ctime=$(date +%r)
mount -o rw,remount /vendor
mount -o rw,remount /system
trap ctrl_c INT
function ctrl_c() {
echo “[ Quitting ]”
sleep 2
#restore orginal firmware (patch breaks wifi hotspot or ap mode)
print “[ Restoring Orginal Firmware ]”
cp /system/mon/fw_bcmdhd.orig.bin /vendor/firmware/fw_bcmdhd.bin
ifconfig $iface down && ifconfig $iface up
exit 0
}
clear
print [“ Disabling Wifi “]
svc wifi disable
ifconfig $iface down
print “[ Backup Original Firmware ]”
cp /vendor/firmware/fw_bcmdhd.bin /system/mon/fw_bcmdhd.orig.bin
sleep 1
print “[ Installing Nexmon Firmware ]”
cp /system/mon/fw_bcmdhd.bin /vendor/firmware/fw_bcmdhd.bin
ifconfig $iface down && ifconfig $iface up
sleep 1
print “[ Setting Random Host Name ]”
sleep 1
setprop net.hostname $rhost
print “ [!] Host Name : “$(getprop net.hostname)
sleep 2
print “[ Enabling Wifi ]”
svc wifi enable
ifconfig $iface up
print “[ Setting Random MAC Address ]”
ifconfig $iface hw ether $rmac
print “ [!] Original MAC Addr : “$(getprop ro.boot.wifimacaddr)
print “ [!] Current MAC Addr : “$(cat /sys/class/net/wlan0/address)
sleep 2
print “[ Enabling Monitor Mode ]”
nexutil -m2
print “ [!] “ $(nexutil -m)
sleep 2
print “[ Loading nexmon ioctl ]”
print [“ Starting Airodump-ng “]
sleep 1
LD_PRELOAD=libnexmon.so airodump-ng -w “$ctime” $iface

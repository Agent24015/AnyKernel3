# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Cosmic by Someone @ xda-developers
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=violet
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=11
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=none;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel install
dump_boot;

if mountpoint -q /data; then
  # Optimize F2FS extension list (@arter97)
  for list_path in $(find /sys/fs/f2fs* -name extension_list); do

    ui_print "  • Optimizing F2FS extension list"
    echo "Updating extension list: $list_path"

    echo "Clearing extension list"

    hot_count="$(grep -n 'hot file extens' $list_path | cut -d':' -f1)"
    list_len="$(cat $list_path | wc -l)"
    cold_count="$((list_len - hot_count))"

    cold_list="$(head -n$((hot_count - 1)) $list_path | grep -v ':')"
    hot_list="$(tail -n$cold_count $list_path)"

    for ext in $cold_list; do
      [ ! -z $ext ] && echo "[c]!$ext" > $list_path
    done

    for ext in $hot_list; do
      [ ! -z $ext ] && echo "[h]!$ext" > $list_path
    done

    echo "Writing new extension list"

    for ext in $(cat $home/f2fs-cold.list | grep -v '#'); do
      [ ! -z $ext ] && echo "[c]$ext" > $list_path
    done

    for ext in $(cat $home/f2fs-hot.list); do
      [ ! -z $ext ] && echo "[h]$ext" > $list_path
    done
  done
fi

UCLAMP=1

# Uclamp tunables
if [ $UCLAMP = 1 ]; then
	ui_print "  • Uclamp supported kernel"
	# Uclamp tuning
	sysctl -w kernel.sched_util_clamp_min_rt_default=500
	sysctl -w kernel.sched_util_clamp_min=128
	sysctl -w net.ipv4.tcp_congestion_control=westwood
	#top-app
	echo max > /dev/cpuset/top-app/uclamp.max
	echo 10  > /dev/cpuset/top-app/uclamp.min
	echo 1   > /dev/cpuset/top-app/uclamp.boosted
	echo 1   > /dev/cpuset/top-app/uclamp.latency_sensitive


	#foreground
	echo 50 > /dev/cpuset/foreground/uclamp.max
	echo 0  > /dev/cpuset/foreground/uclamp.min
	echo 0  > /dev/cpuset/foreground/uclamp.boosted
	echo 0  > /dev/cpuset/foreground/uclamp.latency_sensitive


	#background
	echo max > /dev/cpuset/background/uclamp.max
	echo 20  > /dev/cpuset/background/uclamp.min
	echo 0   > /dev/cpuset/background/uclamp.boosted
	echo 0   > /dev/cpuset/background/uclamp.latency_sensitive


	#system-background
	echo 40 > /dev/cpuset/system-background/uclamp.max
	echo 0  > /dev/cpuset/system-background/uclamp.min
	echo 0  > /dev/cpuset/system-background/uclamp.boosted
	echo 0  > /dev/cpuset/system-background/uclamp.latency_sensitive

	#camera-daemon
	echo 20 > /dev/cpuset/camera-daemon/uclamp.max
	echo 0 > /dev/cpuset/camera-daemon/uclamp.min
	echo 0  > /dev/cpuset/camera-daemon/uclamp.latency_sensitive

	#additional optimizations
	echo 0 > /proc/sys/kernel/sched_schedstats
	echo -1 > /proc/sys/kernel/sched_rt_runtime_us
	echo 0 > /sys/block/mmcblk1/queue/iostats
	echo 0 > /sys/block/mmcblk0/queue/iostats
fi

write_boot;
## end install


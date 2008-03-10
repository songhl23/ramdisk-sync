#!/bin/sh
# Usage: mkramdisk.sh RAMDISK_SIZE(MB) [VOLUME_NAME] [hide]

NUMSECTORS=128000
if [ "$1" != "" ]; then
   NUMSECTORS=`echo $1*1024*2 | bc`
fi
DISK_NAME=Ramdisk
if [ "$2" != "" ]; then
   DISK_NAME="$2"
fi

MOUNT_PATH=/Volumes/$DISK_NAME

mydev=`hdid -nomount ram://$NUMSECTORS | cut -d' ' -f1`
partition="${mydev}s1"
rdev=`echo $mydev | sed -e 's/disk/rdisk/'`
rpartition=`echo $partition | sed -e 's/disk/rdisk/'`
echo "Create ram disk on [$mydev]"

echo y | fdisk -ia hfs $mydev
newfs_hfs -v "$DISK_NAME" $partition
#diskutil eraseDisk HFS+ $DISK_NAME $mydev
if [ "$3" = "hide" ] ; then
   hdiutil mount -nobrowse $rdev
   hdiutil mount -nobrowse $rpartition
else
   hdiutil mount $rdev
   hdiutil mount $rpartition
fi

mkdir $MOUNT_PATH/.fsevents
touch $MOUNT_PATH/.fsevents/no_log

#newfs_hfs $mydev
#mkdir -p $MOUNT_PATH
#mount -t hfs $mydev $MOUNT_PATH
#hdiutil mountvol 
#diskutil mount $mydev

# partition, format, mount
#diskutil eraseDisk HFS+ Ramdisk $mydev

# hide Ramdisk in Finder
#hdiutil attach -nobrowse $mydev #$MOUNT_PATH

#diskutil partitionDisk $mydev 1 HFS+ Ramdisk 100%
#newfs_hfs -v Ramdisk $mydev
#hdiutil attach $mydev #$MOUNT_PATH

#umount&eject: hdiutil detach $MOUNT_PATH

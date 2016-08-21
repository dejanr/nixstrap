set -x

DISK_SIZE=$(parted /dev/sda unit MB print | grep '^Disk' | sed -r 's/.* ([0-9]+)MB.*/\1/')

# Partitions
partition_drive() {
  local drive=$1
  local index=$2

  # bios+grub
  parted            -s ${drive} "mklabel gpt"
  parted -a optimal -s ${drive} "mkpart biosboot${index} ext4 1m 2m"
  parted            -s ${drive} "set 1 bios_grub on"
  mkfs.ext4 -m 0 ${drive}1

  # /boot
  parted -a optimal -s ${drive} "mkpart boot${index} ext4 2m 256m"
  parted            -s ${drive} "set 2 raid on"

  # /
  parted -a optimal -s ${drive} "mkpart root${index} zfs 256m $(($DISK_SIZE - 10000))"

  # swap
  parted -a optimal -s ${drive} "mkpart swap${index} ext4 $(($DISK_SIZE - 10000)) 100%"
  mkswap -L swap${index} ${drive}4
  swapon ${drive}4
}

partition_drive /dev/sda 0
partition_drive /dev/sdb 1

# Create the filesystems
zpool create -f -o ashift=12 rpool mirror /dev/sda3 /dev/sdb3
zfs create -o mountpoint=none -o checksum=fletcher4 -o atime=off rpool/root
zfs create -o mountpoint=legacy rpool/root/nixos

# Mount the filesystems manually
mkdir /mnt
mount -t zfs rpool/root/nixos /mnt

# Mount boot
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot

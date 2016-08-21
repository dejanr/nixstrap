umount /mnt/boot
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sda2
mdadm --zero-superblock /dev/sdb2

umount /mnt
zpool destroy -f rpool

swapoff /dev/sda4
swapoff /dev/sdb4

parted -s /dev/sda "mklabel gpt"
parted -s /dev/sdb "mklabel gpt"

#!/usr/bin/env bash
# LP14 ext4/xfs 元数据性能对照：同盘双 loop 设备，各建 2 万个 4KiB 小文件，三轮
set -u
cd "$(dirname "$0")"
echo '$ sudo -E bash run.sh'
LOG=results
mkdir -p "$LOG"
RUNLOG="$LOG/run-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$RUNLOG") 2>&1

WORK=/var/tmp/meta-bench
MNTEXT4=/mnt/meta-ext4
MNTXFS=/mnt/meta-xfs
IMGEXT4=$WORK/ext4.img
IMGXFS=$WORK/xfs.img
IMGSIZE_MB=4096
ROUNDS=${ROUNDS:-3}

cleanup() {
  mountpoint -q "$MNTEXT4" && sudo umount "$MNTEXT4"
  mountpoint -q "$MNTXFS" && sudo umount "$MNTXFS"
  losetup -a | grep -q "$IMGEXT4" && sudo losetup -d "$(losetup -j "$IMGEXT4" | cut -d: -f1)"
  losetup -a | grep -q "$IMGXFS" && sudo losetup -d "$(losetup -j "$IMGXFS" | cut -d: -f1)"
  rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$WORK" "$MNTEXT4" "$MNTXFS"

echo "== kernel =="; uname -a
echo "== tool versions =="; mkfs.ext4 -V 2>&1 | head -1; mkfs.xfs -V | head -1
echo "== build =="
make clean >/dev/null 2>&1 || true
make || exit 1

truncate -s "${IMGSIZE_MB}M" "$IMGEXT4" "$IMGXFS"
LOOPEXT4=$(sudo losetup --show -f "$IMGEXT4")
LOOPXFS=$(sudo losetup --show -f "$IMGXFS")
echo "loop devices: ext4=$LOOPEXT4 xfs=$LOOPXFS"
sudo mkfs.ext4 -F -q "$LOOPEXT4"
sudo mkfs.xfs -fq "$LOOPXFS"
sudo mount -t ext4 "$LOOPEXT4" "$MNTEXT4"
sudo mount -t xfs "$LOOPXFS" "$MNTXFS"
sudo chown "$(id -u):$(id -g)" "$MNTEXT4" "$MNTXFS"
echo "== mount =="; mount | grep meta-
echo "== inode capacity =="; df -i "$MNTEXT4" "$MNTXFS"

run_fs() {
  local fs="$1" mnt="$2"
  for r in $(seq 1 "$ROUNDS"); do
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
    echo "-- fs=$fs round=$r phase=create"
    ./meta_bench -r "$mnt/tree" -m create -d 100 -f 200 -s 4096 | sed "s/^/fs=$fs round=$r /"
    echo "-- fs=$fs round=$r phase=scan"
    ./meta_bench -r "$mnt/tree" -m scan -d 100 -f 200 | sed "s/^/fs=$fs round=$r /"
    echo "-- fs=$fs round=$r phase=delete"
    ./meta_bench -r "$mnt/tree" -m delete -d 100 -f 200 | sed "s/^/fs=$fs round=$r /"
  done
}

run_fs ext4 "$MNTEXT4"
run_fs xfs "$MNTXFS"
echo "== DONE =="

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$ROOT/scripts/common.sh"

need_cmd curl
need_cmd ar
need_cmd tar
mkdir -p "$ASSETS" "$OUT"

while IFS=$'\t' read -r name expected url; do
  case "$name" in ''|\#*) continue ;; esac
  file="$ASSETS/$name"
  if [ ! -f "$file" ]; then
    printf 'Downloading %s\n' "$name"
    rm -f "$file.part"
    curl -fL --retry 3 --output "$file.part" "$url"
    actual="$(sha256_file "$file.part")"
    if [ "$actual" != "$expected" ]; then
      rm -f "$file.part"
      fail "checksum mismatch: $name"
    fi
    mv "$file.part" "$file"
  fi
  actual="$(sha256_file "$file")"
  [ "$actual" = "$expected" ] || fail "checksum mismatch: $name"
  printf 'SHA256 OK  %s  %s\n' "$actual" "$name"
done < "$ROOT/scripts/assets.manifest"

DEB="$ASSETS/u-boot-qemu_2024.01+dfsg-1ubuntu5_all.deb"
if [ ! -f "$UBOOT" ]; then
  rm -rf "$OUT/uboot"
  mkdir -p "$OUT/uboot"
  (
    cd "$OUT/uboot"
    ar -x "$DEB"
    tar -xf data.tar.* usr/lib/u-boot/qemu-riscv64_smode/u-boot.bin
    cp usr/lib/u-boot/qemu-riscv64_smode/u-boot.bin "$UBOOT"
  )
fi
[ -s "$UBOOT" ] || fail "U-Boot extraction produced an empty file"
printf 'Ready: %s\n' "$IMAGE"
printf 'Ready: %s\n' "$UBOOT"

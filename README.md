# Prateek Unlocker v2.0 🔓⚡

A simple menu-based **Termux** tool for **Xiaomi / Redmi / POCO** phones:
**bootloader unlock** (Xiaomi's official process) **+ ROM flasher** (custom ROM zips, Xiaomi fastboot ROMs, recovery/boot images) — all from a second Android phone over an OTG cable, no PC.

Made by **Prateek Sharma (Pratiyush Sharma)**.

## Features
**Unlock**
- [1] Setup — installs [MiUnlockTool](https://github.com/MiForge/MiUnlockTool), [termux-adb / termux-fastboot](https://github.com/nohajc/termux-adb), unzip
- [2] Device check in fastboot · [3] Bootloader unlock (Mi account → official unlock key) · [4] Unlock status · [5] Reboot

**ROM Flasher (new in v2.0)**
- **[7] Flash ROM (Recovery ZIP)** — lists ROM zips in `/sdcard/Download`, reads the ROM's target device from the zip (`pre-device`), reads the connected phone's codename, **refuses on mismatch** (unless you type `FORCE`), then flashes with `adb sideload`
- **[8] Flash Fastboot ROM (Xiaomi .tgz)** — extracts the ROM, finds `flash_all.sh` / `flash_all_except_storage.sh` (keep data), checks the phone's `product` against the ROM, **refuses on mismatch**, and runs Xiaomi's own flash script through termux-fastboot
- **[9] Flash recovery/boot image** — `recovery`, `boot`, `vendor_boot` or `init_boot`, or a safe temporary `fastboot boot` test
- Every flash: bootloader-unlocked check, big data-wipe / brick warning, typed `yes` confirmation

## What it does NOT do (be honest)
The tool automates the commands and safety checks. **You still have to:**
- Unlock the bootloader first (Xiaomi's bind + wait time rules apply — nothing bypasses them)
- Download a ROM / recovery made for **your exact codename** (check with `getprop ro.product.device` on the target phone) and put it in `/sdcard/Download`
- Boot the target phone into **fastboot** (Power + Vol Down) or **recovery** (Power + Vol Up), and start **ADB sideload** in recovery
- Connect the two phones with an OTG / Type-C to Type-C cable

> ⚠️ Unlocking and flashing can **erase all data**. A wrong ROM/image can **brick** the phone. Don't flash an older stock ROM (anti-rollback). Keep both phones charged.

## Requirements
- 2 Android phones + OTG / Type-C to Type-C cable
- Termux + Termux:API (both from F-Droid, or both from GitHub — same source)

## Install & run
```sh
curl -sL https://raw.githubusercontent.com/MahaRajaPrateek/prateek-unlocker/main/unlock.sh -o unlock.sh && bash unlock.sh
```
Run **[1] Setup** first.

## Usage
- **Unlock:** [1] Setup → phone in fastboot + OTG → [2] Check → [3] Unlock
- **Custom ROM (zip):** [9] flash the recovery (OrangeFox/TWRP) for your phone → boot into recovery → [7] pick the ROM zip → start ADB Sideload on the phone
- **Xiaomi stock fastboot ROM (.tgz):** put the .tgz in Download → phone in fastboot → [8] → choose *except storage* (keep data) or *flash all* (clean)

### If `pkg update` fails (mirror error)
```sh
echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list && dpkg --configure -a && apt update && apt install -y curl
```

## Credits
- MiUnlockTool by offici5l / MiForge
- termux-adb by nohajc

Use at your own risk.

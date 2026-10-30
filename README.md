# Prateek Unlocker 🔓

A simple menu-based **Termux** helper to unlock the bootloader of **Xiaomi / Redmi / POCO** phones using Xiaomi's official unlock process.

Made by **Prateek Sharma (Pratiyush Sharma)**.

## What it does
- Installs the needed tools ([MiUnlockTool](https://github.com/MiForge/MiUnlockTool) + [termux-adb/fastboot](https://github.com/nohajc/termux-adb))
- Checks the phone in fastboot mode over OTG
- Logs in to your Mi account and requests the official unlock key from Xiaomi
- Unlock status check and reboot

> ⚠️ This does **not** bypass Xiaomi's rules. Your Mi account must be bound in *Developer options → Mi Unlock status*, and Xiaomi's permission / wait time still applies.
> ⚠️ Unlocking **erases all data** on the phone.

## Requirements
- 2 Android phones + OTG / Type-C to Type-C cable
- Termux + Termux:API (from F-Droid or GitHub, same source)

## Install & run
```sh
curl -sL https://raw.githubusercontent.com/MahaRajaPrateek/prateek-unlocker/main/unlock.sh -o unlock.sh && bash unlock.sh
```
Run **[1] Setup** first, then **[3] Unlock**.

### If `pkg update` fails (mirror error)
```sh
echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list && dpkg --configure -a && apt update && apt install -y curl
```

## Credits
- MiUnlockTool by offici5l / MiForge
- termux-adb by nohajc

Use at your own risk.

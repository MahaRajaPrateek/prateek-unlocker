# Prateek Unlocker v1.0 — JARVIS RUN

Termux tool (Android) jo **ek phone se dusre phone** ka Xiaomi / Redmi / POCO bootloader unlock karta hai aur custom ROM flash karta hai, OTG / C-to-C cable se. PC ki zarurat nahi.

Special: **Redmi Note 14 5G (beryl)** pe TWRP/OrangeFox nahi hai, isliye tool **recovery ke bina** custom ROM flash karta hai (AUTO / payload.bin / ROM ki apni recovery / GSI).

> ⚠️ Honest note: ye tool abhi kisi real Note 14 5G pe test nahi hua hai. Sirf TEST MODE (nakli phone) mein har step check hua hai. Pehli baar spare phone pe ya poora backup leke try karo.

## Install (Termux)

```
curl -sL https://raw.githubusercontent.com/MahaRajaPrateek/prateek-unlocker/main/unlock.sh -o unlock.sh && bash unlock.sh
```

Pehli baar chalane pe tool khud ko `JARVIS` command ke roop mein install kar leta hai. Uske baad kabhi bhi:

| Command | Kya hota hai |
|---|---|
| `JARVIS RUN` (ya `jarvis run`) | Tool khulta hai: Iron Man suit + J.A.R.V.I.S boot animation + "Jarvis activated" sound, phir menu |
| `JARVIS TEST` | **TEST MODE**: poora tool demo mein, koi phone nahi chahiye, kuch flash nahi hota |
| `JARVIS RUN --fast` | Intro skip (intro ke beech koi bhi key dabane se bhi skip) |
| `JARVIS` | Sirf yaad dilata hai: "Tool kholne ke liye likho: JARVIS RUN" |

Sound ke liye: Menu 1 (Setup) `play-audio` install karta hai (ya Termux:API app ho to `termux-media-player`). Sound na chale to tool chup-chaap aage badh jata hai.

## Menu

1. Setup (pehli baar: termux-adb, MiUnlockTool, payload-dumper-go, play-audio)
2. Device check (fastboot)
3. Bootloader UNLOCK (Mi account se, official Xiaomi tarika)
4. Unlock status check
5. Reboot phone
6. Help / Steps
7. Flash ROM (Recovery ZIP, ADB sideload)
8. Flash Fastboot ROM (Xiaomi stock .tgz)
9. Flash recovery/boot image
10. **AUTO Custom ROM Flash (Note 14 5G)**
11. ROM ZIP flash bina recovery (payload.bin)
12. ROM ki apni recovery + sideload
13. GSI flash (system.img)

## Redmi Note 14 5G (beryl) — recovery ke bina custom ROM

Beryl pe TWRP/OrangeFox available nahi hai, isliye option 7 aur 9 (recovery wala) ki jagah **10–13** use karo.

**[10] AUTO** — ROM ki ZIP chuno, tool khud dekhta hai:
- ROM zip ke andar (ya uske bagal mein Download folder mein) ROM ki apni recovery images (`vendor_boot.img` / `boot.img` / `dtbo.img`) mili → **raasta 12**
- Recovery images nahi mili par zip mein `payload.bin` hai → **raasta 11**
- Kaunsa raasta aur kyun, pehle screen pe batata hai, phir ek "yes" aur kaam shuru.

**[11] payload.bin:** ZIP se images nikalta hai (payload-dumper-go) → boot/dtbo/vbmeta/vendor_boot bootloader fastboot se (dono slot) → fastbootd mein reboot → system/vendor/product/odm flash → (optional format data) → reboot.

**[12] ROM ki apni recovery:** ROM ki boot/vendor_boot/dtbo fastboot se flash → ROM ki recovery mein reboot → (Format data) → "Apply update > Apply from ADB" → tool ZIP sideload karta hai.

**[13] GSI:** vbmeta disable (stock vbmeta.img ya tool khud khali vbmeta banata hai) → fastbootd mein system.img flash → (format data) → reboot.

Har flash se pehle tool check karta hai:
- ROM ka codename = phone ka codename (galat ROM pe hard stop)
- Bootloader unlocked hai
- Image ka type partition se match karta hai
- Extract se pehle free space
- Har fastboot/adb/extract step: error aate hi **wahi ruk jata hai** aur Hinglish mein batata hai kya karna hai (aadha flash karke aage nahi badhta)
- fastbootd mein "not enough space" aaye to purani `-cow` / dusre slot ki partitions saaf karke ek baar dobara try
- Har flash ka log: `~/prateek_flash.log`

## TEST MODE (`JARVIS TEST`)

- Bada peela banner: "TEST MODE — koi phone flash nahi hoga"
- Fastboot / adb / payload-dumper / Mi unlock sab nakli functions pe jaate hain (nakli unlocked beryl, slot a, "[TEST] ... OKAY")
- `~/jarvis-test/` mein dummy ROM ban jaate hain: ek payload.bin wala (AUTO → 11), ek recovery images wala (AUTO → 12), ek GSI image (13)
- Menu mein **[E] Fake error ON/OFF**: ON karke dekho ki error pe tool kaise rukta hai

## Safety

- Unlock aur custom ROM se phone ka **SARA DATA DELETE** ho sakta hai. Pehle backup.
- Sirf apne phone ke codename (beryl) ka ROM daalo. Galat ROM = brick.
- Purana/downgrade stock ROM mat daalo (anti-rollback).
- Flash ke beech cable mat nikalo, dono phone 50%+ charge.
- 2 phone chahiye: ek phone khud ko unlock/flash nahi kar sakta.
- Apne risk pe use karo. Ye tool kisi real phone pe abhi test nahi hua hai.

## Credits

- [MiUnlockTool](https://github.com/MiForge/MiUnlockTool) (`miunlock`) — Xiaomi bootloader unlock
- [termux-adb](https://github.com/nohajc/termux-adb) — adb/fastboot over OTG in Termux
- [payload-dumper-go](https://github.com/ssut/payload-dumper-go) — payload.bin extract

Made by **MahaRajaPrateek** — v1.0

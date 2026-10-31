#!/data/data/com.termux/files/usr/bin/bash
# Prateek Unlocker v1.0 - Xiaomi/Redmi/POCO bootloader unlock + ROM flash helper for Termux
# v1.0: recovery-less custom ROM flashing for Redmi Note 14 5G (beryl): payload.bin, ROM's own recovery + sideload, GSI
# v1.0: beryl safe reboot (kabhi 'fastboot reboot recovery' nahi) + LunarisAOSP / LineageOS official-steps mode [14]
# Uses official Xiaomi account authorization via MiUnlockTool (github.com/MiForge/MiUnlockTool)
# and termux-adb / termux-fastboot (github.com/nohajc/termux-adb). Needs 2 phones + OTG / C-to-C cable.

# --- self-install: Termux mein kabhi bhi "JARVIS RUN" likh ke tool kholo ---
if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ] && [ -f "$0" ] && grep -q "Prateek Unlocker" "$0" 2>/dev/null \
   && [ "$(realpath "$0" 2>/dev/null)" != "$(realpath "$PREFIX/bin/JARVIS" 2>/dev/null)" ]; then
  if cp "$0" "$PREFIX/bin/JARVIS" 2>/dev/null && chmod +x "$PREFIX/bin/JARVIS"; then
    ln -sf JARVIS "$PREFIX/bin/jarvis" 2>/dev/null; rm -f "$PREFIX/bin/prateek"
    echo -e "\033[1;32m[OK] Ab Termux mein kabhi bhi likho: JARVIS RUN\033[0m"; sleep 2
  fi
fi
# --- launch: JARVIS RUN (tool) / JARVIS TEST (demo, koi phone nahi) / --fast (intro skip) ---
MODE=""; FAST=""
for a in "$@"; do case "${a,,}" in run) MODE=run;; test) MODE=test;; --fast|fast) FAST=1;; esac; done
case "$(basename "$0")" in JARVIS|jarvis)
  [ -n "$MODE" ] || { echo -e "\033[1;33mTool kholne ke liye likho: JARVIS RUN\033[0m"; echo -e "\033[1;33mBina phone ke demo: JARVIS TEST\033[0m"; exit 0; };;
esac
[ "$MODE" = "test" ] && TEST=1 || TEST=""
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; N='\033[0m'
banner(){ clear; echo -e "${C}"
echo " ____            _            _    "
echo "|  _ \ _ __ __ _| |_ ___  ___| | __"
echo "| |_) | '__/ _\` | __/ _ \/ _ \ |/ /"
echo "|  __/| | | (_| | ||  __/  __/   < "
echo "|_|   |_|  \__,_|\__\___|\___|_|\_\\"
echo -e "   ${Y}UNLOCKER + ROM FLASHER v1.0${N}"
echo -e "${C}------------------------------------${N}"
[ -n "$TEST" ] && test_banner; }
test_banner(){ echo -e "${Y}########################################"
echo -e "  TEST MODE — koi phone flash nahi hoga"
echo -e "  (sab nakli/demo hai, phone mat lagao)"
echo -e "########################################${N}"
echo -e " Fake error: $([ -n "$FAKE_ERR" ] && echo "${R}ON${N}" || echo "${G}OFF${N}")   Dummy ROM: ${C}~/jarvis-test/${N}"; }
pause(){ echo; read -rp "Enter dabao menu pe jaane ke liye..." _; }
setup(){ if [ -n "$TEST" ]; then echo -e "${Y}[TEST] Setup: asli tool mein yahan packages install hote (termux-adb, miunlock, payload-dumper-go, play-audio).${N}"
    command -v unzip >/dev/null || { echo -e "${Y}[TEST] Demo ke liye sirf 'unzip' chahiye, install ho raha hai...${N}"; pkg install -y unzip; }
    sleep 1; echo -e "${G}[TEST] Setup done (demo)${N}"; pause; return; fi
  echo -e "${Y}[*] Packages install ho rahe hain...${N}"
  apt update && apt install -y python-pip curl termux-api play-audio unzip tar xz-utils coreutils
  pip install -U miunlock
  command -v termux-fastboot >/dev/null || curl -s https://raw.githubusercontent.com/nohajc/termux-adb/master/install.sh | bash
  install_pdg
  command -v miunlock >/dev/null && command -v termux-adb >/dev/null && echo -e "${G}[+] Setup done!${N}" || echo -e "${R}[-] Setup fail, internet check karo${N}"; pause; }
check(){ echo -e "${Y}[*] Dusra phone FASTBOOT mode mein OTG se lagao (Power + Volume Down)${N}"
  echo -e "${Y}[*] USB permission popup aaye to Allow karo${N}"
  termux-fastboot devices && termux-fastboot getvar product 2>&1 | head -3
  termux-fastboot getvar unlocked 2>&1 | head -2; pause; }
unlock(){ echo -e "${R}[!] WARNING: Unlock karne se phone ka SARA DATA DELETE ho jayega!${N}"
  echo -e "${R}[!] Pehle Settings > Developer options > Mi Unlock status mein account bind hona chahiye${N}"
  read -rp "Continue? (yes likho): " a; [ "$a" = "yes" ] || return
  echo -e "${Y}[*] Mi account se login karo, tool token lega aur unlock karega...${N}"
  command -v miunlock >/dev/null || { echo -e "${Y}[*] Pehle Setup chal raha hai...${N}"; setup; }
  miunlock; pause; }
lockcheck(){ termux-fastboot getvar unlocked 2>&1 | head -2; pause; }
reboot_(){ termux-fastboot reboot && echo -e "${G}[+] Reboot command bhej diya${N}"; pause; }

# ---------------- ROM flasher ----------------
need_tools(){ # tools missing ho to setup khud chala do
  if [ -n "$TEST" ]; then command -v unzip >/dev/null && return 0
    echo -e "${Y}[TEST] Demo ke liye 'unzip' chahiye, install ho raha hai...${N}"; pkg install -y unzip >/dev/null 2>&1 || apt install -y unzip
    command -v unzip >/dev/null || { echo -e "${R}[-] unzip install nahi hua. Likho: pkg install unzip${N}"; return 1; }; return 0; fi
  for t in termux-adb termux-fastboot unzip tar; do
    command -v "$t" >/dev/null || { echo -e "${Y}[*] $t nahi mila, pehle Setup chal raha hai...${N}"; setup; break; }
  done
  command -v termux-adb >/dev/null || { echo -e "${R}[-] termux-adb install nahi hua. Menu 1 (Setup) dobara chalao.${N}"; return 1; }; }
need_storage(){ [ -n "$TEST" ] && return 0; [ -r /sdcard/Download ] && return 0
  echo -e "${Y}[*] Storage permission chahiye, popup pe Allow karo...${N}"
  termux-setup-storage; sleep 4
  [ -r /sdcard/Download ] || { echo -e "${R}[-] /sdcard nahi khul raha. Termux ko Files/Storage permission do.${N}"; return 1; }; }
flash_warn(){ # $1 = kya flash ho raha hai
  echo -e "${R}=====================================================${N}"
  echo -e "${R}[!!!] KHATRA: $1${N}"
  echo -e "${R}[!] Phone ka SARA DATA DELETE ho sakta hai. Pehle backup le lo.${N}"
  echo -e "${R}[!] Galat ROM/image (dusre phone ka) = phone BRICK (dead) ho sakta hai.${N}"
  echo -e "${R}[!] Bootloader UNLOCKED hona zaroori hai (Menu 4 se check karo).${N}"
  echo -e "${R}[!] Purana/downgrade stock ROM mat daalo (anti-rollback brick ka risk).${N}"
  echo -e "${R}[!] Flash ke beech cable mat nikalo, dono phone 50%+ charge rakho.${N}"
  echo -e "${R}=====================================================${N}"
  read -rp "Sab samajh gaye? Continue karne ke liye 'yes' likho: " a
  [ "$a" = "yes" ] || { echo -e "${Y}[*] Cancel kar diya.${N}"; return 1; }; }
pick_file(){ # $1 = file pattern (e.g. "*.zip"), result -> $PICKED
  PICKED=""; local i=0 f files=()
  for f in $DL/$1 /sdcard/$1; do [ -f "$f" ] && files+=("$f"); done
  if [ ${#files[@]} -gt 0 ]; then
    echo -e "${C}Ye files mili:${N}"
    for f in "${files[@]}"; do i=$((i+1)); echo -e " ${G}[$i]${N} $(basename "$f") ($(du -h "$f" | cut -f1))"; done
    read -rp "Number likho ya pura path paste karo: " ans
  else
    echo -e "${Y}[*] $DL mein $1 file nahi mili.${N}"
    read -rp "File ka pura path likho (jaise /sdcard/Download/rom.zip): " ans
  fi
  ans="${ans%\"}"; ans="${ans#\"}"; ans="${ans%\'}"; ans="${ans#\'}"
  if [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le ${#files[@]} ]; then PICKED="${files[$((ans-1))]}"; else PICKED="$ans"; fi
  [ -f "$PICKED" ] || { echo -e "${R}[-] File nahi mili: $PICKED${N}"; PICKED=""; return 1; }
  echo -e "${G}[+] Selected: $PICKED${N}"; }
fb_product(){ termux-fastboot getvar product 2>&1 | sed -n 's/^product: *\([^ ]*\).*/\1/p' | head -1; }
fb_unlocked_check(){
  local u; u=$(termux-fastboot getvar unlocked 2>&1 | sed -n 's/^unlocked: *\([^ ]*\).*/\1/p' | head -1)
  if [ "$u" = "no" ]; then echo -e "${R}[-] Bootloader LOCKED hai! Pehle Menu 3 se unlock karo. Flash cancel.${N}"; return 1; fi
  [ "$u" = "yes" ] && echo -e "${G}[+] Bootloader unlocked hai.${N}" || echo -e "${Y}[?] Unlock status pata nahi chala, dhyan se aage badho.${N}"; }
wait_fastboot(){
  echo -e "${Y}[*] Target phone ko FASTBOOT mode mein daalo (Power + Volume Down) aur OTG se lagao${N}"
  echo -e "${Y}[*] USB permission popup aaye to Allow karo${N}"
  read -rp "Ready ho to Enter dabao..." _
  [ -n "$TEST" ] && fake_state bootloader
  FBPROD=$(fb_product)
  [ -n "$FBPROD" ] || { echo -e "${R}[-] Fastboot mein koi phone nahi mila. Cable/OTG aur permission check karo.${N}"; return 1; }
  echo -e "${G}[+] Phone mila, codename: ${C}$FBPROD${N}"; }

flash_zip(){ # [7] Recovery ZIP via ADB sideload
  need_tools || { pause; return; }; need_storage || { pause; return; }
  echo -e "${C}== Flash ROM (Recovery ZIP / ADB sideload) ==${N}"
  echo -e "${Y}Note: Phone mein custom recovery (OrangeFox/TWRP) ya ROM ki recovery honi chahiye.${N}"
  beryl_note
  pick_file "*.zip" || { pause; return; }; local zip="$PICKED"
  unzip -l "$zip" >/dev/null 2>&1 || { echo -e "${R}[-] Ye valid zip nahi hai (adhoori download?).${N}"; pause; return; }
  unzip -l "$zip" | grep -q 'META-INF/com/google/android/update-binary\|payload.bin' || echo -e "${Y}[?] Ye flashable ROM zip jaisa nahi lag raha (update-binary/payload.bin nahi mila).${N}"
  local want; want=$(unzip -p "$zip" META-INF/com/android/metadata 2>/dev/null | sed -n 's/^pre-device=//p' | tr -d '\r' | head -1)
  [ -n "$want" ] && echo -e "${G}[+] ROM kis phone ke liye hai: ${C}$want${N}" || echo -e "${Y}[?] ROM zip mein device naam nahi likha (metadata nahi mila).${N}"
  echo -e "${Y}[*] Target phone ko RECOVERY mein boot karo (Power + Volume Up) aur OTG se lagao.${N}"
  read -rp "Ready ho to Enter dabao..." _
  local state dev=""; state=$(termux-adb get-state 2>/dev/null)
  if [ "$state" = "device" ] || [ "$state" = "recovery" ]; then
    dev=$(termux-adb shell getprop ro.product.device 2>/dev/null | tr -d '\r')
  fi
  if [ -z "$dev" ]; then
    echo -e "${Y}[?] Phone ka codename khud se nahi padh paya (state: ${state:-not found}).${N}"
    read -rp "Target phone ka codename likho (jaise beryl): " dev
  fi
  echo -e "${G}[+] Connected phone: ${C}$dev${N}"
  if is_beryl "$dev"; then beryl_note; echo -e "${Y}[i] Phone mein ROM ki recovery (option 12 se) pehle se hai tabhi aage badho.${N}"; fi
  if [ -n "$want" ] && ! echo ",$want," | grep -q ",$dev,"; then
    echo -e "${R}[!!!] MISMATCH: ROM '$want' ke liye hai, phone '$dev' hai! Flash kiya to BRICK ho sakta hai.${N}"
    read -rp "Phir bhi karna hai to FORCE likho (warna Enter): " f; [ "$f" = "FORCE" ] || { echo -e "${Y}[*] Cancel. Sahi codename wala ROM download karo.${N}"; pause; return; }
  fi
  flash_warn "ROM flash: $(basename "$zip") -> $dev" || { pause; return; }
  echo -e "${C}Ab target phone pe recovery mein:${N}"
  echo -e " OrangeFox: Menu > ADB & Sideload > Swipe | TWRP: Advanced > ADB Sideload > Swipe"
  echo -e " Stock/ROM recovery: 'Apply update' > 'Apply from ADB'"
  echo -e "${Y}(Clean flash / naya ROM: pehle recovery mein Format Data / Factory reset karna padta hai - ROM ke instructions padho)${N}"
  read -rp "Sideload mode on ho gaya? Enter dabao..." _
  do_sideload "$zip" || { pause; return; }
  echo -e "${G}[+] Recovery se 'Reboot system' karo.${N}"; pause; }

flash_fastboot_rom(){ # [8] Xiaomi fastboot ROM (.tgz)
  need_tools || { pause; return; }; need_storage || { pause; return; }
  echo -e "${C}== Flash Fastboot ROM (Xiaomi .tgz) ==${N}"
  read -rp "Pehle se extract kiya folder hai? Uska path likho, warna Enter (tgz choose karo): " dir
  dir="${dir%\"}"; dir="${dir#\"}"
  if [ -z "$dir" ]; then
    pick_file "*.tgz" || { pause; return; }; local tgz="$PICKED" top
    top=$(tar -tf "$tgz" 2>/dev/null | head -1 | cut -d/ -f1)
    [ -n "$top" ] || { echo -e "${R}[-] tgz padh nahi paya (adhoori download?).${N}"; pause; return; }
    dir="$(dirname "$tgz")/$top"
    if [ -f "$dir/flash_all.sh" ]; then echo -e "${G}[+] Pehle se extracted mila: $dir${N}"
    else
      echo -e "${Y}[*] Extract ho raha hai (5-15 min, ~10GB free space chahiye)...${N}"
      space_check "$(dirname "$tgz")" $(( $(du -k "$tgz" | cut -f1) * 5 / 2 )) || { pause; return; }
      tar -xf "$tgz" -C "$(dirname "$tgz")" || { echo -e "${R}[-] Extract fail (space kam?).${N}"; pause; return; }
    fi
  fi
  local fa; fa=$(find "$dir" -maxdepth 3 -name flash_all.sh 2>/dev/null | head -1)
  [ -n "$fa" ] || { echo -e "${R}[-] flash_all.sh nahi mila. Ye Xiaomi FASTBOOT ROM hona chahiye (recovery zip nahi).${N}"; pause; return; }
  local rd; rd=$(dirname "$fa")
  local want; want=$(grep -m1 'getvar product' "$fa" | sed -n 's/.*product: *\**\([A-Za-z0-9_|()]*\).*/\1/p' | tr -d '()')
  echo -e "${G}[+] ROM folder: $rd${N}"; echo -e "${G}[+] ROM kis phone ke liye: ${C}${want:-pata nahi}${N}"
  echo -e " ${G}[1]${N} flash_all_except_storage.sh  (DATA BACHEGA - same ROM update ke liye)"
  echo -e " ${G}[2]${N} flash_all.sh                 (SAB DATA DELETE - clean flash)"
  read -rp "Choose (1/2): " m
  local sc; case $m in 1) sc="flash_all_except_storage.sh";; 2) sc="flash_all.sh";; *) echo "Cancel."; pause; return;; esac
  [ -f "$rd/$sc" ] || { echo -e "${R}[-] $sc is ROM mein nahi hai.${N}"; pause; return; }
  wait_fastboot || { pause; return; }
  fb_unlocked_check || { pause; return; }
  if [ -n "$want" ] && ! echo "|$want|" | grep -q "|$FBPROD|"; then
    echo -e "${R}[!!!] MISMATCH: ROM '$want' ke liye hai, phone '$FBPROD' hai! Flash cancel.${N}"; pause; return
  fi
  flash_warn "Fastboot ROM ($sc) -> $FBPROD" || { pause; return; }
  # fastboot -> termux-fastboot shim (script ke andar 'fastboot' calls isi se jayengi)
  local shim="$HOME/.prateek_shim"; mkdir -p "$shim"
  printf '#!%s\nexec termux-fastboot "$@"\n' "$(command -v bash)" > "$shim/fastboot"; chmod +x "$shim/fastboot"
  echo -e "${Y}[*] Flash shuru... 5-10 min lagenge. Cable mat chhuo!${N}"
  if ( cd "$rd" && PATH="$shim:$PATH" bash "./$sc" ); then
    echo -e "${G}[+] Flash script poori hui! Phone khud reboot hoga (pehla boot 5-10 min le sakta hai).${N}"
  else
    echo -e "${R}[-] Flash script error ke saath ruki. Upar ka error padho/screenshot lo. Phone ko fastboot mein hi rehne do aur dobara try karo.${N}"
  fi; pause; }

flash_img(){ # [9] boot/recovery image
  need_tools || { pause; return; }; need_storage || { pause; return; }
  echo -e "${C}== Flash recovery/boot image ==${N}"
  pick_file "*.img" || { pause; return; }; local img="$PICKED"
  echo -e " ${G}[1]${N} recovery     ${G}[2]${N} boot     ${G}[3]${N} vendor_boot     ${G}[4]${N} init_boot"
  echo -e " ${G}[5]${N} Sirf temporary boot karo (flash nahi, sabse safe test)"
  echo -e "${Y}Tip: Naye phones (jaise beryl) mein recovery partition nahi hota - recovery vendor_boot mein jaati hai. Recovery ke instructions padho.${N}"
  beryl_note
  read -rp "Choose: " p; local part
  case $p in 1) part=recovery;; 2) part=boot;; 3) part=vendor_boot;; 4) part=init_boot;; 5) part=TEMP;; *) echo "Cancel."; pause; return;; esac
  wait_fastboot || { pause; return; }
  fb_unlocked_check || { pause; return; }
  if is_beryl "$FBPROD" && [ "$part" = "recovery" ]; then beryl_note; echo -e "${R}[-] beryl pe 'recovery' partition hai hi nahi. Option 12 use karo.${N}"; pause; return; fi
  [ "$part" != "TEMP" ] && { img_check "$part" "$img" || { pause; return; }; }
  read -rp "Ye image sach mein '$FBPROD' phone ke liye bani hai? (yes likho): " ok
  [ "$ok" = "yes" ] || { echo -e "${Y}[*] Cancel. Sahi codename wali image lo.${N}"; pause; return; }
  if [ "$part" = "TEMP" ]; then
    termux-fastboot boot "$img" && echo -e "${G}[+] Image temporary boot ho rahi hai (reboot pe purana wapas).${N}" || echo -e "${R}[-] Boot fail. Image is phone ki nahi hai ya cable/permission ki dikkat. Phone fastboot mein hi rehne do.${N}"; pause; return
  fi
  flash_warn "$(basename "$img") -> $part partition ($FBPROD)" || { pause; return; }
  local slotarg=""; if is_beryl "$FBPROD" && [ "$part" = "vendor_boot" ]; then slotarg="--slot=all"; echo -e "${C}[i] beryl: vendor_boot dono slot (a+b) pe flash hoga (--slot=all)${N}"; fi
  fb $slotarg flash "$part" "$img" && echo -e "${G}[+] $part flash ho gaya!${N}" || { echo -e "${R}[-] Flash fail. Aage kuch nahi kiya. Phone fastboot mein hi rehne do, cable/image check karke dobara try karo.${N}"; pause; return; }
  if [ "$part" = "recovery" ] || [ "$part" = "vendor_boot" ]; then
    read -rp "Abhi recovery mein jaana hai? (y/n): " r
    [ "$r" = "y" ] && reboot_to_recovery_safe "$part"
  fi; pause; }

# ---------------- Note 14 5G: Redmi Note 14 5G (beryl) - recovery ke bina custom ROM ----------------
LOG="$HOME/prateek_flash.log"
WORK="$HOME/prateek_rom"
DL=/sdcard/Download
if [ -n "$TEST" ]; then TD="$HOME/jarvis-test"; DL="$TD"; LOG="$TD/test_flash.log"; WORK="$TD/work"; fi
PDG_VER="2.1.0"
LOGICAL_KNOWN=" system system_ext product vendor odm vendor_dlkm odm_dlkm system_dlkm mi_ext "
is_beryl(){ [[ "$1" == beryl* ]]; }
beryl_note(){
  echo -e "${Y}-----------------------------------------------------${N}"
  echo -e "${Y}[i] Redmi Note 14 5G (beryl) ke liye OrangeFox/TWRP available NAHI hai.${N}"
  echo -e "${Y}    Is phone pe recovery partition bhi nahi hai (recovery vendor_boot mein hoti hai).${N}"
  echo -e "${Y}    Recovery ke bina flash ke liye: ${G}[10]${Y} AUTO, ${G}[11]${Y} payload.bin, ${G}[12]${Y} ROM ki apni recovery, ${G}[13]${Y} GSI${N}"
  echo -e "${Y}    LunarisAOSP / LineageOS (official steps): ${G}[14]${N}"
  echo -e "${R}    [!] beryl pe 'fastboot reboot recovery' KABHI nahi - reboot ke baad Volume Up se recovery.${N}"
  echo -e "${Y}-----------------------------------------------------${N}"; }
volup_box(){ # beryl: recovery mein jaane ka SAFE tarika (Volume Up), 'fastboot reboot recovery' nahi
  echo -e "${R}#####################################################${N}"
  echo -e "${R}#  ${Y}Phone reboot hote hi turant VOLUME UP daba ke rakho${R}  #${N}"
  echo -e "${R}#  ${Y}        --> recovery khulegi${R}                         #${N}"
  echo -e "${R}#####################################################${N}"
  echo -e "${Y}  Recovery ki screen aane tak Vol Up mat chhodo.${N}"
  echo -e "${Y}  Miss ho gaya aur phone normal boot ho gaya? Phone band karo, phir Power + Volume Up saath dabao.${N}"
  echo -e "${R}  [!] 'fastboot reboot recovery' beryl ko BRICK kar sakta hai - ye tool wo command kabhi nahi bhejta.${N}"; }
reboot_to_recovery_safe(){ # $1 = flash ki gayi partition. beryl / vendor_boot: sirf 'fastboot reboot' + Vol Up
  if is_beryl "$FBPROD" || [ "$1" = "vendor_boot" ]; then
    volup_box
    read -rp "Target phone pe Volume Up pakad lo, phir Enter dabao (reboot bhejenge)..." _
    fb reboot || { fail "reboot fail" "Phone ko Power button se restart karo aur turant Volume Up daba ke rakho."; return 1; }
    [ -n "$TEST" ] && fake_state recovery # TEST: Vol Up se recovery khuli (nakli)
    echo -e "${Y}[*] Reboot bheja. VOLUME UP dabaye rakho jab tak recovery na dikhe!${N}"
  else
    fb reboot recovery || fb reboot
  fi; }
log(){ echo "[$(date '+%F %T')] $*" >> "$LOG"; }
fail(){ # $1 = kya fail hua, $2 = hint
  echo -e "${R}=====================================================${N}"
  echo -e "${R}[X] RUK GAYA: $1${N}"
  [ -n "$2" ] && echo -e "${Y}[>] Kya karein: $2${N}"
  echo -e "${Y}[>] Poora log: $LOG (screenshot bhejna ho to ye file dikhao)${N}"
  echo -e "${R}=====================================================${N}"; log "FAIL: $1"; return 1; }
fb(){ # termux-fastboot + log + exit code (output $FBOUT mein bhi)
  log "fastboot $*"; local t="$WORK/.fbout"; mkdir -p "$WORK"
  termux-fastboot "$@" </dev/null 2>&1 | tee -a "$LOG" | tee "$t"; local rc=${PIPESTATUS[0]}
  FBOUT=$(cat "$t" 2>/dev/null); log "rc=$rc"; return $rc; }
fbv(){ termux-fastboot getvar "$1" </dev/null 2>&1 | tr -d '\r' | sed -n "s|^$1: *||p" | head -1; }
fb_slot(){ local s; s=$(fbv current-slot); s="${s#_}"; echo "${s:0:1}"; }
fb_mode(){ # bootloader / fastbootd / none
  local p; p=$(fb_product); [ -n "$p" ] || { echo none; return; }
  [ "$(fbv is-userspace)" = "yes" ] && echo fastbootd || echo bootloader; }
wait_mode(){ # $1 = bootloader|fastbootd
  local n=0 m
  echo -e "${Y}[*] Phone ka '$1' mode mein aane ka wait... (USB permission popup aaye to Allow karo)${N}"
  while :; do
    m=$(fb_mode); [ "$m" = "$1" ] && { echo; echo -e "${G}[+] Phone '$1' mode mein hai.${N}"; return 0; }
    n=$((n+1))
    if [ $n -gt 40 ]; then
      echo; echo -e "${Y}[?] 2 min ho gaye, phone '$1' mein nahi mila (abhi: $m).${N}"
      read -rp "Cable dobara laga ke Enter dabao (ya 'q' likho rukne ke liye): " a
      [ "$a" = "q" ] && return 1; n=0
    fi
    echo -ne "\r${Y}[*] wait... ($n)${N}"; sleep 3
  done; }
fb_unlocked_strict(){
  local u; u=$(fbv unlocked)
  case "$u" in
    yes) echo -e "${G}[+] Bootloader unlocked hai.${N}";;
    no) fail "Bootloader LOCKED hai" "Pehle Menu 3 se unlock karo. Locked phone pe flash = brick ka risk."; return 1;;
    *) echo -e "${Y}[?] Phone ne unlock status nahi bataya.${N}"
       read -rp "Tumhe pakka pata hai bootloader UNLOCKED hai? (yes likho): " a
       [ "$a" = "yes" ] || { echo -e "${Y}[*] Cancel. Menu 4 se check karo.${N}"; return 1; };;
  esac; }
zip_device(){ unzip -p "$1" META-INF/com/android/metadata 2>/dev/null | tr -d '\r' | sed -n 's/^pre-device=//p' | head -1; }
codename_gate(){ # $1 = ROM ka device (pre-device, comma list ho sakta hai), $2 = phone ka product. Mismatch = hard stop.
  local want="$1" have="$2" w ok=""
  if [ -z "$want" ]; then
    echo -e "${Y}[?] ROM zip mein device ka naam nahi likha (metadata nahi mila).${N}"
    read -rp "ROM ke download page pe jo codename likha hai wo type karo: " want
    [ -n "$want" ] || { fail "Codename nahi diya" "ROM ke page pe codename dekho (Note 14 5G = beryl)"; return 1; }
  fi
  for w in $(echo "$want" | tr ',' ' '); do
    [ "$w" = "$have" ] && ok=1
    [ "${w%%_*}" = "${have%%_*}" ] && ok=1
  done
  if [ -z "$ok" ]; then
    fail "MISMATCH: ROM '$want' ke liye bana hai, par phone '$have' hai" "Sirf '$have' codename wala ROM download karo. Ye check bypass nahi hota - galat ROM = brick."
    return 1
  fi
  echo -e "${G}[+] Codename match: ROM '$want' = phone '$have'${N}"; }
img_magic(){ head -c 8 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n'; }
img_check(){ # $1 = partition, $2 = image. Image ka type partition se match karta hai?
  local m; m=$(img_magic "$2")
  case "$1" in
    boot|init_boot|recovery) [ "$m" = "414e44524f494421" ] || { fail "$(basename "$2") '$1' image nahi lagti (ANDROID! header nahi)" "Sahi file chuno."; return 1; };;
    vendor_boot) [ "$m" = "564e4452424f4f54" ] || { fail "$(basename "$2") vendor_boot image nahi lagti (VNDRBOOT header nahi)" "Sahi file chuno."; return 1; };;
    vbmeta*) [ "${m:0:8}" = "41564230" ] || { fail "$(basename "$2") vbmeta image nahi lagti (AVB0 header nahi)" "Sahi file chuno."; return 1; };;
    dtbo) [ "${m:0:8}" = "d7b7ab1e" ] || { fail "$(basename "$2") dtbo image nahi lagti" "Sahi file chuno."; return 1; };;
  esac; return 0; }
free_kb(){ df -Pk "$1" 2>/dev/null | awk 'NR==2{print $4}'; }
space_check(){ # $1 = dir, $2 = kitne KB chahiye
  local f; f=$(free_kb "$1")
  [ -n "$f" ] || { echo -e "${Y}[?] Free space check nahi ho paya.${N}"; return 0; }
  echo -e "${C}[i] Free space: $((f/1024/1024)) GB, chahiye ~$(( $2/1024/1024 + 1 )) GB${N}"
  [ "$f" -ge "$2" ] || { fail "Is phone mein jagah kam hai (free $((f/1024)) MB, chahiye ~$(( $2/1024 )) MB)" "Purani files/videos delete karo ya ROM zip ke alawa baaki downloads hatao, phir dobara chalao."; return 1; }; }
install_pdg(){ # payload-dumper-go (ssut) - static Go binary, GitHub release
  command -v payload-dumper-go >/dev/null && payload-dumper-go -h >/dev/null 2>&1 && { echo -e "${G}[+] payload-dumper-go pehle se hai.${N}"; return 0; }
  local a; case "$(uname -m)" in aarch64|arm64) a=linux_arm64;; armv7l|armv8l|arm) a=linux_armv7;; x86_64) a=linux_amd64;; *) fail "CPU $(uname -m) ke liye payload-dumper-go nahi hai"; return 1;; esac
  local t="${TMPDIR:-$HOME}/pdg_$$"; mkdir -p "$t"
  local base="https://github.com/ssut/payload-dumper-go/releases/download/$PDG_VER"
  local f="payload-dumper-go_${PDG_VER}_${a}.tar.gz"
  echo -e "${Y}[*] payload-dumper-go $PDG_VER ($a) download ho raha hai...${N}"
  curl -fsSL -o "$t/$f" "$base/$f" && curl -fsSL -o "$t/sums.txt" "$base/payload-dumper-go_sha256checksums.txt" \
    || { rm -rf "$t"; fail "payload-dumper-go download fail" "Internet check karke Setup [1] dobara chalao."; return 1; }
  ( cd "$t" && grep " $f\$" sums.txt | sha256sum -c - >/dev/null 2>&1 ) \
    || { rm -rf "$t"; fail "payload-dumper-go ka checksum match nahi hua (download kharab)" "Setup [1] dobara chalao."; return 1; }
  tar -xzf "$t/$f" -C "$t" payload-dumper-go && mv -f "$t/payload-dumper-go" "$PREFIX/bin/payload-dumper-go" && chmod +x "$PREFIX/bin/payload-dumper-go"
  rm -rf "$t"
  payload-dumper-go -h >/dev/null 2>&1 && echo -e "${G}[+] payload-dumper-go install ho gaya.${N}" \
    || { fail "payload-dumper-go chal nahi raha" "Termux update karo (pkg upgrade) aur Setup [1] dobara chalao."; return 1; }; }
need_pdg(){ command -v payload-dumper-go >/dev/null && return 0; install_pdg; }
pick_zip(){ need_tools || return 1; need_storage || return 1
  pick_file "*.zip" || return 1; ZIP="$PICKED"
  unzip -l "$ZIP" >/dev/null 2>&1 || { fail "Ye valid zip nahi hai" "Zip adhoori download hui hogi, dobara download karo."; return 1; }; }
zip_has(){ unzip -Z1 "$1" 2>/dev/null | grep -qx "$2"; }
goto_bootloader(){ # phone ko bootloader fastboot mein lao + unlock check
  wait_fastboot || return 1
  if [ "$(fbv is-userspace)" = "yes" ]; then
    echo -e "${Y}[*] Phone fastbootd mein hai, bootloader fastboot mein bhej rahe hain...${N}"
    fb reboot bootloader || { fail "reboot bootloader fail" "Phone ko khud Power + Vol Down se fastboot mein daalo, phir dobara chalao."; return 1; }
    wait_mode bootloader || return 1; FBPROD=$(fb_product)
  fi
  is_beryl "$FBPROD" || echo -e "${Y}[?] Ye option Redmi Note 14 5G (beryl) ke liye bana hai, phone '$FBPROD' hai. Codename check fir bhi hoga.${N}"
  fb_unlocked_strict; }
fmt_data_bootloader(){ # format data, Xiaomi flash_all jaisa: erase metadata + userdata
  echo -e "${Y}[*] Data format ho raha hai (metadata + userdata erase)...${N}"
  fb erase metadata || { fail "erase metadata fail" "Phone fastboot mein hai. Same option dobara chalao, ya ROM ki recovery se Format Data karo."; return 1; }
  fb erase userdata || { fail "erase userdata fail" "Phone fastboot mein hai. Same option dobara chalao, ya ROM ki recovery se Format Data karo."; return 1; }
  echo -e "${G}[+] Data format ho gaya.${N}"; }
ask_format(){ # FORMAT=1/0
  echo -e "${R}[!] FORMAT DATA: Stock HyperOS/MIUI se custom ROM pe aa rahe ho to ZAROORI hai (warna bootloop).${N}"
  echo -e "${R}    Isse phone ka SARA data (photos, apps, sab) DELETE hoga.${N}"
  read -rp "Format data karna hai? (y/n): " a; [ "$a" = "y" ] && FORMAT=1 || FORMAT=0; }
cow_cleanup(){ # fastbootd mein: *-cow aur dusre slot ki logical partitions delete (sirf jagah ke liye)
  local cur="$1" other p list; [ "$cur" = "a" ] && other=b || other=a
  list=$(termux-fastboot getvar all 2>&1 | tr -d '\r' | grep -o 'is-logical:[^:]*:yes' | cut -d: -f2 | sort -u)
  list=$(echo "$list" | grep -E -- "-cow\$|_${other}\$")
  [ -n "$list" ] || { echo -e "${Y}[i] Delete karne layak *-cow / _${other} partition nahi mili.${N}"; return 1; }
  echo -e "${Y}Super partition mein jagah banane ke liye ye purani partitions delete hongi (current slot _$cur ko kuch nahi hoga):${N}"
  echo "$list" | sed 's/^/   - /'
  read -rp "Delete karein? (yes likho): " a; [ "$a" = "yes" ] || return 1
  for p in $list; do fb delete-logical-partition "$p" || { fail "delete-logical-partition $p fail"; return 1; }; done
  echo -e "${G}[+] Cleanup ho gaya.${N}"; }
flash_logical(){ # $1 part $2 img $3 slot  - fastbootd mein, jagah kam ho to cleanup offer, phir ek retry
  fb flash "$1" "$2" && return 0
  if echo "$FBOUT" | grep -qiE 'space|resize|too large|no free|allocate'; then
    echo -e "${Y}[!] Super partition mein jagah kam hai.${N}"
    cow_cleanup "$3" && fb flash "$1" "$2" && return 0
    fail "$1 flash fail: not enough space" "Phone fastbootd mein hai. Option 13 ki tarah 'product' delete karke ya Format data ke baad dobara try karo. Phone ko aise hi mat chhodo - same option phir chalao."
    return 1
  fi
  fail "$1 flash fail" "Phone abhi fastbootd mein hai. Cable dobara laga ke same option phir chalao (beech mein phone restart mat karo)."; }

flash_payload(){ # [11] Path A: payload.bin -> fastboot + fastbootd (recovery ki zarurat nahi)
  local auto="$1" zip p
  echo -e "${C}== ROM ZIP flash BINA recovery (payload.bin) ==${N}"
  if [ -n "$auto" ]; then zip="$ZIP"; else pick_zip || { pause; return; }; zip="$ZIP"; fi
  zip_has "$zip" payload.bin || { fail "Is zip mein payload.bin nahi hai" "Ye method sirf A/B ROM zip (payload.bin wali) ke liye hai. Option 12 try karo."; pause; return; }
  need_pdg || { pause; return; }
  : > "$LOG"; log "Path A payload: $zip"
  local parts; parts=$(payload-dumper-go -l "$zip" 2>>"$LOG" | sed -n '/^Found partitions:/{n;p;}' | tr ',' '\n' | sed 's/^ *//; s/ (.*//' | grep -v '^$')
  [ -n "$parts" ] || { fail "payload.bin padh nahi paya" "ROM zip kharab ho sakti hai, dobara download karo."; pause; return; }
  local want; want=$(zip_device "$zip"); echo -e "${G}[+] ROM kis phone ke liye: ${C}${want:-metadata nahi}${N}"
  # space: payload ka ~2 guna (images unpack hoke badi hoti hain)
  local psz; psz=$(unzip -l "$zip" payload.bin | awk '$4=="payload.bin"{print $1}')
  mkdir -p "$WORK"; space_check "$WORK" $(( ${psz:-0} * 2 / 1024 )) || { pause; return; }
  goto_bootloader || { pause; return; }
  codename_gate "$want" "$FBPROD" || { pause; return; }
  local slot; slot=$(fb_slot); [ -n "$slot" ] || slot=a
  # classify
  local firm="" logi="" skip=""
  for p in $parts; do
    case "$p" in preloader*) skip="$skip $p"; continue;; esac
    if [[ "$LOGICAL_KNOWN" == *" $p "* ]] || [[ "$p" == my_* ]] || [ "$(fbv "is-logical:$p")" = "yes" ] || [ "$(fbv "is-logical:${p}_$slot")" = "yes" ]; then logi="$logi $p"; else firm="$firm $p"; fi
  done
  echo -e "${C}------------- PLAN -------------${N}"
  echo -e " Phone: ${C}$FBPROD${N}  current slot: ${C}_$slot${N}"
  echo -e " 1) Bootloader fastboot mein (dono slot):${G}$firm${N}"
  echo -e " 2) fastbootd mein (logical, slot _$slot):${G}$logi${N}"
  [ -n "$skip" ] && echo -e " ${Y}Skip (MTK preloader galat ho to hard brick - ye tool nahi chhedta):$skip${N}"
  local slotarg="--slot=all"
  if [ -z "$auto" ]; then
    echo -e " Boot partitions: ${G}[1]${N} dono slot (recommended)  ${G}[2]${N} sirf current slot _$slot"
    read -rp " Choose (1/2): " a; [ "$a" = "2" ] && slotarg=""
  fi
  ask_format
  echo -e " 3) Format data: $([ $FORMAT = 1 ] && echo "${R}HAAN${N}" || echo "nahi")   4) Reboot"
  echo -e "${C}--------------------------------${N}"
  flash_warn "Custom ROM (payload.bin): $(basename "$zip") -> $FBPROD" || { pause; return; }
  local out="$WORK/images"; rm -rf "$out"; mkdir -p "$out"
  echo -e "${Y}[*] Images nikal rahe hain (payload-dumper-go)... 5-20 min, phone ko charging pe rakho${N}"
  log "payload-dumper-go -o $out $zip"
  payload-dumper-go -o "$out" "$zip" 2>&1 | tee -a "$LOG" | tail -3
  [ "${PIPESTATUS[0]}" = "0" ] || { fail "Payload extract fail" "Jagah kam ho sakti hai ya zip kharab. Phone ko kuch nahi hua (abhi tak kuch flash nahi hua)."; pause; return; }
  for p in $firm $logi; do
    [ -s "$out/$p.img" ] || { fail "$p.img extract nahi hui" "Phone ko kuch nahi hua (abhi tak kuch flash nahi hua). Zip dobara download karo."; pause; return; }
    img_check "$p" "$out/$p.img" || { pause; return; }
  done
  echo -e "${G}[+] Sab images ready. Ab flash shuru - CABLE MAT CHHUNA!${N}"
  for p in $firm; do
    echo -e "${Y}[*] $p flash...${N}"
    fb $slotarg flash "$p" "$out/$p.img" || { fail "$p flash fail (bootloader stage)" "Phone abhi fastboot mein hai - use restart mat karo. Cable dobara laga ke same option phir chalao."; pause; return; }
  done
  echo -e "${Y}[*] fastbootd mein reboot (logical partitions ke liye)...${N}"
  fb reboot fastboot || { fail "reboot fastboot fail" "Phone fastboot mein hai. Same option phir chalao."; pause; return; }
  wait_mode fastbootd || { fail "Phone fastbootd mein nahi aaya" "Boot partitions flash ho chuki hain. Phone ki screen pe 'fastbootd' aaye to same option phir chalao; na aaye to Power+Vol Down se fastboot mein daal ke phir chalao."; pause; return; }
  fb snapshot-update cancel >/dev/null 2>&1; log "snapshot-update cancel (ignore result)"
  for p in $logi; do
    echo -e "${Y}[*] $p flash...${N}"
    flash_logical "$p" "$out/$p.img" "$slot" || { pause; return; }
  done
  if [ "$FORMAT" = 1 ]; then
    fb reboot bootloader || { fail "reboot bootloader fail (format ke liye)" "ROM flash ho chuka hai. Phone ko Power+Vol Down se fastboot mein daalo, phir Menu 13 nahi - bas 'termux-fastboot erase userdata' chalao."; pause; return; }
    wait_mode bootloader || { pause; return; }
    fmt_data_bootloader || { pause; return; }
  fi
  fb reboot || { fail "reboot fail" "ROM flash ho gaya hai, phone ko khud Power button se restart karo."; pause; return; }
  echo -e "${G}[+] ROM flash poora! Pehla boot 5-15 min le sakta hai, wait karo.${N}"
  read -rp "Extracted images ($out) delete karke jagah khali karein? (y/n): " a; [ "$a" = "y" ] && rm -rf "$out"
  pause; }

do_sideload(){ # $1 = zip. Phone recovery ke ADB sideload mode mein ho
  local n=0
  until [ "$(termux-adb get-state 2>/dev/null)" = "sideload" ]; do
    n=$((n+1)); [ $n -gt 60 ] && { fail "Sideload mode mein phone nahi mila" "Recovery mein 'Apply update > Apply from ADB' on karo, cable check karo, phir same option chalao."; return 1; }
    echo -ne "\r${Y}[*] Phone ka sideload mode mein wait... ($n)${N}"; sleep 2; done
  echo; echo -e "${Y}[*] Flash shuru... (47% ya 'Total xfer' pe atakna normal hai, cable mat nikalo)${N}"
  log "adb sideload $1"
  termux-adb sideload "$1" 2>&1 | tee -a "$LOG"; local rc=${PIPESTATUS[0]}
  [ "$rc" = "0" ] || { fail "Sideload error ke saath ruka (code $rc)" "Phone ki screen pe error padho. Phone recovery mein hai - wahi se dobara 'Apply from ADB' karke same option chalao."; return 1; }
  [ -n "$2" ] && { echo -e "${G}[+] Sideload poora: $(basename "$1")${N}"; return 0; }
  echo -e "${G}[+] Sideload poora! Phone ki screen pe result dekho, phir 'Reboot system now'.${N}"; }
rec_part_for(){ # file name -> partition
  local b; b=$(basename "$1" | tr 'A-Z' 'a-z')
  case "$b" in *vendor_boot*) echo vendor_boot;; *init_boot*) echo init_boot;; *dtbo*) echo dtbo;;
    *vbmeta_system*|*vbmeta_vendor*) echo "";; *vbmeta*) echo vbmeta;; *recovery*) echo recovery;; *boot*) echo boot;; *) echo "";; esac; }
find_rec_imgs(){ # $1 zip -> REC_SRC (zip|folder|""), REC_LIST lines "part|path"  (folder: zip ke bagal mein)
  local zip="$1" e p dir tok f; REC_SRC=""; REC_LIST=""
  for e in $(unzip -Z1 "$zip" 2>/dev/null | grep -iE '(^|/)(boot|vendor_boot|init_boot|dtbo|recovery|vbmeta)\.img$'); do
    p=$(rec_part_for "$e"); [ -n "$p" ] && REC_LIST="$REC_LIST$p|zip:$e"$'\n'
  done
  if echo "$REC_LIST" | grep -qE '^(vendor_boot|recovery)\|'; then REC_SRC=zip; return 0; fi
  REC_LIST=""
  dir=$(dirname "$zip"); tok=$(basename "$zip" | cut -d- -f1 | cut -d_ -f1 | tr 'A-Z' 'a-z')
  for f in "$dir"/*.img; do [ -f "$f" ] || continue
    b=$(basename "$f" | tr 'A-Z' 'a-z')
    case "$b" in boot.img|vendor_boot.img|init_boot.img|dtbo.img|recovery.img|vbmeta.img) ;; *"$tok"*) ;; *) continue;; esac
    p=$(rec_part_for "$f"); [ -n "$p" ] || continue
    echo "$REC_LIST" | grep -q "^$p|" && continue
    REC_LIST="$REC_LIST$p|$f"$'\n'
  done
  [ -n "$REC_LIST" ] && REC_SRC=folder
  # recovery tabhi maano jab vendor_boot ya recovery image ho (beryl pe recovery vendor_boot mein hoti hai); akela vbmeta/dtbo/boot recovery nahi hai
  echo "$REC_LIST" | grep -qE '^(vendor_boot|recovery)\|' || { REC_LIST=""; REC_SRC=""; }; return 0; }
flash_rom_recovery(){ # [12] Path B: ROM ki apni recovery images -> fastboot, phir sideload
  local auto="$1" zip line p f
  echo -e "${C}== ROM ki apni recovery + ADB sideload ==${N}"
  if [ -n "$auto" ]; then zip="$ZIP"; else pick_zip || { pause; return; }; zip="$ZIP"; find_rec_imgs "$zip"; fi
  : > "$LOG"; log "Path B: $zip"
  if [ -z "$REC_LIST" ]; then
    echo -e "${Y}[?] ROM zip ke andar ya uske bagal mein recovery images (boot/vendor_boot/dtbo) nahi mili.${N}"
    if zip_has "$zip" payload.bin; then
      read -rp "ROM ke payload.bin se boot/vendor_boot/dtbo/init_boot nikaal lein? (y/n): " a
      [ "$a" = "y" ] || { echo -e "${Y}[*] ROM ke download page se recovery images (boot.img, vendor_boot.img, dtbo.img) Download folder mein rakho, phir dobara.${N}"; pause; return; }
      need_pdg || { pause; return; }
      local pl; pl=$(payload-dumper-go -l "$zip" 2>/dev/null | sed -n '/^Found partitions:/{n;p;}' | tr ',' '\n' | sed 's/^ *//; s/ (.*//' | grep -xE 'boot|vendor_boot|init_boot|dtbo' | paste -sd, -)
      [ -n "$pl" ] || { fail "payload mein boot/vendor_boot nahi mile"; pause; return; }
      rm -rf "$WORK/rec"; mkdir -p "$WORK/rec"
      payload-dumper-go -p "$pl" -o "$WORK/rec" "$zip" 2>&1 | tee -a "$LOG" | tail -2
      [ "${PIPESTATUS[0]}" = "0" ] || { fail "Payload se images nahi nikli" "Jagah check karo, zip dobara download karo."; pause; return; }
      for p in $(echo "$pl" | tr ',' ' '); do REC_LIST="$REC_LIST$p|$WORK/rec/$p.img"$'\n'; done; REC_SRC=payload
    else
      echo -e "${Y}[*] ROM ke download page se recovery images Download folder mein rakho, phir dobara chalao.${N}"; pause; return
    fi
  fi
  # zip ke andar wali images bahar nikalo
  local list="" rd="$WORK/rec_zip"; rm -rf "$rd"; mkdir -p "$rd"
  space_check "$WORK" 1048576 || { pause; return; }
  while IFS='|' read -r p f; do [ -n "$p" ] || continue
    if [[ "$f" == zip:* ]]; then
      unzip -o -j "$zip" "${f#zip:}" -d "$rd" >>"$LOG" 2>&1 || { fail "Zip se $(basename "${f#zip:}") nahi nikli" "Jagah check karo."; pause; return; }
      f="$rd/$(basename "${f#zip:}")"
    fi
    if [ "$p" = "recovery" ] && [ "$(img_magic "$f")" = "564e4452424f4f54" ]; then p=vendor_boot; fi
    list="$list$p|$f"$'\n'
  done <<< "$REC_LIST"
  local want; want=$(zip_device "$zip"); echo -e "${G}[+] ROM kis phone ke liye: ${C}${want:-metadata nahi}${N}"
  goto_bootloader || { pause; return; }
  codename_gate "$want" "$FBPROD" || { pause; return; }
  while IFS='|' read -r p f; do [ -n "$p" ] || continue
    if [ "$p" = "recovery" ] && is_beryl "$FBPROD"; then fail "$(basename "$f") 'recovery' type hai, par beryl pe recovery partition nahi hota" "ROM ki vendor_boot.img use karo."; pause; return; fi
    img_check "$p" "$f" || { pause; return; }
  done <<< "$list"
  echo -e "${C}------------- PLAN -------------${N}"
  local slotarg=""; is_beryl "$FBPROD" && slotarg="--slot=all"
  echo -e " Images (${REC_SRC}) -> fastboot ($([ -n "$slotarg" ] && echo "dono slot" || echo "current slot")):"
  echo "$list" | while IFS='|' read -r p f; do [ -n "$p" ] && echo -e "   ${G}$p${N} <- $(basename "$f")"; done
  [ -n "$slotarg" ] && echo -e "   (beryl: dono slot a+b, --slot=all)"
  if is_beryl "$FBPROD" || echo "$list" | grep -q '^vendor_boot|'; then echo -e " Phir: normal reboot + Volume Up se recovery -> (Format data) -> ADB sideload $(basename "$zip")"
  else echo -e " Phir: reboot recovery -> (Format data) -> ADB sideload $(basename "$zip")"; fi
  is_beryl "$FBPROD" && echo -e "${Y} LunarisAOSP / LineageOS ho to option ${G}[14]${Y} better hai (firmware zip bhi daalta hai).${N}"
  echo -e "${C}--------------------------------${N}"
  flash_warn "ROM recovery images + sideload: $(basename "$zip") -> $FBPROD" || { pause; return; }
  while IFS='|' read -r p f; do [ -n "$p" ] || continue
    echo -e "${Y}[*] $p flash...${N}"
    fb $slotarg flash "$p" "$f" || { fail "$p flash fail" "Phone abhi fastboot mein hai - restart mat karo. Cable dobara laga ke same option phir chalao."; pause; return; }
  done <<< "$list"
  echo -e "${Y}[*] ROM ki recovery mein jaana hai...${N}"
  local rp=recovery; echo "$list" | grep -q '^vendor_boot|' && rp=vendor_boot
  reboot_to_recovery_safe "$rp" || echo -e "${Y}[>] Images flash ho gayi hain. Phone ko khud recovery mein daalo (Power + Vol Up), phir neeche wale steps.${N}"
  echo -e "${C}Ab target phone pe (ROM ki recovery mein):${N}"
  echo -e " 1. ${R}Clean flash / stock se aa rahe ho:${N} 'Factory reset' > 'Format data / factory reset' (SARA DATA DELETE)"
  echo -e " 2. 'Apply update' > 'Apply from ADB'"
  echo -e "${Y}[*] Termux:API popup / USB permission aaye to Allow karo${N}"
  read -rp "Phone pe 'Apply from ADB' on ho gaya? Enter dabao..." _
  do_sideload "$zip" || { pause; return; }
  echo -e "${Y}(Agar recovery 'reboot to recovery for add-ons?' puchhe aur GApps nahi chahiye to 'No'.)${N}"
  pause; }

make_empty_vbmeta(){ # $1 = output. AVB header, koi descriptor nahi, flags=2 (verification disabled) - 4096 bytes
  { printf 'AVB0\000\000\000\001\000\000\000\000'; head -c 108 /dev/zero
    printf '\000\000\000\002'; head -c 4 /dev/zero
    printf 'avbtool 1.2.0'; head -c 115 /dev/zero; head -c 3840 /dev/zero; } > "$1"; }
flash_gsi(){ # [13] Path C: GSI
  echo -e "${C}== GSI flash (system.img) ==${N}"
  echo -e "${Y}GSI = generic Android (arm64, A/B). Note 14 5G pe camera/NFC/kuch features shayad na chalein. Stock vendor same rehta hai.${N}"
  need_tools || { pause; return; }; need_storage || { pause; return; }
  pick_file "*.img*" || { pause; return; }; local src="$PICKED" sys
  : > "$LOG"; log "Path C GSI: $src"; mkdir -p "$WORK"
  case "$src" in
    *.xz) sys="$WORK/gsi_system.img"; space_check "$WORK" 6000000 || { pause; return; }
          echo -e "${Y}[*] .xz unpack ho raha hai...${N}"; xz -dc "$src" > "$sys" || { fail "xz unpack fail" "Setup [1] chalao (xz-utils), jagah check karo."; pause; return; };;
    *.gz) sys="$WORK/gsi_system.img"; space_check "$WORK" 6000000 || { pause; return; }
          gzip -dc "$src" > "$sys" || { fail "gz unpack fail"; pause; return; };;
    *.img) sys="$src";;
    *) fail "Ye .img / .img.xz file nahi hai"; pause; return;;
  esac
  local mg; mg=$(img_magic "$sys")
  if [ "${mg:0:8}" != "3aff26ed" ] && [ "$(od -An -tx1 -j1080 -N2 "$sys" | tr -d ' \n')" != "53ef" ] && [ "$(od -An -tx1 -j1024 -N4 "$sys" | tr -d ' \n')" != "e2e1f5e0" ]; then
    fail "Ye system image nahi lagti (ext4/erofs/sparse nahi)" "GSI ka system .img chuno."; pause; return
  fi
  echo -e "${C}vbmeta (verification band karna zaroori hai, warna GSI boot nahi hoga):${N}"
  echo -e " ${G}[1]${N} Stock vbmeta.img do (phone ke stock fastboot ROM ke 'images' folder se) - zyada safe"
  echo -e " ${G}[2]${N} Khali vbmeta bana do (tool khud banayega, verification band) - stock file na ho tab"
  read -rp " Choose (1/2): " v; local vb vbdir=""
  case $v in
    1) pick_file "vbmeta*.img" || { pause; return; }; vb="$PICKED"; vbdir=$(dirname "$vb"); img_check vbmeta "$vb" || { pause; return; };;
    2) vb="$WORK/vbmeta_empty.img"; make_empty_vbmeta "$vb"; echo -e "${G}[+] Khali vbmeta bana: $vb${N}";;
    *) echo "Cancel."; pause; return;;
  esac
  read -rp "Super mein jagah ke liye 'product' partition delete karein? (GSI bada ho to zaroori; y/n): " dp
  goto_bootloader || { pause; return; }
  read -rp "Ye GSI arm64 A/B hai aur '$FBPROD' ke Android version se match karta hai? (yes likho): " ok
  [ "$ok" = "yes" ] || { echo -e "${Y}[*] Cancel.${N}"; pause; return; }
  ask_format
  local slot; slot=$(fb_slot); [ -n "$slot" ] || slot=a
  echo -e "${C}------------- PLAN -------------${N}"
  echo -e " 1) vbmeta (--disable-verity --disable-verification) <- $(basename "$vb")"
  [ -n "$vbdir" ] && for x in vbmeta_system vbmeta_vendor; do [ -f "$vbdir/$x.img" ] && echo -e "    + $x <- $x.img"; done
  echo -e " 2) fastbootd: $([ "$dp" = "y" ] && echo "product_$slot DELETE, ")system <- $(basename "$sys")"
  echo -e " 3) Format data: $([ $FORMAT = 1 ] && echo "${R}HAAN${N}" || echo "nahi (GSI mein aksar zaroori hai)")   4) Reboot"
  echo -e "${C}--------------------------------${N}"
  flash_warn "GSI: $(basename "$sys") -> $FBPROD" || { pause; return; }
  fb --disable-verity --disable-verification flash vbmeta "$vb" || { fail "vbmeta flash fail" "Phone fastboot mein hai. Same option phir chalao."; pause; return; }
  if [ -n "$vbdir" ]; then for x in vbmeta_system vbmeta_vendor; do
    [ -f "$vbdir/$x.img" ] && { fb --disable-verity --disable-verification flash "$x" "$vbdir/$x.img" || { fail "$x flash fail" "Phone fastboot mein hai. Same option phir chalao."; pause; return; }; }
  done; fi
  fb reboot fastboot || { fail "reboot fastboot fail" "Phone fastboot mein hai. Same option phir chalao."; pause; return; }
  wait_mode fastbootd || { fail "Phone fastbootd mein nahi aaya" "Power+Vol Down se fastboot mein daal ke same option phir chalao."; pause; return; }
  fb snapshot-update cancel >/dev/null 2>&1
  if [ "$dp" = "y" ]; then fb delete-logical-partition "product_$slot" || { fail "product delete fail" "Phone fastbootd mein hai. Same option phir chalao (product delete ko 'n' karke)."; pause; return; }; fi
  echo -e "${Y}[*] system flash... (GSI bada hai, 5-10 min)${N}"
  flash_logical system "$sys" "$slot" || { pause; return; }
  if [ "$FORMAT" = 1 ]; then
    fb reboot bootloader || { fail "reboot bootloader fail"; pause; return; }
    wait_mode bootloader || { pause; return; }
    fmt_data_bootloader || { pause; return; }
  fi
  fb reboot || { fail "reboot fail" "GSI flash ho gaya, phone khud restart karo."; pause; return; }
  echo -e "${G}[+] GSI flash poora! Pehla boot lamba ho sakta hai. Bootloop ho to: fastboot mein jaake Format data karo, ya option 8 se stock ROM wapas.${N}"; pause; }

flash_lunaris(){ # [14] LunarisAOSP / LineageOS (beryl) - ROM ke official 9 steps, bina 'fastboot reboot recovery'
  echo -e "${C}== Lunaris / LineageOS (Redmi Note 14 5G beryl) - official steps ==${N}"
  need_tools || { pause; return; }; need_storage || { pause; return; }
  echo -e "${R}=====================================================${N}"
  echo -e "${R}[!] Sirf HyperOS 3 se flash karo (ROM ke official notes). Purane HyperOS/MIUI se = bootloop/brick ka risk.${N}"
  echo -e "${R}[!] beryl pe 'fastboot reboot recovery' KABHI nahi - tool sirf normal reboot karega, tum Volume Up se recovery khologe.${N}"
  echo -e "${R}=====================================================${N}"
  read -rp "Target phone abhi HyperOS 3 pe hai? (yes likho): " a
  [ "$a" = "yes" ] || { echo -e "${Y}[*] Cancel. Pehle phone ko HyperOS 3 pe update karo, phir aao.${N}"; pause; return; }
  echo -e "${C}Step A: vendor_boot.img chuno (ROM ke download page wali)${N}"
  pick_file "*vendor_boot*.img" || { pause; return; }; local vb="$PICKED"
  echo -e "${C}Step B: firmware zip chuno (fw_beryl_global_xxxx.zip)${N}"
  pick_file "fw_*.zip" || { pause; return; }; local fw="$PICKED"
  echo -e "${C}Step C: ROM zip chuno (LunarisAOSP / LineageOS)${N}"
  pick_file "*.zip" || { pause; return; }; local rom="$PICKED"
  local gapps=""
  read -rp "GApps (MindTheGapps) bhi daalna hai? (y/n): " a
  if [ "$a" = "y" ]; then echo -e "${C}Step D: GApps zip chuno${N}"; pick_file "*[Gg]app*.zip" || { pause; return; }; gapps="$PICKED"; fi
  # --- file checks (abhi tak phone ko kuch nahi hua) ---
  : > "$LOG"; log "Lunaris mode: vb=$vb fw=$fw rom=$rom gapps=$gapps"
  local f; for f in "$vb" "$fw" "$rom" $gapps; do
    [ -r "$f" ] && [ -s "$f" ] || { fail "$(basename "$f") khali hai ya padh nahi pa rahe" "File dobara download karo (Download folder mein). Phone ko kuch nahi hua."; pause; return; }
  done
  img_check vendor_boot "$vb" || { pause; return; }
  [ "$rom" != "$fw" ] && [ "$rom" != "$gapps" ] || { fail "ROM zip aur firmware/GApps zip same file chun li" "Step C mein ROM wali zip (Lunaris/Lineage) chuno."; pause; return; }
  case "$(basename "$rom")" in fw_*) fail "ROM ki jagah firmware zip chun li" "Step C mein ROM zip chuno, fw_ wali nahi."; pause; return;; esac
  for f in "$fw" "$rom" $gapps; do
    unzip -l "$f" >/dev/null 2>&1 || { fail "$(basename "$f") valid zip nahi hai (adhoori download?)" "Dobara download karo. Phone ko kuch nahi hua."; pause; return; }
  done
  zip_has "$rom" payload.bin || zip_has "$rom" META-INF/com/google/android/update-binary || { fail "$(basename "$rom") ROM zip nahi lagti (payload.bin / update-binary nahi)" "Sahi ROM zip download karo."; pause; return; }
  local want; want=$(zip_device "$rom")
  # --- phone: fastboot + unlocked + codename ---
  goto_bootloader || { pause; return; }
  case "$FBPROD" in beryl*|citrine*) ;; *) fail "Ye mode sirf Redmi Note 14 5G (beryl/citrine) ke liye hai, phone '$FBPROD' hai" "Is phone ke liye uske apne ROM ke steps follow karo."; pause; return;; esac
  codename_gate "$want" "$FBPROD" || { pause; return; }
  local fwn; fwn=$(basename "$fw" | tr 'A-Z' 'a-z')
  if [[ "$fwn" == *beryl* || "$fwn" == *citrine* ]]; then
    [[ "$fwn" == *"${FBPROD%%_*}"* ]] || { fail "Firmware '$(basename "$fw")' dusre codename ka hai, phone '$FBPROD' hai" "Phone ke codename wali fw_${FBPROD%%_*}_... zip lo."; pause; return; }
  else
    echo -e "${Y}[?] Firmware zip ke naam mein beryl/citrine nahi likha.${N}"
    read -rp "Pakka ye '$FBPROD' ka firmware hai? (yes likho): " a; [ "$a" = "yes" ] || { echo -e "${Y}[*] Cancel.${N}"; pause; return; }
  fi
  echo -e "${C}------------- PLAN (ROM ke official steps) -------------${N}"
  echo -e " 1) fastboot flash vendor_boot ${G}--slot=all${N} <- $(basename "$vb")"
  echo -e " 2) fastboot reboot  ${R}(reboot recovery NAHI)${N}"
  echo -e " 3) Reboot hote hi tum ${Y}Volume Up${N} daba ke rakhoge -> recovery"
  echo -e " 4) Recovery mein ${R}Format Data${N} (SARA DATA DELETE)"
  echo -e " 5) adb sideload ${G}$(basename "$fw")${N} (firmware)"
  echo -e " 6) adb sideload ${G}$(basename "$rom")${N} (ROM)"
  echo -e " 7) Recovery 'reboot to recovery?' puchhe to ${G}Yes${N}"
  echo -e " 8) GApps: $([ -n "$gapps" ] && echo "${G}$(basename "$gapps")${N}" || echo "nahi")"
  echo -e " 9) Reboot system"
  echo -e "${C}--------------------------------------------------------${N}"
  flash_warn "LunarisAOSP/LineageOS: $(basename "$rom") -> $FBPROD" || { pause; return; }
  echo -e "${R}[!] Step 4 mein Format Data se phone ka SARA DATA (photos, apps, sab) DELETE hoga.${N}"
  read -rp "Samajh gaye? Aage badhne ke liye FORMAT likho: " a
  [ "$a" = "FORMAT" ] || { echo -e "${Y}[*] Cancel. Phone ko kuch nahi hua.${N}"; pause; return; }
  # 1) vendor_boot dono slot
  echo -e "${Y}[1/9] vendor_boot flash (dono slot)...${N}"
  fb --slot=all flash vendor_boot "$vb" || { fail "vendor_boot flash fail" "Phone abhi fastboot mein hai - restart mat karo. Cable dobara laga ke option 14 phir chalao."; pause; return; }
  # 2-3) normal reboot + Vol Up
  echo -e "${Y}[2/9] Normal reboot (fastboot reboot)...${N}"
  volup_box
  read -rp "Target phone pe Volume Up pakad lo, phir Enter dabao (reboot bhejenge)..." _
  fb reboot || { fail "reboot fail" "vendor_boot flash ho chuka hai. Phone ko Power button se restart karo aur turant Volume Up daba ke rakho, phir 'recovery' wale steps khud karo."; pause; return; }
  [ -n "$TEST" ] && fake_state recovery
  echo -e "${Y}[3/9] VOLUME UP dabaye rakho jab tak recovery na dikhe!${N}"
  read -rp "Recovery khul gayi? Enter dabao..." _
  # 4) Format data
  echo -e "${C}[4/9] Recovery mein: 'Factory reset' > 'Format data / factory reset' > confirm${N}"
  read -rp "Format data ho gaya? 'done' likho: " a
  [ "$a" = "done" ] || { fail "Format data confirm nahi hua" "Recovery mein Format Data karke option 14 phir chalao (vendor_boot dobara flash karna safe hai)."; pause; return; }
  # 5) firmware
  lun_sideload 5 "firmware" "$fw" || { pause; return; }
  # 6) ROM
  lun_sideload 6 "ROM" "$rom" || { pause; return; }
  # 7) reboot to recovery prompt (recovery khud puchhti hai - ye safe hai, fastboot command nahi)
  echo -e "${C}[7/9] Recovery 'Reboot to recovery?' / 'install add-ons ke liye reboot?' puchhe to: ${G}Yes${N}"
  if [ -n "$gapps" ]; then
    read -rp "Recovery dobara khul gayi? Enter dabao..." _
    lun_sideload 8 "GApps" "$gapps" || { pause; return; }
  else echo -e "${Y}[8/9] GApps skip.${N}"; fi
  echo -e "${C}[9/9] Recovery mein: 'Reboot system now'${N}"
  echo -e "${G}[+] Sab steps poore! Pehla boot 5-15 min le sakta hai, wait karo.${N}"; log "Lunaris mode done"; pause; }
lun_sideload(){ # $1 step no, $2 naam, $3 zip. Har sideload se pehle 'Apply from ADB', fail pe ruk jao
  echo -e "${C}[$1/9] $2 sideload: recovery mein 'Apply update' > 'Apply from ADB' chuno${N}"
  read -rp "Phone pe 'Apply from ADB' on ho gaya? Enter dabao..." _
  do_sideload "$3" quiet && return 0
  echo -e "${Y}[?] adb ne error diya. Kabhi kabhi '47%' / 'failed to read command: Success' pe bhi install ho jata hai.${N}"
  read -rp "Phone ki screen pe 'Install completed with status 0' / success dikh raha hai? (haan likho, warna Enter = ruko): " a
  [ "$a" = "haan" ] && { log "sideload $2: adb rc!=0 par user ne screen pe success confirm kiya"; return 0; }
  fail "$2 sideload fail" "Phone recovery mein hi rehne do. Cable check karke option 14 dobara chalao (ya recovery se 'Apply from ADB' karke tool ka option 7 se sirf ye zip)."; return 1; }

auto_flash(){ # [10] AUTO: ROM zip dekh ke khud raasta chunta hai
  echo -e "${C}== AUTO Custom ROM Flash (Redmi Note 14 5G / beryl) ==${N}"
  pick_zip || { pause; return; }
  echo -e "${Y}[*] ROM zip check ho rahi hai...${N}"
  find_rec_imgs "$ZIP"
  echo -e "${C}------------- AUTO ka faisla -------------${N}"
  if [ -n "$REC_LIST" ]; then
    echo -e "${G}[+] Raasta: ROM ki apni recovery + sideload (option 12 jaisa)${N}"
    if [ "$REC_SRC" = zip ]; then echo -e "    Kyun: ROM zip ke andar hi recovery images mili:"; else echo -e "    Kyun: ROM zip ke bagal mein (Download folder) uski recovery images mili:"; fi
    echo "$REC_LIST" | while IFS='|' read -r p f; do [ -n "$p" ] || continue
      if [[ "$f" == zip:* ]]; then echo -e "      $p <- ${f#zip:} (zip ke andar)"; else echo -e "      $p <- $(basename "$f") ($(date -r "$f" '+%d %b %Y' 2>/dev/null))"; fi; done
    echo -e "    ROM ki apni recovery se install = ROM developer ka official tarika."
    echo -e "${Y}    LunarisAOSP / LineageOS (beryl) hai? Unke steps mein firmware zip bhi hai - option ${G}[14]${Y} use karo (agle 'yes' pe kuch aur likh ke cancel karo, phir menu se 14).${N}"
    [ "$REC_SRC" = folder ] && echo -e "${Y}    Dhyan: ye images ISI ROM build ki honi chahiye. Purani/dusre ROM ki .img Download se hata do, warna 'yes' mat likhna.${N}"
    flash_rom_recovery auto; return
  fi
  if zip_has "$ZIP" payload.bin; then
    echo -e "${G}[+] Raasta: payload.bin method (option 11 jaisa) - recovery ki zarurat nahi${N}"
    echo -e "    Kyun: recovery images nahi mili, par zip mein payload.bin hai. Tool images nikal ke fastboot/fastbootd se flash karega."
    flash_payload auto; return
  fi
  if zip_has "$ZIP" META-INF/com/google/android/update-binary; then
    fail "Ye purane type ki recovery-only ZIP hai (payload.bin nahi) aur recovery images bhi nahi mili" "Beryl pe TWRP/OrangeFox nahi hai. ROM ke page se uski recovery (boot.img/vendor_boot.img) Download folder mein rakho, phir AUTO dobara chalao."
  else
    fail "Ye ROM zip nahi lagti (payload.bin / update-binary kuch nahi mila)" "Xiaomi stock .tgz ke liye option 8, GSI .img ke liye option 13."
  fi; pause; }

help_(){ echo -e "${C}Unlock steps:${N}
1. Target phone: Settings > About phone > OS version pe 7 baar tap (Developer options)
2. Developer options > OEM unlocking ON + Mi Unlock status > Add account
3. HyperOS pe Xiaomi Community app se unlock permission apply karni padti hai (Xiaomi ka rule)
4. Xiaomi ka wait time (aksar kuch din) poora hone do
5. Is phone pe: Menu 1 (Setup) -> phone ko fastboot mein OTG se lagao -> Menu 2 -> Menu 3
${C}ROM flash steps:${N}
- Apne phone ka codename pata karo (target phone pe: getprop ro.product.device)
- Sirf usi codename ka ROM / recovery download karo (/sdcard/Download mein rakho)
- Custom ROM zip: pehle Menu 9 se recovery daalo, phir Menu 7
${C}Redmi Note 14 5G (beryl) - TWRP/OrangeFox nahi hai:${N}
- [10] AUTO: ROM zip chuno, tool khud raasta chunega (ROM ki recovery mili to 12, warna payload.bin se 11)
- [11] payload.bin: images nikaal ke fastboot + fastbootd se flash (recovery nahi chahiye)
- [12] ROM ki apni recovery (boot/vendor_boot/dtbo) flash karke ZIP sideload
- [13] GSI: vbmeta disable + system.img flash
- [14] LunarisAOSP / LineageOS: ROM ke official steps (vendor_boot dono slot -> normal reboot + Vol Up -> Format data -> firmware zip -> ROM zip -> GApps)
- beryl pe 'fastboot reboot recovery' KABHI mat chalao (brick ho sakta hai). Reboot ke baad Volume Up daba ke recovery kholo.
- Lunaris/LineageOS sirf HyperOS 3 se flash karo
- Har flash ka log: ~/prateek_flash.log
- Xiaomi stock fastboot ROM (.tgz): Menu 8
- Phone ko fastboot/recovery mein daalna aur cable lagana aapko khud karna hai
Note: Same phone khud ko unlock/flash nahi kar sakta, 2 phone chahiye."; pause; }

# ================= TEST MODE (JARVIS TEST): nakli phone, kuch flash nahi hota =================
fake_state(){ echo "$1" > "$TD/.state"; }
fake_get(){ cat "$TD/.state" 2>/dev/null || echo bootloader; }
fake_flashfail(){ # Fake error ON ho to 2nd flash fail karo (taaki dikhe ki tool beech mein rukta hai)
  [ -n "$FAKE_ERR" ] || return 1
  local n; n=$(( $(cat "$TD/.flashcount" 2>/dev/null || echo 0) + 1 )); echo $n > "$TD/.flashcount"
  [ $n -ge 2 ]; }
if [ -n "$TEST" ]; then
termux-fastboot(){
  echo "fastboot $*" >> "$TD/.fbcalls" # TEST: har nakli fastboot command ka log (reboot recovery check ke liye)
  local st; st=$(fake_get)
  while [[ "$1" == --* ]]; do shift; done
  if [ "$st" != bootloader ] && [ "$st" != fastbootd ]; then echo "< waiting for any device >" >&2; sleep 0.3; return 1; fi
  case "$1" in
    devices) echo -e "TEST1234beryl\tfastboot";;
    getvar) local v="$2" val
      case "$v" in
        product) val=beryl;; unlocked) val=yes;; current-slot) val=a;; slot-count) val=2;;
        is-userspace) [ "$st" = fastbootd ] && val=yes || val=no;;
        is-logical:*) case "${v#is-logical:}" in system*|vendor*|product*|odm*|mi_ext*) case "${v#is-logical:}" in vendor_boot*) val=no;; *) val=yes;; esac;; *) val=no;; esac;;
        super-partition-name) val=super;; max-download-size) val=0x10000000;;
        all) echo "(bootloader) product:beryl" >&2; echo "(bootloader) unlocked:yes" >&2; echo "(bootloader) current-slot:a" >&2; return 0;;
        *) val="";;
      esac
      echo "$v: $val" >&2; echo "Finished. Total time: 0.002s" >&2;;
    flash) sleep 0.4; echo "[TEST] Sending '$2' ($(( ($(stat -c %s "$3" 2>/dev/null || echo 4096) + 1023) / 1024 )) KB)   OKAY [  0.31s]" >&2
      if fake_flashfail; then echo "[TEST] Writing '$2'   FAILED (remote: 'Fake error - TEST MODE')" >&2; echo "fastboot: error: Command failed" >&2; return 1; fi
      sleep 0.3; echo "[TEST] Writing '$2'   OKAY [  0.12s]" >&2; echo "Finished. Total time: 0.5s" >&2;;
    erase|delete-logical-partition|create-logical-partition|resize-logical-partition|set_active|snapshot-update|oem)
      sleep 0.2; echo "[TEST] $1 ${2:-} OKAY [  0.05s]" >&2;;
    boot) sleep 0.4; echo "[TEST] Sending 'boot.img' OKAY / Booting OKAY" >&2;;
    reboot) sleep 0.3
      case "$2" in fastboot) fake_state fastbootd;; bootloader) fake_state bootloader;; recovery) fake_state recovery;; *) fake_state system;; esac
      echo "[TEST] Rebooting${2:+ into $2}   OKAY" >&2;;
    reboot-bootloader) fake_state bootloader; echo "[TEST] Rebooting into bootloader OKAY" >&2;;
    --version|-h|help) echo "fastboot version TEST";;
    *) sleep 0.2; echo "[TEST] $* OKAY" >&2;;
  esac; return 0; }
termux-adb(){
  echo "adb $*" >> "$TD/.fbcalls"
  case "$1" in
    get-state) case "$(fake_get)" in recovery) echo sideload;; system) echo device;; *) echo unknown; return 1;; esac;;
    shell) echo beryl;;
    devices) echo -e "List of devices attached\nTEST1234beryl\tsideload";;
    sideload) local i; for i in 10 30 47 70 100; do sleep 0.4; echo "[TEST] serving: '$(basename "$2")'  (~$i%)"; done
      if [ -n "$FAKE_ERR" ]; then echo "[TEST] adb: failed to read command: Success (fake error)"; return 1; fi
      echo "[TEST] Total xfer: 1.00x"; fake_state recovery;; # asli phone sideload ke baad recovery mein hi rehta hai
    reboot) fake_state "${2:-system}"; echo "[TEST] reboot OKAY";;
    *) echo "[TEST] adb $* OKAY";;
  esac; return 0; }
payload-dumper-go(){
  local out="" parts="" list="" zip=""
  while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift;; -p) parts="$2"; shift;; -l) list=1;; -h|--help|-version) echo "payload-dumper-go TEST"; return 0;; *) zip="$1";; esac; shift; done
  local all="boot,dtbo,vbmeta,vbmeta_system,vendor_boot,system,system_ext,product,vendor,odm"
  if [ -n "$list" ]; then echo "Please wait while extracting payload.bin from the archive."; echo "Found partitions:"
    echo "boot (100 MB), dtbo (8.4 MB), vbmeta (8.2 kB), vbmeta_system (4.1 kB), vendor_boot (100 MB), system (1.2 GB), system_ext (420 MB), product (1.9 GB), vendor (1.1 GB), odm (2 MB)"; return 0; fi
  [ -n "$out" ] || out="extracted_TEST"; mkdir -p "$out" || return 1
  [ -n "$parts" ] || parts="$all"
  local p
  for p in $(echo "$parts" | tr ',' ' '); do
    sleep 0.25
    case "$p" in
      boot|init_boot|recovery) printf 'ANDROID!' > "$out/$p.img";;
      vendor_boot) printf 'VNDRBOOT' > "$out/$p.img";;
      vbmeta*) printf 'AVB0' > "$out/$p.img";;
      dtbo) printf '\xd7\xb7\xab\x1e' > "$out/$p.img";;
      *) head -c 1024 /dev/zero > "$out/$p.img"; printf '\x53\xef' | dd of="$out/$p.img" bs=1 seek=1080 conv=notrunc 2>/dev/null;;
    esac
    head -c 2048 /dev/zero >> "$out/$p.img"
    echo "[TEST] $p.img  100% |########################|"
  done; return 0; }
miunlock(){ echo -e "${Y}[TEST] Mi account login (nakli)...${N}"; sleep 0.6; echo "[TEST] Account: 1234567890 (demo)"; sleep 0.4
  echo "[TEST] Phone: beryl (fastboot)"; sleep 0.4
  if [ -n "$FAKE_ERR" ]; then echo -e "${R}[TEST] Xiaomi: 'Please unlock 168 hours later' (fake error)${N}"; return 1; fi
  echo "[TEST] Unlock token mila"; sleep 0.4; echo -e "${G}[TEST] Unlock OKAY (asli mein phone ka data delete hota)${N}"; return 0; }
termux-setup-storage(){ echo "[TEST] storage OK"; }
make_test_files(){ # dummy ROMs: ek payload.bin wala, ek recovery images wala
  mkdir -p "$TD" || return 1; fake_state bootloader; : > "$TD/.fbcalls"
  base64 -d > "$TD/TEST-payload-rom-beryl.zip" <<'B64'
UEsDBBQAAAAIAGu5Xl1h3L3mVAAAAFwAAAAdAAAATUVUQS1JTkYvY29tL2FuZHJvaWQvbWV0YWRhdGHLL0nULaksSLV1dOIqyC8u0U0qzcxJsQ1xDQ7Rz0osKsssjk9KLarM0QeTVoam+mApQ6vS4tQi/aLUnNTE4lTd7NTKYq6ColTdlNSyzORUW7BiLgBQSwMEFAAAAAgAa7leXYX/ZBgVAAAAEwAAACkAAABNRVRBLUlORi9jb20vZ29vZ2xlL2FuZHJvaWQvdXBkYXRlLWJpbmFyeVNW1C9OyszTL87gUlZIKc3NreQCAFBLAwQUAAAACABruV5dQJlaRxsAAAAAEAAACwAAAHBheWxvYWQuYmlu7cFBDQAACAQgqzkzXBH7P+zhgNlOAQAAAK8dUEsDBBQAAAAIAGu5Xl1wzgDVEQAAAA8AAAAWAAAAcGF5bG9hZF9wcm9wZXJ0aWVzLnR4dHPz9HGN93AM9rANcQ0O4QIAUEsBAhQDFAAAAAgAa7leXWHcveZUAAAAXAAAAB0AAAAAAAAAAAAAAIABAAAAAE1FVEEtSU5GL2NvbS9hbmRyb2lkL21ldGFkYXRhUEsBAhQDFAAAAAgAa7leXYX/ZBgVAAAAEwAAACkAAAAAAAAAAAAAAIABjwAAAE1FVEEtSU5GL2NvbS9nb29nbGUvYW5kcm9pZC91cGRhdGUtYmluYXJ5UEsBAhQDFAAAAAgAa7leXUCZWkcbAAAAABAAAAsAAAAAAAAAAAAAAIAB6wAAAHBheWxvYWQuYmluUEsBAhQDFAAAAAgAa7leXXDOANURAAAADwAAABYAAAAAAAAAAAAAAIABLwEAAHBheWxvYWRfcHJvcGVydGllcy50eHRQSwUGAAAAAAQABAAfAQAAdAEAAAAA
B64
  base64 -d > "$TD/TEST-recovery-rom-beryl.zip" <<'B64'
UEsDBBQAAAAIAGu5Xl1h3L3mVAAAAFwAAAAdAAAATUVUQS1JTkYvY29tL2FuZHJvaWQvbWV0YWRhdGHLL0nULaksSLV1dOIqyC8u0U0qzcxJsQ1xDQ7Rz0osKsssjk9KLarM0QeTVoam+mApQ6vS4tQi/aLUnNTE4lTd7NTKYq6ColTdlNSyzORUW7BiLgBQSwMEFAAAAAgAa7leXYX/ZBgVAAAAEwAAACkAAABNRVRBLUlORi9jb20vZ29vZ2xlL2FuZHJvaWQvdXBkYXRlLWJpbmFyeVNW1C9OyszTL87gUlZIKc3NreQCAFBLAwQUAAAACABruV5dQJlaRxsAAAAAEAAACwAAAHBheWxvYWQuYmlu7cFBDQAACAQgqzkzXBH7P+zhgNlOAQAAAK8dUEsDBBQAAAAIAGu5Xl3rtXYlIQAAAAAQAAAIAAAAYm9vdC5pbWftwbEJADAIADBf6SmCS5cK/n9M/5Ak+Wr61gkAAABgrQ9QSwMEFAAAAAgAa7leXaHxoAgfAAAAABAAAA8AAAB2ZW5kb3JfYm9vdC5pbWftwbEJADAIADBvK84Kpfj/Kf1DkkzlPd0vAAAAgLU+UEsDBBQAAAAIAGu5Xl0ne3qjHAAAAAAQAAAIAAAAZHRiby5pbWftwQENAAAIAyCT2H8zwKNYxx4O2EwXAAAA8NoBUEsBAhQDFAAAAAgAa7leXWHcveZUAAAAXAAAAB0AAAAAAAAAAAAAAIABAAAAAE1FVEEtSU5GL2NvbS9hbmRyb2lkL21ldGFkYXRhUEsBAhQDFAAAAAgAa7leXYX/ZBgVAAAAEwAAACkAAAAAAAAAAAAAAIABjwAAAE1FVEEtSU5GL2NvbS9nb29nbGUvYW5kcm9pZC91cGRhdGUtYmluYXJ5UEsBAhQDFAAAAAgAa7leXUCZWkcbAAAAABAAAAsAAAAAAAAAAAAAAIAB6wAAAHBheWxvYWQuYmluUEsBAhQDFAAAAAgAa7leXeu1diUhAAAAABAAAAgAAAAAAAAAAAAAAIABLwEAAGJvb3QuaW1nUEsBAhQDFAAAAAgAa7leXaHxoAgfAAAAABAAAA8AAAAAAAAAAAAAAIABdgEAAHZlbmRvcl9ib290LmltZ1BLAQIUAxQAAAAIAGu5Xl0ne3qjHAAAAAAQAAAIAAAAAAAAAAAAAACAAcIBAABkdGJvLmltZ1BLBQYAAAAABgAGAIQBAAAEAgAAAAA=
B64
  head -c 4096 /dev/zero > "$TD/TEST-gsi-system.img"; printf '\x53\xef' | dd of="$TD/TEST-gsi-system.img" bs=1 seek=1080 conv=notrunc 2>/dev/null
  rm -f "$TD/TEST-gsi-system.img.xz" 2>/dev/null
  rm -f "$TD/TEST-boot.img"
  # Lunaris mode [14] ke dummy: vendor_boot + firmware + ROM + GApps
  { printf 'VNDRBOOT'; head -c 4088 /dev/zero; } > "$TD/beryl-lunaris-vendor_boot.img"
  cp -f "$TD/TEST-recovery-rom-beryl.zip" "$TD/fw_beryl_global_TEST.zip"
  cp -f "$TD/TEST-payload-rom-beryl.zip" "$TD/LunarisAOSP-3.12-beryl-TEST.zip"
  cp -f "$TD/TEST-payload-rom-beryl.zip" "$TD/MindTheGapps-16-arm64-TEST.zip"
  echo -e "${G}[TEST] Dummy files ready: ~/jarvis-test/${N}"
  echo -e "  ${C}TEST-payload-rom-beryl.zip${N}  -> AUTO payload.bin (11) chunega"
  echo -e "  ${C}TEST-recovery-rom-beryl.zip${N} -> AUTO ROM ki recovery (12) chunega"
  echo -e "  ${C}TEST-gsi-system.img${N}         -> GSI (13)"
  echo -e "  ${C}beryl-lunaris-vendor_boot.img + fw_beryl_global_TEST.zip + LunarisAOSP-3.12-beryl-TEST.zip + MindTheGapps${N} -> Lunaris (14)"; }
fi

# ================= Iron Man / J.A.R.V.I.S intro =================
JSND_URL1="https://prateek-tools.sites.tab.bot/jarvis.mp3"
JSND_URL2="https://raw.githubusercontent.com/MahaRajaPrateek/prateek-unlocker/main/jarvis.mp3"
jarvis_sound(){ # background mein, kabhi block nahi karta, fail ho to chup
  ( f="$HOME/.jarvis/jarvis.mp3"; mkdir -p "$HOME/.jarvis"
    if [ ! -s "$f" ]; then
      for u in "$JSND_URL1" "$JSND_URL2"; do
        curl -fsL --max-time 15 "$u" -o "$f.tmp" 2>/dev/null && [ -s "$f.tmp" ] && mv "$f.tmp" "$f" && break
      done; rm -f "$f.tmp"
    fi
    [ -s "$f" ] || exit 0
    if command -v termux-media-player >/dev/null && timeout 8 termux-media-player play "$f" 2>&1 | grep -qi "playing"; then exit 0; fi
    if command -v play-audio >/dev/null; then play-audio "$f"; exit 0; fi
    command -v mpv >/dev/null && mpv --really-quiet --no-video "$f"
  ) >/dev/null 2>&1 </dev/null & disown 2>/dev/null; }
J_SKIP=""
jwait(){ # $1 = seconds. Koi bhi key dabao to intro skip
  [ -n "$J_SKIP" ] && return 0
  if [ -t 0 ]; then read -rsn1 -t "$1" _ && J_SKIP=1; else sleep "$1"; fi; return 0; }
jarvis_intro(){
  [ -n "$FAST" ] && return 0
  jarvis_sound; clear; J_SKIP=""
  local Rd='\033[1;31m' Yl='\033[1;33m' Cy='\033[1;36m' l
  local helm=(
"${Rd}         .-=========-.          "
"${Rd}       .'  ${Yl}_________${Rd}  '.        "
"${Rd}      /  ${Yl}.'         '.${Rd}  \\\\       "
"${Rd}     |  ${Yl}/             \\\\${Rd}  |      "
"${Rd}     |  ${Yl}|  ${Cy}<===>${Yl} ${Cy}<===>${Yl}|${Rd}  |      "
"${Rd}     |  ${Yl}|      |      |${Rd}  |      "
"${Rd}     |  ${Yl} \\\\     |     /${Rd}   |      "
"${Rd}      \\\\  ${Yl} '.  ---  .'${Rd}   /       "
"${Rd}       '.  ${Yl}'-.___.-'${Rd} .'        "
"${Rd}         '-.._____..-'          "
"${Yl}            MARK  85            ")
  for l in "${helm[@]}"; do echo -e "$l${N}"; jwait 0.18; done
  echo
  local hud=("Initializing J.A.R.V.I.S..." "Loading flash protocols..." "Scanning USB / OTG ports...")
  for l in "${hud[@]}"; do echo -e "${Cy}[>] $l${N}"; jwait 0.3; done
  local i bar
  for i in $(seq 1 20); do
    bar=$(printf '%*s' "$i" '' | tr ' ' '#')$(printf '%*s' $((20-i)) '' | tr ' ' '-')
    printf "\r${Yl}[%s] %3d%%${N}" "$bar" $((i*5)); jwait 0.06
  done; echo
  echo -e "${G}[+] Suit systems: ONLINE${N}"; jwait 0.3
  echo -e "${G}[+] Arc reactor: 100%${N}"; jwait 0.3
  [ -n "$TEST" ] && { echo -e "${Yl}[!] TEST MODE: phone link SIMULATED${N}"; jwait 0.3; }
  echo; echo -e "${Rd}========================================${N}"
  echo -e "${Yl}       >>> J.A.R.V.I.S ACTIVATED <<<${N}"
  echo -e "${Rd}========================================${N}"; jwait 1
  J_SKIP=""; }
jarvis_intro
[ -n "$TEST" ] && { make_test_files || echo -e "${R}[-] Test files nahi bane (jagah?)${N}"; sleep 2; }
while true; do banner
[ -n "$TEST" ] && echo 0 > "$TD/.flashcount"
echo -e " ${G}[1]${N} Setup (pehli baar)"
echo -e " ${G}[2]${N} Device check (fastboot)"
echo -e " ${G}[3]${N} Bootloader UNLOCK"
echo -e " ${G}[4]${N} Unlock status check"
echo -e " ${G}[5]${N} Reboot phone"
echo -e " ${G}[6]${N} Help / Steps"
echo -e " ${C}---- ROM FLASHER ----${N}"
echo -e " ${G}[7]${N} Flash ROM (Recovery ZIP)"
echo -e " ${G}[8]${N} Flash Fastboot ROM (Xiaomi .tgz)"
echo -e " ${G}[9]${N} Flash recovery/boot image"
echo -e " ${C}---- Note 14 5G (beryl): recovery ke bina ----${N}"
echo -e " ${G}[10]${N} AUTO Custom ROM Flash (Note 14 5G)"
echo -e " ${G}[11]${N} ROM ZIP flash bina recovery (payload.bin)"
echo -e " ${G}[12]${N} ROM ki apni recovery + sideload"
echo -e " ${G}[13]${N} GSI flash (system.img)"
echo -e " ${G}[14]${N} Lunaris / LineageOS (beryl) - official steps"
[ -n "$TEST" ] && echo -e " ${Y}[E]${N} Fake error: $([ -n "$FAKE_ERR" ] && echo "${R}ON${N} (OFF karne ke liye E)" || echo "${G}OFF${N} (ON karne ke liye E)")"
echo -e " ${R}[0]${N} Exit"
read -rp $'\n Choose: ' c
if [ -n "$TEST" ] && [ "${c,,}" = "e" ]; then [ -n "$FAKE_ERR" ] && FAKE_ERR="" || FAKE_ERR=1; continue; fi
case $c in 1) setup;; 2) check;; 3) unlock;; 4) lockcheck;; 5) reboot_;; 6) help_;; 7) flash_zip;; 8) flash_fastboot_rom;; 9) flash_img;; 10) auto_flash;; 11) flash_payload;; 12) flash_rom_recovery;; 13) flash_gsi;; 14) flash_lunaris;; 0) exit 0;; *) ;; esac
done

#!/data/data/com.termux/files/usr/bin/bash
# Prateek Unlocker v2.0 - Xiaomi/Redmi/POCO bootloader unlock + ROM flash helper for Termux
# Uses official Xiaomi account authorization via MiUnlockTool (github.com/MiForge/MiUnlockTool)
# and termux-adb / termux-fastboot (github.com/nohajc/termux-adb). Needs 2 phones + OTG / C-to-C cable.

# --- self-install: type "prateek" anywhere in Termux to open this tool ---
if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ] && [ "$(realpath "$0" 2>/dev/null)" != "$PREFIX/bin/prateek" ]; then
  cp "$0" "$PREFIX/bin/prateek" 2>/dev/null && chmod +x "$PREFIX/bin/prateek" && echo -e "\033[1;32m[OK] Ab Termux mein kabhi bhi sirf 'prateek' likh ke tool khol sakte ho\033[0m" && sleep 2
fi
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; N='\033[0m'
banner(){ clear; echo -e "${C}"
echo " ____            _            _    "
echo "|  _ \ _ __ __ _| |_ ___  ___| | __"
echo "| |_) | '__/ _\` | __/ _ \/ _ \ |/ /"
echo "|  __/| | | (_| | ||  __/  __/   < "
echo "|_|   |_|  \__,_|\__\___|\___|_|\_\\"
echo -e "   ${Y}UNLOCKER + ROM FLASHER v2.0${N}"
echo -e "${C}------------------------------------${N}"; }
pause(){ echo; read -rp "Enter dabao menu pe jaane ke liye..." _; }
setup(){ echo -e "${Y}[*] Packages install ho rahe hain...${N}"
  apt update && apt install -y python-pip curl termux-api unzip tar
  pip install -U miunlock
  command -v termux-fastboot >/dev/null || curl -s https://raw.githubusercontent.com/nohajc/termux-adb/master/install.sh | bash
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

# ---------------- v2.0: ROM flasher ----------------
need_tools(){ # tools missing ho to setup khud chala do
  for t in termux-adb termux-fastboot unzip tar; do
    command -v "$t" >/dev/null || { echo -e "${Y}[*] $t nahi mila, pehle Setup chal raha hai...${N}"; setup; break; }
  done
  command -v termux-adb >/dev/null || { echo -e "${R}[-] termux-adb install nahi hua. Menu 1 (Setup) dobara chalao.${N}"; return 1; }; }
need_storage(){ [ -r /sdcard/Download ] && return 0
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
  for f in /sdcard/Download/$1 /sdcard/$1; do [ -f "$f" ] && files+=("$f"); done
  if [ ${#files[@]} -gt 0 ]; then
    echo -e "${C}Ye files mili:${N}"
    for f in "${files[@]}"; do i=$((i+1)); echo -e " ${G}[$i]${N} $(basename "$f") ($(du -h "$f" | cut -f1))"; done
    read -rp "Number likho ya pura path paste karo: " ans
  else
    echo -e "${Y}[*] /sdcard/Download mein $1 file nahi mili.${N}"
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
  FBPROD=$(fb_product)
  [ -n "$FBPROD" ] || { echo -e "${R}[-] Fastboot mein koi phone nahi mila. Cable/OTG aur permission check karo.${N}"; return 1; }
  echo -e "${G}[+] Phone mila, codename: ${C}$FBPROD${N}"; }

flash_zip(){ # [7] Recovery ZIP via ADB sideload
  need_tools || { pause; return; }; need_storage || { pause; return; }
  echo -e "${C}== Flash ROM (Recovery ZIP / ADB sideload) ==${N}"
  echo -e "${Y}Note: Phone mein custom recovery (OrangeFox/TWRP) ya ROM ki recovery honi chahiye.${N}"
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
  local n=0; until [ "$(termux-adb get-state 2>/dev/null)" = "sideload" ]; do
    n=$((n+1)); [ $n -gt 30 ] && { echo -e "${R}[-] Sideload mode mein phone nahi mila. Cable/permission check karo.${N}"; pause; return; }
    echo -ne "\r${Y}[*] Phone ka wait... ($n)${N}"; sleep 2; done
  echo; echo -e "${Y}[*] Flash shuru... (47% ya 'Total xfer' pe atakna normal hai, cable mat nikalo)${N}"
  termux-adb sideload "$zip"
  echo -e "${G}[+] Sideload khatam. Phone ki screen pe result dekho, phir recovery se 'Reboot system' karo.${N}"; pause; }

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
      df -h "$(dirname "$tgz")" | tail -1
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
  echo -e "${Y}Tip: Naye phones (jaise beryl) mein recovery partition nahi hota - OrangeFox vendor_boot mein jaata hai. Recovery ke instructions padho.${N}"
  read -rp "Choose: " p; local part
  case $p in 1) part=recovery;; 2) part=boot;; 3) part=vendor_boot;; 4) part=init_boot;; 5) part=TEMP;; *) echo "Cancel."; pause; return;; esac
  wait_fastboot || { pause; return; }
  fb_unlocked_check || { pause; return; }
  read -rp "Ye image sach mein '$FBPROD' phone ke liye bani hai? (yes likho): " ok
  [ "$ok" = "yes" ] || { echo -e "${Y}[*] Cancel. Sahi codename wali image lo.${N}"; pause; return; }
  if [ "$part" = "TEMP" ]; then
    termux-fastboot boot "$img" && echo -e "${G}[+] Image temporary boot ho rahi hai (reboot pe purana wapas).${N}"; pause; return
  fi
  flash_warn "$(basename "$img") -> $part partition ($FBPROD)" || { pause; return; }
  termux-fastboot flash "$part" "$img" && echo -e "${G}[+] $part flash ho gaya!${N}" || { echo -e "${R}[-] Flash fail.${N}"; pause; return; }
  if [ "$part" = "recovery" ] || [ "$part" = "vendor_boot" ]; then
    read -rp "Abhi recovery mein reboot karein? (y/n): " r
    [ "$r" = "y" ] && { termux-fastboot reboot recovery 2>/dev/null || termux-fastboot reboot; }
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
- Xiaomi stock fastboot ROM (.tgz): Menu 8
- Phone ko fastboot/recovery mein daalna aur cable lagana aapko khud karna hai
Note: Same phone khud ko unlock/flash nahi kar sakta, 2 phone chahiye."; pause; }
while true; do banner
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
echo -e " ${R}[0]${N} Exit"
read -rp $'\n Choose: ' c
case $c in 1) setup;; 2) check;; 3) unlock;; 4) lockcheck;; 5) reboot_;; 6) help_;; 7) flash_zip;; 8) flash_fastboot_rom;; 9) flash_img;; 0) exit 0;; *) ;; esac
done

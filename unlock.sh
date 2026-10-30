#!/data/data/com.termux/files/usr/bin/bash
# Prateek Unlocker - Xiaomi/Redmi bootloader unlock helper for Termux
# Uses official Xiaomi account authorization via MiUnlockTool (github.com/MiForge/MiUnlockTool)
# and termux-fastboot (github.com/nohajc/termux-adb). Needs 2 phones + OTG / C-to-C cable.
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; N='\033[0m'
banner(){ clear; echo -e "${C}"
echo " ____            _            _    "
echo "|  _ \ _ __ __ _| |_ ___  ___| | __"
echo "| |_) | '__/ _\` | __/ _ \/ _ \ |/ /"
echo "|  __/| | | (_| | ||  __/  __/   < "
echo "|_|   |_|  \__,_|\__\___|\___|_|\_\\"
echo -e "      ${Y}BOOTLOADER UNLOCKER v1.0${N}"
echo -e "${C}------------------------------------${N}"; }
pause(){ echo; read -rp "Enter dabao menu pe jaane ke liye..." _; }
setup(){ echo -e "${Y}[*] Packages install ho rahe hain...${N}"
  apt update && apt install -y python-pip curl termux-api
  pip install -U miunlock
  command -v termux-fastboot >/dev/null || curl -s https://raw.githubusercontent.com/nohajc/termux-adb/master/install.sh | bash
  command -v miunlock >/dev/null && echo -e "${G}[+] Setup done!${N}" || echo -e "${R}[-] Setup fail, internet check karo${N}"; pause; }
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
help_(){ echo -e "${C}Steps:${N}
1. Target phone: Settings > About phone > OS version pe 7 baar tap (Developer options)
2. Developer options > OEM unlocking ON + Mi Unlock status > Add account
3. HyperOS pe Xiaomi Community app se unlock permission apply karni padti hai (Xiaomi ka rule)
4. Xiaomi ka wait time (aksar kuch din) poora hone do
5. Is phone pe: Menu 1 (Setup) -> phone ko fastboot mein OTG se lagao -> Menu 2 -> Menu 3
Note: Same phone khud ko unlock nahi kar sakta, 2 phone chahiye."; pause; }
while true; do banner
echo -e " ${G}[1]${N} Setup (pehli baar)"
echo -e " ${G}[2]${N} Device check (fastboot)"
echo -e " ${G}[3]${N} Bootloader UNLOCK"
echo -e " ${G}[4]${N} Unlock status check"
echo -e " ${G}[5]${N} Reboot phone"
echo -e " ${G}[6]${N} Help / Steps"
echo -e " ${R}[0]${N} Exit"
read -rp $'\n Choose: ' c
case $c in 1) setup;; 2) check;; 3) unlock;; 4) lockcheck;; 5) reboot_;; 6) help_;; 0) exit 0;; *) ;; esac
done

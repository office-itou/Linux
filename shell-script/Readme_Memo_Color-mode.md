# **Linux Color mode**  
  
## set color  
  
``` bash:
    declare -r    ESC=$'\033'
    declare -r    TXT_RESET="${ESC}[m"                      # reset all attributes
    declare -r    TXT_ULINE="${ESC}[4m"                     # set underline
    declare -r    TXT_ULINERST="${ESC}[24m"                 # reset underline
    declare -r    TXT_REV="${ESC}[7m"                       # set reverse display
    declare -r    TXT_REVRST="${ESC}[27m"                   # reset reverse display
    declare -r    TXT_BLACK="${ESC}[90m"                    # text black
    declare -r    TXT_RED="${ESC}[91m"                      # text red
    declare -r    TXT_GREEN="${ESC}[92m"                    # text green
    declare -r    TXT_YELLOW="${ESC}[93m"                   # text yellow
    declare -r    TXT_BLUE="${ESC}[94m"                     # text blue
    declare -r    TXT_MAGENTA="${ESC}[95m"                  # text purple
    declare -r    TXT_CYAN="${ESC}[96m"                     # text light blue
    declare -r    TXT_WHITE="${ESC}[97m"                    # text white
    declare -r    TXT_BBLACK="${ESC}[40m"                   # text reverse black
    declare -r    TXT_BRED="${ESC}[41m"                     # text reverse red
    declare -r    TXT_BGREEN="${ESC}[42m"                   # text reverse green
    declare -r    TXT_BYELLOW="${ESC}[43m"                  # text reverse yellow
    declare -r    TXT_BBLUE="${ESC}[44m"                    # text reverse blue
    declare -r    TXT_BMAGENTA="${ESC}[45m"                 # text reverse purple
    declare -r    TXT_BCYAN="${ESC}[46m"                    # text reverse light blue
    declare -r    TXT_BWHITE="${ESC}[47m"                   # text reverse white
```
  
## text color test  
  
``` bash:
function funcColorTest() {
    printf "%s : %-12.12s : %s\n" "${TXT_RESET}"    "TXT_RESET"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_ULINE}"    "TXT_ULINE"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_ULINERST}" "TXT_ULINERST" "${TXT_RESET}"
#   printf "%s : %-12.12s : %s\n" "${TXT_BLINK}"    "TXT_BLINK"    "${TXT_RESET}"
#   printf "%s : %-12.12s : %s\n" "${TXT_BLINKRST}" "TXT_BLINKRST" "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_REV}"      "TXT_REV"      "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_REVRST}"   "TXT_REVRST"   "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BLACK}"    "TXT_BLACK"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_RED}"      "TXT_RED"      "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_GREEN}"    "TXT_GREEN"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_YELLOW}"   "TXT_YELLOW"   "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BLUE}"     "TXT_BLUE"     "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_MAGENTA}"  "TXT_MAGENTA"  "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_CYAN}"     "TXT_CYAN"     "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_WHITE}"    "TXT_WHITE"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BBLACK}"   "TXT_BBLACK"   "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BRED}"     "TXT_BRED"     "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BGREEN}"   "TXT_BGREEN"   "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BYELLOW}"  "TXT_BYELLOW"  "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BBLUE}"    "TXT_BBLUE"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BMAGENTA}" "TXT_BMAGENTA" "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BCYAN}"    "TXT_BCYAN"    "${TXT_RESET}"
    printf "%s : %-12.12s : %s\n" "${TXT_BWHITE}"   "TXT_BWHITE"   "${TXT_RESET}"
}
```
  

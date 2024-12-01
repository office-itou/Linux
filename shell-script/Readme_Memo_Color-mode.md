# **Linux Color mode**  
  
## set color  
  
``` bash:
    declare -r    TXT_RESET='\033[m'                        # reset all attributes
    declare -r    TXT_ULINE='\033[4m'                       # set underline
    declare -r    TXT_ULINERST='\033[24m'                   # reset underline
    declare -r    TXT_REV='\033[7m'                         # set reverse display
    declare -r    TXT_REVRST='\033[27m'                     # reset reverse display
    declare -r    TXT_BLACK='\033[90m'                      # text black
    declare -r    TXT_RED='\033[91m'                        # text red
    declare -r    TXT_GREEN='\033[92m'                      # text green
    declare -r    TXT_YELLOW='\033[93m'                     # text yellow
    declare -r    TXT_BLUE='\033[94m'                       # text blue
    declare -r    TXT_MAGENTA='\033[95m'                    # text purple
    declare -r    TXT_CYAN='\033[96m'                       # text light blue
    declare -r    TXT_WHITE='\033[97m'                      # text white
    declare -r    TXT_BBLACK='\033[40m'                     # text reverse black
    declare -r    TXT_BRED='\033[41m'                       # text reverse red
    declare -r    TXT_BGREEN='\033[42m'                     # text reverse green
    declare -r    TXT_BYELLOW='\033[43m'                    # text reverse yellow
    declare -r    TXT_BBLUE='\033[44m'                      # text reverse blue
    declare -r    TXT_BMAGENTA='\033[45m'                   # text reverse purple
    declare -r    TXT_BCYAN='\033[46m'                      # text reverse light blue
    declare -r    TXT_BWHITE='\033[47m'                     # text reverse white
```
  
## text color test  
  
``` bash:
function funcColorTest() {
    printf "${TXT_RESET} : %-12.12s : ${TXT_RESET}\n" "TXT_RESET"
    printf "${TXT_ULINE} : %-12.12s : ${TXT_RESET}\n" "TXT_ULINE"
    printf "${TXT_ULINERST} : %-12.12s : ${TXT_RESET}\n" "TXT_ULINERST"
#   printf "${TXT_BLINK} : %-12.12s : ${TXT_RESET}\n" "TXT_BLINK"
#   printf "${TXT_BLINKRST} : %-12.12s : ${TXT_RESET}\n" "TXT_BLINKRST"
    printf "${TXT_REV} : %-12.12s : ${TXT_RESET}\n" "TXT_REV"
    printf "${TXT_REVRST} : %-12.12s : ${TXT_RESET}\n" "TXT_REVRST"
    printf "${TXT_BLACK} : %-12.12s : ${TXT_RESET}\n" "TXT_BLACK"
    printf "${TXT_RED} : %-12.12s : ${TXT_RESET}\n" "TXT_RED"
    printf "${TXT_GREEN} : %-12.12s : ${TXT_RESET}\n" "TXT_GREEN"
    printf "${TXT_YELLOW} : %-12.12s : ${TXT_RESET}\n" "TXT_YELLOW"
    printf "${TXT_BLUE} : %-12.12s : ${TXT_RESET}\n" "TXT_BLUE"
    printf "${TXT_MAGENTA} : %-12.12s : ${TXT_RESET}\n" "TXT_MAGENTA"
    printf "${TXT_CYAN} : %-12.12s : ${TXT_RESET}\n" "TXT_CYAN"
    printf "${TXT_WHITE} : %-12.12s : ${TXT_RESET}\n" "TXT_WHITE"
    printf "${TXT_BBLACK} : %-12.12s : ${TXT_RESET}\n" "TXT_BBLACK"
    printf "${TXT_BRED} : %-12.12s : ${TXT_RESET}\n" "TXT_BRED"
    printf "${TXT_BGREEN} : %-12.12s : ${TXT_RESET}\n" "TXT_BGREEN"
    printf "${TXT_BYELLOW} : %-12.12s : ${TXT_RESET}\n" "TXT_BYELLOW"
    printf "${TXT_BBLUE} : %-12.12s : ${TXT_RESET}\n" "TXT_BBLUE"
    printf "${TXT_BMAGENTA} : %-12.12s : ${TXT_RESET}\n" "TXT_BMAGENTA"
    printf "${TXT_BCYAN} : %-12.12s : ${TXT_RESET}\n" "TXT_BCYAN"
    printf "${TXT_BWHITE} : %-12.12s : ${TXT_RESET}\n" "TXT_BWHITE"
}
```
  

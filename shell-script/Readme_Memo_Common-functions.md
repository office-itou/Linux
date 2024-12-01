# **Linux common functions**  
  
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
  
## diff  
  
``` bash:
function funcDiff() {
    if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
        return
    fi
    funcPrintf "$3"
    diff -y -W "${COLS_SIZE}" --suppress-common-lines "$1" "$2" || true
}
```
  
## substr  
  
``` bash:
function funcSubstr() {
    echo "$1" | awk '{print substr($0,'"$2"','"$3"');}'
}
```
  
## IPv6 full address  
  
``` bash:
function funcIPv6GetFullAddr() {
#   declare -r    OLD_IFS="${IFS}"
    declare       INP_ADDR="$1"
    declare -r    STR_FSEP="${INP_ADDR//[^:]}"
    declare -r -i CNT_FSEP=$((7-${#STR_FSEP}))
    declare -a    OUT_ARRY=()
    declare       OUT_TEMP=""
    if [[ "${CNT_FSEP}" -gt 0 ]]; then
        OUT_TEMP="$(eval printf ':%.s' "{1..$((CNT_FSEP+2))}")"
        INP_ADDR="${INP_ADDR/::/${OUT_TEMP}}"
    fi
    IFS=':'
    # shellcheck disable=SC2206
    OUT_ARRY=(${INP_ADDR/%:/::})
    IFS=${OLD_IFS}
    OUT_TEMP="$(printf ':%04x' "${OUT_ARRY[@]/#/0x0}")"
    echo "${OUT_TEMP:1}"
}
```
  
## IPv6 reverse address  
  
``` bash:
function funcIPv6GetRevAddr() {
    declare -r    INP_ADDR="$1"
    echo "${INP_ADDR//:/}"                   | \
        awk '{for(i=length();i>1;i--)          \
            printf("%c.", substr($0,i,1));     \
            printf("%c" , substr($0,1,1));}'
}
```
  
## IPv4 netmask conversion  
  
``` bash:
function funcIPv4GetNetmask() {
    declare -r    INP_ADDR="$1"
#   declare       DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-INP_ADDR)-1)))"
    declare -i    LOOP=$((32-INP_ADDR))
    declare -i    WORK=1
    declare       DEC_ADDR=""
    while [[ "${LOOP}" -gt 0 ]]
    do
        LOOP=$((LOOP-1))
        WORK=$((WORK*2))
    done
    DEC_ADDR="$((0xFFFFFFFF ^ (WORK-1)))"
    printf '%d.%d.%d.%d'             \
        $(( DEC_ADDR >> 24        )) \
        $(((DEC_ADDR >> 16) & 0xFF)) \
        $(((DEC_ADDR >>  8) & 0xFF)) \
        $(( DEC_ADDR        & 0xFF))
}
```
  
## IPv4 cidr conversion  
  
``` bash:
function funcIPv4GetNetCIDR() {
    declare -r    INP_ADDR="$1"
    #declare -a    OCTETS=()
    #declare -i    MASK=0
    echo "${INP_ADDR}" | \
        awk -F '.' '{
            split($0, OCTETS);
            for (I in OCTETS) {
                MASK += 8 - log(2^8 - OCTETS[I])/log(2);
            }
            print MASK
        }'
}
```
  
## is numeric  
  
``` bash:
function funcIsNumeric() {
    if [[ ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        echo 0
    else
        echo 1
    fi
}
```
  
## string output  
  
``` bash:
function funcString() {
#   declare -r    OLD_IFS="${IFS}"
    IFS=$'\n'
    if [[ "$1" -le 0 ]]; then
        echo ""
    else
        if [[ "$2" = " " ]]; then
            echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); print s;}'
        else
            echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); gsub(" ","'"$2"'",s); print s;}'
        fi
    fi
    IFS="${OLD_IFS}"
}
```
  
## print with screen control  
  
``` bash:
function funcPrintf() {
#   declare -r    SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
    declare -r    SET_ENV_X="$(set -o | awk '$1=="xtrace"  {print $2;}')"
    set +x
    # https://www.tohoho-web.com/ex/dash-tilde.html
#   declare -r    OLD_IFS="${IFS}"
#   declare -i    RET_CD=0
    declare       FLAG_CUT=""
    declare       TEXT_FMAT=""
    declare -r    CTRL_ESCP=$'\033['
    declare       PRNT_STR=""
    declare       SJIS_STR=""
    declare       TEMP_STR=""
    declare       WORK_STR=""
    declare -i    CTRL_CNT=0
    declare -i    MAX_COLS="${COLS_SIZE:-80}"
    # -------------------------------------------------------------------------
    IFS=$'\n'
    if [[ "$1" = "--no-cutting" ]]; then                    # no cutting print
        FLAG_CUT="true"
        shift
    fi
    if [[ "$1" =~ %[0-9.-]*[diouxXfeEgGcs]+ ]]; then
        # shellcheck disable=SC2001
        TEXT_FMAT="$(echo "$1" | sed -e 's/%\([0-9.-]*\)s/%\1b/g')"
        shift
    fi
    # shellcheck disable=SC2059
    PRNT_STR="$(printf "${TEXT_FMAT:-%b}" "${@:-}")"
    if [[ -z "${FLAG_CUT}" ]]; then
        SJIS_STR="$(echo -n "${PRNT_STR:-}" | iconv -f UTF-8 -t CP932)"
        TEMP_STR="$(echo -n "${SJIS_STR}" | sed -e "s/${CTRL_ESCP}[0-9]*m//g")"
        if [[ "${#TEMP_STR}" -gt "${MAX_COLS}" ]]; then
            CTRL_CNT=$((${#SJIS_STR}-${#TEMP_STR}))
            WORK_STR="$(echo -n "${SJIS_STR}" | cut -b $((MAX_COLS+CTRL_CNT))-)"
            TEMP_STR="$(echo -n "${WORK_STR}" | sed -e "s/${CTRL_ESCP}[0-9]*m//g")"
            MAX_COLS+=$((CTRL_CNT-(${#WORK_STR}-${#TEMP_STR})))
            # shellcheck disable=SC2312
            if ! PRNT_STR="$(echo -n "${SJIS_STR:-}" | cut -b -"${MAX_COLS}"   | iconv -f CP932 -t UTF-8 2> /dev/null)"; then
                 PRNT_STR="$(echo -n "${SJIS_STR:-}" | cut -b -$((MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
            fi
        fi
    fi
    printf "%b\n" "${PRNT_STR:-}"
    IFS="${OLD_IFS}"
    # -------------------------------------------------------------------------
    if [[ "${SET_ENV_X}" = "on" ]]; then
        set -x
    else
        set +x
    fi
#   if [[ "${SET_ENV_E}" = "on" ]]; then
#       set -e
#   else
#       set +e
#   fi
}
```
  
## unit conversion  
  
``` bash:
function funcUnit_conversion() {
#   declare -r    OLD_IFS="${IFS}"
    declare -r -a TEXT_UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
    declare -i    CALC_UNIT=0
    declare -i    I=0

    if [[ "$1" -lt 1024 ]]; then
        printf "%'d Byte" "$1"
        return
    fi
    for ((I=3; I>0; I--))
    do
        CALC_UNIT=$((1024**I))
        if [[ "$1" -ge "${CALC_UNIT}" ]]; then
            # shellcheck disable=SC2312
            printf "%s %s" "$(echo "$1" "${CALC_UNIT}" | awk '{printf("%.1f", $1/$2)}')" "${TEXT_UNIT[${I}]}"
            return
        fi
    done
    echo -n "$1"
}
```
  
## download  
  
``` bash:
function funcCurl() {
#   declare -r    OLD_IFS="${IFS}"
    declare -i    RET_CD=0
    declare -i    I
    declare       INP_URL=""
    declare       OUT_DIR=""
    declare       OUT_FILE=""
    declare       MSG_FLG=""
    declare -a    OPT_PRM=()
    declare -a    ARY_HED=()
    declare       ERR_MSG=""
    declare       WEB_SIZ=""
    declare       WEB_TIM=""
    declare       WEB_FIL=""
    declare       LOC_INF=""
    declare       LOC_SIZ=""
    declare       LOC_TIM=""
    declare       TXT_SIZ=""

    while [[ -n "${1:-}" ]]
    do
        case "${1:-}" in
            http://* | https://* )
                OPT_PRM+=("${1}")
                INP_URL="${1}"
                ;;
            --output-dir )
                OPT_PRM+=("${1}")
                shift
                OPT_PRM+=("${1}")
                OUT_DIR="${1}"
                ;;
            --output )
                OPT_PRM+=("${1}")
                shift
                OPT_PRM+=("${1}")
                OUT_FILE="${1}"
                ;;
            --quiet )
                MSG_FLG="true"
                ;;
            * )
                OPT_PRM+=("${1}")
                ;;
        esac
        shift
    done
    if [[ -z "${OUT_FILE}" ]]; then
        OUT_FILE="${INP_URL##*/}"
    fi
    if ! ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${INP_URL}" 2> /dev/null)"); then
        RET_CD="$?"
        ERR_MSG=$(echo "${ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
#       echo -e "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
        if [[ -z "${MSG_FLG}" ]]; then
            printf "%s\n" "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
        fi
        return "${RET_CD}"
    fi
    WEB_SIZ=$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
    # shellcheck disable=SC2312
    WEB_TIM=$(TZ=UTC date -d "$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
    WEB_FIL="${OUT_DIR:-.}/${INP_URL##*/}"
    if [[ -n "${OUT_DIR}" ]] && [[ ! -d "${OUT_DIR}/." ]]; then
        mkdir -p "${OUT_DIR}"
    fi
    if [[ -n "${OUT_FILE}" ]] && [[ -e "${OUT_FILE}" ]]; then
        WEB_FIL="${OUT_FILE}"
    fi
    if [[ -n "${WEB_FIL}" ]] && [[ -e "${WEB_FIL}" ]]; then
        LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${WEB_FIL}")
        LOC_TIM=$(echo "${LOC_INF}" | awk '{print $6;}')
        LOC_SIZ=$(echo "${LOC_INF}" | awk '{print $5;}')
        if [[ "${WEB_TIM:-0}" -eq "${LOC_TIM:-0}" ]] && [[ "${WEB_SIZ:-0}" -eq "${LOC_SIZ:-0}" ]]; then
            if [[ -z "${MSG_FLG}" ]]; then
                funcPrintf "same    file: ${WEB_FIL}"
            fi
            return
        fi
    fi

    TXT_SIZ="$(funcUnit_conversion "${WEB_SIZ}")"

    if [[ -z "${MSG_FLG}" ]]; then
        funcPrintf "get     file: ${WEB_FIL} (${TXT_SIZ})"
    fi
    if curl "${OPT_PRM[@]}"; then
        return $?
    fi

    for ((I=0; I<3; I++))
    do
        if [[ -z "${MSG_FLG}" ]]; then
            funcPrintf "retry  count: ${I}"
        fi
        if curl --continue-at "${OPT_PRM[@]}"; then
            return "$?"
        else
            RET_CD="$?"
        fi
    done
    if [[ "${RET_CD}" -ne 0 ]]; then
        rm -f "${:?}"
    fi
    return "${RET_CD}"
}
```
  
## service status  
  
``` bash:
function funcServiceStatus() {
#   declare -r    OLD_IFS="${IFS}"
    # shellcheck disable=SC2155
    declare       SRVC_STAT="$(systemctl is-enabled "$1" 2> /dev/null || true)"
    # -------------------------------------------------------------------------
    if [[ -z "${SRVC_STAT}" ]]; then
        SRVC_STAT="not-found"
    fi
    case "${SRVC_STAT}" in
        disabled        ) SRVC_STAT="disabled";;
        enabled         | \
        enabled-runtime ) SRVC_STAT="enabled";;
        linked          | \
        linked-runtime  ) SRVC_STAT="linked";;
        masked          | \
        masked-runtime  ) SRVC_STAT="masked";;
        alias           ) ;;
        static          ) ;;
        indirect        ) ;;
        generated       ) ;;
        transient       ) ;;
        bad             ) ;;
        not-found       ) ;;
        *               ) SRVC_STAT="undefined";;
    esac
    echo "${SRVC_STAT}"
}
```
  
## function is package  
  
``` bash:
function funcIsPackage () {
    LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
}
```
  

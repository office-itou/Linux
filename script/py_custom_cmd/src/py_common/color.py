class Color_code():
    def __init__(self):
        self.code = {
            "reset"             :"\033[0m" ,                # reset all attributes
            "bold"              :"\033[1m" ,                #
            "faint"             :"\033[2m" ,                #
            "italic"            :"\033[3m" ,                #
            "underline"         :"\033[4m" ,                # set underline
            "blink"             :"\033[5m" ,                #
            "fast_blink"        :"\033[6m" ,                #
            "reverse"           :"\033[7m" ,                # set reverse display
            "conceal"           :"\033[8m" ,                #
            "strike"            :"\033[9m" ,                #
            "gothic"            :"\033[20m",                #
            "double_underline"  :"\033[21m",                #
            "normal"            :"\033[22m",                #
            "no_italic"         :"\033[23m",                #
            "no_underline"      :"\033[24m",                # reset underline
            "no_blink"          :"\033[25m",                #
            "no_reverse"        :"\033[27m",                # reset reverse display
            "no_conceal"        :"\033[28m",                #
            "no_strike"         :"\033[29m",                #
            "black"             :"\033[30m",                # text dark black
            "red"               :"\033[31m",                # text dark red
            "green"             :"\033[32m",                # text dark green
            "yellow"            :"\033[33m",                # text dark yellow
            "blue"              :"\033[34m",                # text dark blue
            "magenta"           :"\033[35m",                # text dark purple
            "cyan"              :"\033[36m",                # text dark light blue
            "white"             :"\033[37m",                # text dark white
            "default"           :"\033[39m",                #
            "bg_black"          :"\033[40m",                # text reverse black
            "bg_red"            :"\033[41m",                # text reverse red
            "bg_green"          :"\033[42m",                # text reverse green
            "bg_yellow"         :"\033[43m",                # text reverse yellow
            "bg_blue"           :"\033[44m",                # text reverse blue
            "bg_magenta"        :"\033[45m",                # text reverse purple
            "bg_cyan"           :"\033[46m",                # text reverse light blue
            "bg_white"          :"\033[47m",                # text reverse white
            "bg_default"        :"\033[49m",                #
            "br_black"          :"\033[90m",                # text black
            "br_red"            :"\033[91m",                # text red
            "br_green"          :"\033[92m",                # text green
            "br_yellow"         :"\033[93m",                # text yellow
            "br_blue"           :"\033[94m",                # text blue
            "br_magenta"        :"\033[95m",                # text purple
            "br_cyan"           :"\033[96m",                # text light blue
            "br_white"          :"\033[97m",                # text white
            "br_default"        :"\033[99m",                #
        }

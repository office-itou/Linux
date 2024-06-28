@echo off
    if /i "%1" == "-R" goto REBOOT
    if /i "%1" == "/R" goto REBOOT
    if /i "%1" == "-S" goto PWOFF
    if /i "%1" == "/S" goto PWOFF

:USAGE
    echo Power Management Commands
    echo usage: shutdown -r/-s
    echo -r: Restart the computer.
    echo -s: Turn off the computer.
    goto DONE

:REBOOT
    wpeutil reboot
    goto DONE

:PWOFF
    wpeutil shutdown
    goto DONE

:DONE

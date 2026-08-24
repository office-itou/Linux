#!/usr/bin/env python3
# encoding: utf-8

## -----------------------------------------------------------------------------
from .colors import color

def debugout(output, message_color, function_name, mode, messeage):
    if output == True:
        print(f"{color.reset}{message_color}{function_name:<16}:{mode:^10}:{messeage:<}{color.reset}")

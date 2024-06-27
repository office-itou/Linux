# **install.sh.user.lst**  
  
## File format  
  
``` bash:
# --- user information ----------------------------------------------------
# USER_LIST
#  0: status flag (a:add, s: skip, e: error, o: export)
#  1: administrator flag (1: sambaadmin)
#  2: full name
#  3: user name
#  4: user password (unused)
#  5: user id
#  6: lanman password
#  7: nt password
#  8: account flags
#  9:last change time
# sample: administrator's password="password"
declare -a    USER_LIST=( \
    "a:1:Administrator:administrator:unused:1001:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-00000000:" \
)   #0:1:2            :3            :4     :5   :6                               :7                               :8            :9
```
  

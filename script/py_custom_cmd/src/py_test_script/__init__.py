from pathlib        import Path
import os
import sys
execusr = os.getenv('USER')
execusr = os.getenv('SUDO_USER', execusr)
homedir = os.getenv('HOME')
homedir = os.getenv('SUDO_HOME', homedir)
libsdir = '/linux/script/py_custom_cmd/src/'
libsdir = Path(homedir) / libsdir.strip('/')
sys.path.append(str(libsdir))

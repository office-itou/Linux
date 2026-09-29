# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['creation_of_the_ipxe_menu.py'],
    pathex=['/srv/hgfs/linux/script/py_custom_cmd/src/tools'],
    binaries=[],
    datas=[],
    hiddenimports=['common.shared.my_common_cfg', 'common.shared.my_convert', 'common.shared.my_distribution_dat', 'common.shared.my_func_check_root', 'common.shared.my_func_initarg', 'common.shared.my_media_dat', 'common.shared.my_shared', 'common.utils.my_argument', 'common.utils.my_colors', 'common.utils.my_config', 'common.utils.my_debug', 'common.utils.my_error', 'common.utils.my_file_api', 'common.utils.my_json', 'common.utils.my_language', 'common.utils.my_markdown', 'common.utils.my_mem_usage', 'common.utils.my_message', 'common.utils.my_string', 'common.utils.my_time'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['matplotlib', 'numpy', 'scipy', 'PIL', 'unittest', 'pydoc', 'openpyxl', 'lxml', 'tkinter', 'tkinter.test', 'Tkinter', '_tkinter'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='creation_of_the_ipxe_menu',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

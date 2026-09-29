# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['management_of_shared_data.py'],
    pathex=['/srv/hgfs/linux/script/py_custom_cmd/src/tools.test'],
    binaries=[],
    datas=[],
    hiddenimports=['common.shared.my_common_cfg', 'common.shared.my_convert', 'common.shared.my_distribution_dat', 'common.shared.my_func_check_root', 'common.shared.my_func_generate_markdown', 'common.shared.my_func_initarg', 'common.shared.my_media_dat', 'common.shared.my_shared', 'common.utils.my_argument', 'common.utils.my_colors', 'common.utils.my_config', 'common.utils.my_debug', 'common.utils.my_error', 'common.utils.my_file_api', 'common.utils.my_json', 'common.utils.my_language', 'common.utils.my_markdown', 'common.utils.my_mem_usage', 'common.utils.my_message', 'common.utils.my_string', 'common.utils.my_time'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['matplotlib', 'numpy', 'scipy', 'PIL', 'tkinter', 'tkinter.test', 'Tkinter', '_tkinter', 'unittest', 'pydoc', 'openpyxl', 'lxml'],
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
    name='management_of_shared_data',
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

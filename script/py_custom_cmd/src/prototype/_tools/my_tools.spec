# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['my_tools.py'],
    pathex=['/srv/hgfs/linux/script/py_custom_cmd/src/prototype/_tools'],
    binaries=[],
    datas=[('ui_definition.json', '.')],
    hiddenimports=['async_io', 'common.shared.my_async_api', 'common.shared.my_common_cfg', 'common.shared.my_convert', 'common.shared.my_distribution_dat', 'common.shared.my_media_dat', 'common.shared.my_shared', 'common.utils.my_colors', 'common.utils.my_config', 'common.utils.my_debug', 'common.utils.my_error', 'common.utils.my_file_api', 'common.utils.my_gui_build_helper', 'common.utils.my_infofile', 'common.utils.my_infoweb', 'common.utils.my_json', 'common.utils.my_language', 'common.utils.my_markdown', 'common.utils.my_mem_usage', 'common.utils.my_message', 'common.utils.my_process', 'common.utils.my_string', 'common.utils.my_time', 'common.utils.my_web_api', 'gui_main', 'gui_main_build', 'gui_main_build_buttons', 'gui_main_build_tables', 'gui_main_event', 'my_tools'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['matplotlib', 'numpy', 'scipy', 'PIL', 'unittest', 'pydoc', 'openpyxl', 'lxml'],
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
    name='my_tools',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

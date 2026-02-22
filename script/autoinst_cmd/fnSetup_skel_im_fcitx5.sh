# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: input method skeleton for fcitx5
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_skel_im_fcitx5() {
	___FUNC_NAME="fnSetup_skel_im_fcitx5"
	fnMsgout "${_PROG_NAME:-}" "start" "[${___FUNC_NAME}]"

	# --- fcitx5 --------------------------------------------------------------
	if command -v fcitx5 > /dev/null 2>&1; then
		# --- .xinputrc -------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/skel/.xinputrc"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			# im-config(8) generated on Sat, 14 Feb 2026 09:14:00 +0900
			run_im fcitx5
			# im-config signature: d9b9928f862c39723ce984af60025ad5  -
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- .xprofile -------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/skel/.config/environment.d/99fcitx.conf"
#		__PATH="${_DIRS_TGET:-}/etc/environment.d/99fcitx.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			XMODIFIERS=@im=fcitx
			QT_IM_MODULE=fcitx
			#GTK_IM_MODULE=fcitx
			#SDL_IM_MODULE=fcitx
			#QT_IM_MODULES="wayland;fcitx"
			#CLUTTER_IM_MODULE=xim
			#IM_CONFIG_PHASE=
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- profile ---------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/skel/.config/fcitx5/profile"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[Groups/0]
			# Group Name
			Name=デフォルト
			# Layout
			Default Layout=jp
			# Default Input Method
			DefaultIM=mozc

			[Groups/0/Items/0]
			# Name
			Name=keyboard-jp
			# Layout
			Layout=

			[Groups/0/Items/1]
			# Name
			Name=mozc
			# Layout
			Layout=

			[Groups/0/Items/2]
			# Name
			Name=anthy
			# Layout
			Layout=

			[GroupOrder]
			0=デフォルト

_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- config ----------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/skel/.config/fcitx5/config"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[Hotkey]
			# トリガーキーを押すたびに切り替える
			EnumerateWithTriggerKeys=True
			# 次の入力メソッドに切り替える
			EnumerateForwardKeys=
			# 前の入力メソッドに切り替える
			EnumerateBackwardKeys=
			# 切り替え時は第1入力メソッドをスキップする
			EnumerateSkipFirst=False

			[Hotkey/TriggerKeys]
			0=Control+space
			1=Zenkaku_Hankaku
			2=Hangul

			[Hotkey/AltTriggerKeys]
			0=Shift_L

			[Hotkey/EnumerateGroupForwardKeys]
			0=Super+space

			[Hotkey/EnumerateGroupBackwardKeys]
			0=Shift+Super+space

			[Hotkey/ActivateKeys]
			0=Hangul_Hanja

			[Hotkey/DeactivateKeys]
			0=Hangul_Romaja

			[Hotkey/PrevPage]
			0=Up

			[Hotkey/NextPage]
			0=Down

			[Hotkey/PrevCandidate]
			0=Shift+Tab

			[Hotkey/NextCandidate]
			0=Tab

			[Hotkey/TogglePreedit]
			0=Control+Alt+P

			[Behavior]
			# デフォルトで有効にする
			ActiveByDefault=False
			# 入力状態を共有する
			ShareInputState=No
			# アプリケーションにプリエディットを表示する
			PreeditEnabledByDefault=True
			# 入力メソッドを切り替える際に入力メソッドの情報を表示する
			ShowInputMethodInformation=True
			# フォーカスを変更する際に入力メソッドの情報を表示する
			showInputMethodInformationWhenFocusIn=False
			# 入力メソッドの情報をコンパクトに表示する
			CompactInputMethodInformation=True
			# 第1入力メソッドの情報を表示する
			ShowFirstInputMethodInformation=True
			# デフォルトのページサイズ
			DefaultPageSize=5
			# XKB オプションより優先する
			OverrideXkbOption=False
			# カスタム XKB オプション
			CustomXkbOption=
			# Force Enabled Addons
			EnabledAddons=
			# Force Disabled Addons
			DisabledAddons=
			# Preload input method to be used by default
			PreloadInputMethod=True
			# パスワード欄に入力メソッドを許可する
			AllowInputMethodForPassword=False
			# パスワード入力時にプリエディットテキストを表示する
			ShowPreeditForPassword=False
			# ユーザーデータを保存する間隔（分）
			AutoSavePeriod=30

_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	unset __PATH __CONF __DIRS

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${___FUNC_NAME}]" 
	unset ___FUNC_NAME
}

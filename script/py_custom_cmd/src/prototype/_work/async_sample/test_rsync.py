#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
import asyncio
import subprocess
import sys
from pathlib import Path
from typing import Any, Mapping


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
)


# ruff: isort: on
# =============================================================================
async def process_rsync(
    src_path: Path,
    dest_path: Path,
    mount_path: Path,
    task_name: str,
    semaphore: asyncio.Semaphore,
) -> bool:
    _caller = get_caller_name()
    _rsync_opt = [
        "--recursive",
        "--links",
        "--perms",
        "--times",
        "--group",
        "--owner",
        "--devices",
        "--specials",
        "--hard-links",
        "--acls",
        "--xattrs",
        "--human-readable",
        "--delete",
        "--info=stats2",
        "--compress",
    ]
    _kwargs: Mapping[str, Any] = {
        "stdout": asyncio.subprocess.PIPE,
        "stderr": asyncio.subprocess.PIPE,
    }
    _status = False
    _mounted = False
    async with semaphore:
        # --- command ---------------------------------------------------------
        _rsync_src = f"{str(mount_path)}/."
        _rsync_dest = f"{str(dest_path)}/"
        _sudo_args = ["sudo", "-n"]
        _nice_args = ["nice", "-n", "19"]
        _mount_args = [*_sudo_args, "mount", "-o", "loop,ro", src_path, mount_path]
        _rsync_args = [
            *_sudo_args,
            *_nice_args,
            "rsync",
            *_rsync_opt,
            _rsync_src,
            _rsync_dest,
        ]
        _umount_args = [*_sudo_args, "umount", mount_path]
        try:
            # --- start -----------------------------------------------------------
            message_info(_caller, f"{task_name}: start")
            # --- mkdir -----------------------------------------------------------
            mount_path.mkdir(parents=True, exist_ok=True)
            dest_path.mkdir(parents=True, exist_ok=True)
            # --- mount -----------------------------------------------------------
            _mount_proc = await asyncio.create_subprocess_exec(*_mount_args, **_kwargs)
            _, _stderr_mount = await _mount_proc.communicate()
            if _mount_proc.returncode != 0:
                for _message in _stderr_mount.decode().splitlines():
                    message_alert(
                        _caller, f"{task_name}: {_message.strip()}", omit=True
                    )
                return False
            _mounted = True  # マウントに成功したためフラグを立てる
            # --- rsync -------------------------------------------------------
            _rsync_proc = await asyncio.create_subprocess_exec(*_rsync_args, **_kwargs)
            assert _rsync_proc.stdout is not None
            try:
                while True:
                    _line_bytes = await _rsync_proc.stdout.readline()
                    if not _line_bytes:
                        break
                    _message = _line_bytes.decode().strip()
                    if _message:
                        message_info(_caller, f"{task_name}: {_message}", omit=True)
            except asyncio.CancelledError:
                # 外部からキャンセルされた場合、実行中のrsyncプロセスを強制終了
                try:
                    _rsync_proc.terminate()
                    await _rsync_proc.wait()
                except ProcessLookupError:
                    pass
                raise  # 上位のfinallyへ進むために例外を再送出
            _stdout_rsync, _stderr_rsync = await _rsync_proc.communicate()
            if _rsync_proc.returncode != 0:
                for _message in _stderr_rsync.decode().splitlines():
                    message_alert(
                        _caller, f"{task_name}: {_message.strip()}", omit=True
                    )
            else:
                message_info(_caller, f"{task_name}: complete")
                _status = True
        except asyncio.CancelledError:
            message_alert(
                _caller, f"{task_name}: 処理がキャンセルされました。", omit=True
            )
            raise
        except (OSError, Exception) as e:
            handle_fatal_error(_caller, e, raise_exit=False)
        finally:
            # --- unmount (必ず実行される後始末) --------------------------------------
            if _mounted:
                _umount_proc = await asyncio.create_subprocess_exec(
                    *_umount_args, **_kwargs
                )
                await _umount_proc.communicate()
                # アンマウントが失敗した場合の段階的な強制解除リトライ
                if _umount_proc.returncode != 0:
                    _umount_args = [*_sudo_args, "umount", "-f", mount_path]
                    _umount_proc = await asyncio.create_subprocess_exec(
                        *_umount_args, **_kwargs
                    )
                    await _umount_proc.communicate()
                    if _umount_proc.returncode != 0:
                        _umount_args = [*_sudo_args, "umount", "-l", mount_path]
                        _umount_proc = await asyncio.create_subprocess_exec(
                            *_umount_args, **_kwargs
                        )
                        await _umount_proc.communicate()
                # 最終的なアンマウント成否の判定
                if _umount_proc.returncode != 0:
                    message_alert(
                        _caller,
                        f"{task_name}: マウントの解除に完全に失敗しました。",
                        omit=True,
                    )
                    _status = False
    return _status


def pre_authenticate_sudo() -> bool:
    """親スクリプト（非root）の起動時に、事前に一度だけパスワードを入力させておく"""
    print(
        "特権コマンド実行のため、sudo権限を確認しています。パスワードを求められた場合は入力してください。"
    )
    try:
        subprocess.run(["sudo", "-v"], check=True)
        return True
    except subprocess.CalledProcessError:
        print("エラー: sudo認証に失敗しました。", file=sys.stderr)
        return False


async def main():
    if not pre_authenticate_sudo():
        sys.exit(1)
    semaphore = asyncio.Semaphore(3)
    tasks = []
    for _src_file in (
        "debian-12.15.0-amd64-DVD-1.iso",
        "debian-12.15.0-amd64-netinst.iso",
        "debian-13.7.0-amd64-DVD-1.iso",
        "debian-13.7.0-amd64-netinst.iso",
        "debian-live-12.15.0-amd64-cinnamon.iso",
        "debian-live-12.15.0-amd64-gnome.iso",
        "debian-live-13.7.0-amd64-cinnamon.iso",
        "debian-live-13.7.0-amd64-gnome.iso",
        "debian-live-testing-amd64-cinnamon.iso",
        "debian-live-testing-amd64-gnome.iso",
        "debian-testing-amd64-DVD-1.iso",
        "debian-testing-amd64-netinst.iso",
        "debian-testing-daily-builds-arch-latest-amd64-netinst.iso",
        "debian-testing-daily-builds-current-amd64-netinst.iso",
        "debian-testing-weekly-builds-amd64-netinst.iso",
        "mini-bookworm-amd64.iso",
        "mini-forky-amd64.iso",
        "mini-testing-amd64.iso",
        "mini-testing-daily-amd64.img",
        "mini-testing-daily-amd64.iso",
        "mini-trixie-amd64.iso",
    ):
        _src_path = Path(f"/srv/user/share/isos/linux/debian/{_src_file}")
        _src_base = _src_path.stem
        tasks.append(
            process_rsync(
                src_path=_src_path,
                dest_path=Path(f"/home/master/test/{_src_base}"),
                mount_path=Path(f"/home/master/mnt/{_src_base}"),
                task_name=_src_base,
                semaphore=semaphore,
            )
        )
    print(f"--- 全{len(tasks)}件のISO同期処理を並行開始します (最大3並列) ---")
    try:
        # asyncio.gather を使ってすべてのタスクを実行
        results = await asyncio.gather(*tasks)
        if all(results):
            print("\n[完了]: すべてのISOタスクが正常に終了しました。")
        else:
            print(
                "\n[エラー]: 一部のタスクで失敗が発生しました。ログを確認してください。",
                file=sys.stderr,
            )
    except asyncio.CancelledError:
        print(
            "\n[キャンセル]: 実行中のすべてのタスクが中断されました。", file=sys.stderr
        )


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nユーザーによって処理が強制終了されました(Ctrl+C)。")

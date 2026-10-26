# --- python library ----------------------------------------------------------
import os

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def is_container() -> str | None:
    _caller = get_caller_name()
    if os.path.exists("/.dockerenv"):
        return "docker"
    if os.path.exists("/proc/1/cgroup"):
        try:
            with open("/proc/1/cgroup", "r") as f:
                _cgroup_content = f.read()
                if "docker" in _cgroup_content or "containerd" in _cgroup_content:
                    return "docker/containerd"
                if "lxc" in _cgroup_content:
                    return "lxc"
                if "kubepods" in _cgroup_content:
                    return "k8s"
        except Exception:
            pass
    return None


@debug_logger
def is_vm_type() -> str | None:
    _caller = get_caller_name()
    _hypervisor_files = [
        "/sys/class/dmi/id/product_name",
        "/sys/class/dmi/id/sys_vendor",
    ]
    _vm_keywords = [
        "kvm",
        "qemu",
        "virtualbox",
        "vmware",
        "xen",
        "hyper-v",
        "microsoft",
    ]
    for _file_path in _hypervisor_files:
        if os.path.exists(_file_path):
            try:
                with open(_file_path, "r") as f:
                    content = f.read().lower()
                    for kw in _vm_keywords:
                        if kw in content:
                            return kw
            except Exception:
                pass
    if os.path.exists("/sys/hypervisor/type"):
        try:
            with open("/sys/hypervisor/type", "r") as f:
                return f.read().strip()
        except Exception:
            return "unknown_hypervisor"
    return None


@debug_logger
def is_chroot() -> str | None:
    _caller = get_caller_name()
    try:
        _init_root = os.stat("/proc/1/root")
        _current_root = os.stat("/")
        if (_init_root.st_dev != _current_root.st_dev) or (
            _init_root.st_ino != _current_root.st_ino
        ):
            return True
    except Exception:
        pass
    return None

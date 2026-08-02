#!/usr/bin/env python3
import sys
import os
import ctypes
import ctypes.util
import getpass
import subprocess

def verify_via_chkpwd(username, password):
    """Uses setuid unix_chkpwd helper for unprivileged Linux desktop password verification."""
    chkpwd_paths = [
        '/sbin/unix_chkpwd',
        '/usr/sbin/unix_chkpwd',
        '/usr/libexec/unix_chkpwd',
        '/usr/lib/security/unix_chkpwd',
        '/usr/lib/chkpwd/unix_chkpwd'
    ]
    
    chkpwd_bin = None
    for p in chkpwd_paths:
        if os.path.exists(p):
            chkpwd_bin = p
            break
            
    if not chkpwd_bin:
        return False
        
    try:
        proc = subprocess.Popen(
            [chkpwd_bin, username, 'nullhelper'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        pwd_bytes = password.encode('utf-8') + b'\x00'
        proc.communicate(input=pwd_bytes, timeout=3)
        return (proc.returncode == 0)
    except Exception:
        return False

def verify_via_libpam(username, password):
    """Uses libpam C API for PAM service authentication."""
    try:
        libpam_path = ctypes.util.find_library('pam') or 'libpam.so.0'
        libpam = ctypes.CDLL(libpam_path)
        libc = ctypes.CDLL(None)
    except Exception:
        return False

    class PamMessage(ctypes.Structure):
        _fields_ = [('msg_style', ctypes.c_int), ('msg', ctypes.c_char_p)]

    class PamResponse(ctypes.Structure):
        _fields_ = [('resp', ctypes.c_char_p), ('resp_retcode', ctypes.c_int)]

    CONV_FUNC = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.POINTER(PamMessage)), ctypes.POINTER(ctypes.POINTER(PamResponse)), ctypes.c_void_p)

    class PamConv(ctypes.Structure):
        _fields_ = [('conv', CONV_FUNC), ('appdata_ptr', ctypes.c_void_p)]

    pwd_bytes = password.encode('utf-8')

    def conv_cb(num_msg, msg, resp, appdata_ptr):
        response_array = (PamResponse * num_msg)()
        for i in range(num_msg):
            response_array[i].resp = libc.strdup(pwd_bytes)
            response_array[i].resp_retcode = 0
        resp[0] = ctypes.cast(response_array, ctypes.POINTER(PamResponse))
        return 0

    cb = CONV_FUNC(conv_cb)
    conv = PamConv(cb, None)

    for service in ['system-auth', 'system-local-login', 'system-login', 'login', 'passwd', 'kde', 'sddm', 'gdm', 'su', 'other']:
        try:
            pamh = ctypes.c_void_p()
            res = libpam.pam_start(service.encode('utf-8'), username.encode('utf-8'), ctypes.byref(conv), ctypes.byref(pamh))
            if res == 0:
                auth_res = libpam.pam_authenticate(pamh, 0)
                libpam.pam_end(pamh, auth_res)
                if auth_res == 0:
                    return True
        except Exception:
            pass
            
    return False

def verify_password(username, password):
    if not password:
        return False
        
    # 1. Primary method for non-root desktop processes: unix_chkpwd
    if verify_via_chkpwd(username, password):
        return True

    # 2. Fallback method: libpam API
    if verify_via_libpam(username, password):
        return True

    return False

def main():
    password = ""
    if len(sys.argv) >= 2:
        password = sys.argv[1]
    else:
        password = sys.stdin.read().strip()

    username = getpass.getuser()
    if len(sys.argv) >= 3:
        username = sys.argv[2].strip()

    success = verify_password(username, password)
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()

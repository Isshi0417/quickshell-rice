#!/usr/bin/env python3
import sys
import os
import ctypes
import ctypes.util
import getpass
import subprocess

# ------------------------------------------------------------------------------
# 1. PAM C API Authentication Engine (with persistent callback & libc allocations)
# ------------------------------------------------------------------------------
libpam = None
libc = None

try:
    libpam_path = ctypes.util.find_library('pam') or 'libpam.so.0'
    libpam = ctypes.CDLL(libpam_path)
    libc = ctypes.CDLL(None)
    libc.calloc.restype = ctypes.c_void_p
    libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]
    libc.strdup.restype = ctypes.c_void_p
    libc.strdup.argtypes = [ctypes.c_char_p]
except Exception:
    libpam = None

class PamMessage(ctypes.Structure):
    _fields_ = [('msg_style', ctypes.c_int), ('msg', ctypes.c_char_p)]

class PamResponse(ctypes.Structure):
    _fields_ = [('resp', ctypes.c_void_p), ('resp_retcode', ctypes.c_int)]

PamConvFunc = ctypes.CFUNCTYPE(
    ctypes.c_int,
    ctypes.c_int,
    ctypes.POINTER(ctypes.POINTER(PamMessage)),
    ctypes.POINTER(ctypes.POINTER(PamResponse)),
    ctypes.c_void_p
)

class PamConv(ctypes.Structure):
    _fields_ = [('conv', PamConvFunc), ('appdata_ptr', ctypes.c_void_p)]

def _py_pam_conv(n_messages, messages, p_response, appdata_ptr):
    if not appdata_ptr or not libc:
        return 19 # PAM_CONV_ERR
    arr = libc.calloc(n_messages, ctypes.sizeof(PamResponse))
    responses = ctypes.cast(arr, ctypes.POINTER(PamResponse))

    for i in range(n_messages):
        msg = messages[i].contents
        if msg.msg_style in (1, 2): # PAM_PROMPT_ECHO_OFF or PAM_PROMPT_ECHO_ON
            p_bytes = ctypes.cast(appdata_ptr, ctypes.c_char_p).value
            if p_bytes:
                responses[i].resp = libc.strdup(p_bytes)
                responses[i].resp_retcode = 0

    p_response[0] = responses
    return 0

# Store persistent C-callback function reference to prevent GC cleanup
GLOBAL_PAM_CONV_FUNC = PamConvFunc(_py_pam_conv)

def verify_via_libpam(username, password):
    if not libpam or not libc:
        return False

    pwd_bytes = password.encode('utf-8')
    pwd_buf = ctypes.c_char_p(pwd_bytes)
    conv = PamConv(GLOBAL_PAM_CONV_FUNC, ctypes.cast(pwd_buf, ctypes.c_void_p))

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

# ------------------------------------------------------------------------------
# 2. Sudo Authentication Engine (Fallback for user password validation)
# ------------------------------------------------------------------------------
def verify_via_sudo(username, password):
    try:
        # Reset sudo timestamp cache first so sudo always asks for password
        subprocess.run(['sudo', '-k'], capture_output=True, timeout=2)

        # Validate password via sudo -S -v
        proc = subprocess.Popen(
            ['sudo', '-S', '-v'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        pwd_bytes = (password + '\n').encode('utf-8')
        _, _ = proc.communicate(input=pwd_bytes, timeout=3)
        return (proc.returncode == 0)
    except Exception:
        return False

# ------------------------------------------------------------------------------
# 3. Su Authentication Engine (Fallback for user password validation)
# ------------------------------------------------------------------------------
def verify_via_su(username, password):
    try:
        proc = subprocess.Popen(
            ['su', '-c', 'true', username],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        pwd_bytes = (password + '\n').encode('utf-8')
        _, _ = proc.communicate(input=pwd_bytes, timeout=3)
        return (proc.returncode == 0)
    except Exception:
        return False

def verify_password(username, password):
    if not password:
        return False

    # 1. Primary method: C libpam API
    if verify_via_libpam(username, password):
        return True

    # 2. Fallback method: Sudo password validation
    if verify_via_sudo(username, password):
        return True

    # 3. Fallback method: Su password validation
    if verify_via_su(username, password):
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

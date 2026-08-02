#!/usr/bin/env python3
import sys
import os
import ctypes
import ctypes.util
import getpass

libpam = None
try:
    libpam_path = ctypes.util.find_library('pam') or 'libpam.so.0'
    libpam = ctypes.CDLL(libpam_path)
except Exception:
    libpam = None

libc = ctypes.CDLL(None)

class PamMessage(ctypes.Structure):
    _fields_ = [('msg_style', ctypes.c_int), ('msg', ctypes.c_char_p)]

class PamResponse(ctypes.Structure):
    _fields_ = [('resp', ctypes.c_char_p), ('resp_retcode', ctypes.c_int)]

CONV_FUNC = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.POINTER(PamMessage)), ctypes.POINTER(ctypes.POINTER(PamResponse)), ctypes.c_void_p)

class PamConv(ctypes.Structure):
    _fields_ = [('conv', CONV_FUNC), ('appdata_ptr', ctypes.c_void_p)]

def verify_password(username, password):
    if not password:
        return False
    if not libpam:
        return False

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

    for service in ['system-auth', 'login', 'passwd', 'kde', 'sddm', 'gdm', 'su', 'shadow']:
        pamh = ctypes.c_void_p()
        res = libpam.pam_start(service.encode('utf-8'), username.encode('utf-8'), ctypes.byref(conv), ctypes.byref(pamh))
        if res == 0:
            auth_res = libpam.pam_authenticate(pamh, 0)
            libpam.pam_end(pamh, auth_res)
            if auth_res == 0:
                return True
    return False

def main():
    if len(sys.argv) < 2:
        # Read from stdin
        password = sys.stdin.read().strip()
    else:
        password = sys.argv[1].strip()

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

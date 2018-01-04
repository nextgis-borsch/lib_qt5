#!/usr/bin/env python
# -*- coding: utf-8 -*-
################################################################################
##
## Project: NextGIS Borsch build system
## Author: Dmitry Baryshnikov <dmitry.baryshnikov@nextgis.com>
## Author: Maxim Dubinin <maim.dubinin@nextgis.com>
## Copyright (c) 2016 NextGIS <info@nextgis.com>
## License: GPL v.2
##
################################################################################

import os
import shutil
import string
import subprocess
import sys
import multiprocessing
import glob

install_dir = 'inst'

def run(args):
    print 'calling ' + string.join(args)
    try:
        subprocess.check_call(args)
        return True
    except subprocess.CalledProcessError, e:
        return False

if sys.platform != 'darwin':
    exit('Mac OS X only supported')
# Qt libraries put to the <NextGIS>/Library/Frameworks/Qt<Core,Gui, etc>.framework
# Qt plugins put to the <NextGIS>/Library/plugins/<4>/<codecs,sqldrivers, etc.>/*.dylib
repo_root = os.getcwd()
qt_path = os.path.join(repo_root, install_dir)
qt_install_lib_path = os.path.join(qt_path, 'lib')
files = glob.glob(qt_install_lib_path + "/*.framework")
lib_rpaths = []
for f in files:
    if os.path.isdir(f):
        lib_name = os.path.splitext(os.path.basename(f))[0]
        lib_path = os.path.realpath(os.path.join(f, lib_name))
        lib_rpath = os.path.join(lib_name + '.framework', os.path.relpath(lib_path, start=f))
        run(('install_name_tool', '-id', '@rpath/' + lib_rpath, lib_path))
        lib_rpaths.append(lib_rpath)

for f in files:
    if os.path.isdir(f):
        lib_name = os.path.splitext(os.path.basename(f))[0]
        lib_path = os.path.realpath(os.path.join(f, lib_name))
        for rpath in lib_rpaths:
            run(('install_name_tool', '-change', rpath, '@rpath/' + rpath, lib_path))
# plugins
qt_install_plg_path = os.path.join(qt_path, 'plugins')
files = glob.glob(qt_install_plg_path + "/*/*.dylib")
for f in files:
    if not os.path.isdir(f):
        lib_name = os.path.basename(f)
        run(('install_name_tool', '-id', '@rpath/' + lib_name, f))
        run(('install_name_tool', '-add_rpath', '@loader_path/../../../Frameworks/', f)) #/plugins/4/crypto
        for rpath in lib_rpaths:
            run(('install_name_tool', '-change', rpath, '@rpath/' + rpath, f))

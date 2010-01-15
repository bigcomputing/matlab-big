#!/usr/bin/env python
#
# A packaging script for NetWorkSpaces MATLAB
#
import sys, os, shutil

def copyDir():
    for file in os.listdir("."):
        if file in file_list:
            shutil.copy(file, dest)
        elif file in dir_list:
            destDir = dest + "/" + file
            shutil.copytree(file, destDir)

def removeCVS(path):
    for file in os.listdir(path):
        file_or_dir = os.path.join(path, file)
        if file == "CVS":
            shutil.rmtree(file_or_dir) # remove entire CVS directory without visiting
        elif os.path.isdir(file_or_dir) and not os.path.islink(file_or_dir):
            removeCVS(file_or_dir)

def check():
    for file in file_list:
        if not os.path.exists(dest + "/" + file):
            print "ERROR: " + file +  " file cannot be found"
            sys.exit(1)
    for dir in dir_list:
        if not os.path.exists(dest + "/" + dir):
            print "ERROR: " + dir + " directory cannot be found"
            sys.exit(1)

# initializing data
nt_ext = ".mexw32"
linux_ext = ".mexglx"
maci_ext = ".mexmaci"

nwsMex = "nwsMex"
release_version = "1.4"
dest = "nws_matlab_" + release_version
dist = "dist"
if os.name == "nt":
    mexBinary = nwsMex + nt_ext
    tarCmd = "zip -r"
    tarball = dest + ".zip"
elif sys.platform == 'darwin':
    mexBinary = nwsMex + maci_ext
    tarCmd = "tar czvf"
    tarball = dest + ".tar.gz"
else:
    mexBinary = nwsMex + linux_ext
    tarCmd = "tar czvf"
    tarball = dest + ".tar.gz"

file_list = ["babelfish.m", "barrierNames.m", "cmdLaunch.m", "envcmd.m", "launch.m",
	"lsfcmd.m", "rshcmd.m", "sshcmd.m", "scriptcmd.m", "workerLoop.m", 
	"INSTALL", "README", "README.sleigh", mexBinary]
dir_list = ["@netWorkSpace", "@nwsServer", "@sleigh", "@sleighPending",
	"bin", "doc", "examples"]

if os.path.exists(dest):
    print "Deleting", dest
    shutil.rmtree(dest)

os.mkdir(dest)
if not os.path.exists(dist):
    os.mkdir(dist)

# real work
copyDir()
removeCVS(dest)

# make sure all necessary files are in the package 
check()
cmd = tarCmd + " " + tarball + " " + dest
print "Executing command:", cmd
os.system(tarCmd + " " + tarball + " " + dest)  # make a tarball

# clean up
shutil.move(tarball, dist) 
shutil.rmtree(dest)  # remove temp directory

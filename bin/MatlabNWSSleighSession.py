#!/usr/bin/env python
#
# Copyright (c) 2005-2008, REvolution Computing, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import sys, os, tempfile, traceback
from os import environ as Env

try:
    import win32api
    _winuser = win32api.GetUserName()
except ImportError:
    _winuser = None

if sys.platform.startswith('win'):
    _TMPDIR = tempfile.gettempdir() or '\\TEMP'
else:
    _TMPDIR = tempfile.gettempdir() or '/tmp'

def addMatlabPath(*d):
    matlabpath = Env.get('MATLABPATH')
    print "old MATLABPATH:", matlabpath
    if matlabpath:
        matlabpath = os.pathsep.join(d + (matlabpath,))
    else:
        matlabpath = os.pathsep.join(d)
    print "new MATLABPATH:", matlabpath
    Env['MATLABPATH'] = matlabpath

def main():
    # initialize variables from environment
    modulePath = Env.get('MatlabSleighNwsPath', '')
    logDir = Env.get('MatlabSleighLogDir', _TMPDIR)
    outfile = Env.get('MatlabSleighWorkerOut')
    if outfile:
        outfile = os.path.join(logDir, os.path.split(outfile)[1])
    nwsPath = Env.get('MatlabSleighNwsPath')
    nwsName = Env['MatlabSleighNwsName']
    nwsHost = Env.get('MatlabSleighNwsHost', 'localhost')
    nwsPort = int(Env.get('MatlabSleighNwsPort', '8765'))
    print nwsName, nwsHost, nwsPort

    print "executing Matlab worker"
    mprog = Env.get('MatlabProg', 'matlab')
    rcmd = 'cmdLaunch'
    if nwsPath:
        if sys.platform.startswith('win'):
            # XXX this may be a bad idea, but I'll give it a shot
            rcmd = "addpath('%s');cmdLaunch" % nwsPath
        else:
            # setting the MATLABPATH environment variable causes
            # big problems on Windows, but seems to work on Unix
            addMatlabPath(nwsPath)
    argv = [mprog, '-r', rcmd, '-nodesktop', '-nosplash', '-nojvm']
    if sys.platform.startswith('win'):
        argv += ['-minimize']
    else:
        argv += ['-nodisplay']
    if outfile: argv += ['-logfile', outfile]
    try:
        # XXX Python 2.4 is currently required for Windows (but not gracefully enforced)
        print "attempting to use subprocess.Popen with argv:", argv
        import subprocess
        p = subprocess.Popen(argv, stdin=open(os.path.devnull))
        if hasattr(p, '_handle'):
            wpid = int(p._handle)  # Windows
        else:
            wpid = p.pid  # Unix
        print "subprocess.Popen appears to have worked"
    except ImportError:
        print "python version:"
        print sys.version
        print "attempting to use os.spawnvp due to import error"
        wpid = os.spawnvp(os.P_NOWAIT, argv[0], argv)
        print "os.spawnvp appears to have worked"

    print "waiting for shutdown"
    sys.path[1:1] = modulePath.split(os.pathsep)

    try:
        from nws.client import NetWorkSpace
    except ImportError:
        from nwsclient import NetWorkSpace
    nws = NetWorkSpace(nwsName, nwsHost, nwsPort, useUse=True, create=False)
    sentinel(nws)

    print "killing Matlab worker"
    kill(wpid)

    print "all done"

    # just being paranoid
    sys.stdout.flush()
    sys.stderr.flush()

def getenv(args):
    e = {}
    for kv in args:
        try:
            k, v = [x.strip() for x in kv.split('=', 1)]
            if k: e[k] = v
        except:
            print "warning: bad argument:", kv
    return e

def setup(f):
    if os.path.isabs(f):
        log = f
    else:
        log = os.path.join(Env.get('MatlabSleighLogDir', _TMPDIR), f)

    # open the output file and redirect stdout and stderr
    try:
        # create an unbuffered file for writing
        outfile = open(log, 'w', 0)
        sys.stdout = outfile
        sys.stderr = outfile
    except:
        traceback.print_exc()
        print "warning: unable to create file:", log

    # cd to the specified directory
    wd = Env.get('MatlabSleighWorkingDir', _TMPDIR)
    if not os.path.isdir(wd):
        wd = _TMPDIR

    try:
        os.chdir(wd)
    except:
        traceback.print_exc()
        print "warning: unable to cd to", wd

    # this information will normally seem rather obvious
    print "current working directory:", os.getcwd()

def sentinel(nws):
    print "waiting for sleigh to be stopped"

    try:
        nws.find('Sleigh ride over')
        nws.store('bye', 'Sleigh ride over')
    except:
        try: nws.store('bye', str(sys.exc_info()[1]))
        except: pass

    print "sentinel returning"

def kill(pid):
    try:
        try:
            import win32api
            # the "pid" is really a handle on Windows
            win32api.TerminateProcess(pid, -1)
            win32api.CloseHandle(pid)  # XXX not sure about this
        except ImportError:
            try:
                from signal import SIGTERM as sig
            except ImportError:
                print "couldn't import signal module"
                sig = 15
            os.kill(pid, sig)
    except OSError:
        # process is already dead, so ignore it
        pass
    except:
        traceback.print_exc()

if __name__ == '__main__':
    try:
        # treat all arguments as environment settings
        Env.update(getenv(sys.argv[1:]))

        # user name is used in log file name to avoid permission problems
        user = Env.get('USER') or Env.get('USERNAME') or \
                _winuser or 'nwsuser'
        f = 'MatlabSleighSentinelLog_' + user + '_' + \
                Env.get('MatlabSleighID', 'X') + '.txt'
        setup(f)

        if not Env.has_key('MatlabSleighNwsName'):
            print "MatlabSleighNwsName variable is not set"
            print >> sys.__stderr__, "MatlabSleighNwsName variable is not set"
        else:
            main()
    except:
        traceback.print_exc()

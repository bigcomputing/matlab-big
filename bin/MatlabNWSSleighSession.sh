#!/bin/sh
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

MatlabProg=${MatlabProg:-'matlab'}
cd ${MatlabSleighWorkingDir:-'/tmp'}
LogDir=${MatlabSleighLogDir:-'/tmp'}
if [ -n "${MatlabSleighWorkerOut}" ]; then
    WorkerOut=${LogDir}/`basename "${MatlabSleighWorkerOut}"`
else
    WorkerOut='/dev/null'
fi

# compute engine
$MatlabProg -nosplash -nodesktop -nodisplay -nojvm <<'EOF' > ${WorkerOut} 2>&1 &

nwsPath = getenv('MatlabSleighNwsPath');
addpath(nwsPath);
cmdLaunch
EOF

MatlabCEPid=$!
MatlabCEHost=`hostname`
export MatlabCEPid MatlabCEHost

# sentinel
USERID=`id -u`
$MatlabProg -nosplash -nodesktop -nodisplay -nojvm <<EOF > ${LogDir}/MatlabSleighSentinelLog_${USERID}_${MatlabSleighID} 2>&1

nwsPath = getenv('MatlabSleighNwsPath');
addpath(nwsPath);

cePid = getenv('MatlabCEPid');
ceHost = getenv('MatlabCEHost');

% put two descriptions of the worker in the netWorkSpace:

% one is a variable whose name conveys the basics, the other is
% a structure with more details assigned as a value to the variable 'wInfo'.

opt.useUse = 1;
opt.host = getenv('MatlabSleighNwsHost');
opt.port = sscanf(getenv('MatlabSleighNwsPort'), '%d');
nws = netWorkSpace(getenv('MatlabSleighNwsName'), opt);
store(nws, sprintf('Worker %s on %s', cePid, ceHost), 1);
wInfo.hostname = ceHost;
wInfo.pid = cePid;
wInfo.pwd = pwd;
wInfo.id = getenv('MatlabSleighID');
wInfo.version = version;
store(nws, 'worker info', wInfo);

try
  find(nws, 'Sleigh ride over');
  system(sprintf('kill %s', cePid));  
  store(nws, 'bye', 1);
catch
  % hmmm ... looks like the rug was pulled out from under us. wait a
  % bit for the shell scripts trap to fire ...
  pause(3)
  % still here?, kill the subjob (still a possible race here...)
  system(sprintf('kill %s', cePid));  
  store(nws, 'bye', 101);
end

EOF

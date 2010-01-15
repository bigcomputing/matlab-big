function launch(nwsName, nwsHost, nwsPort, maxWorkerCount, name, verbose)
% LAUNCH starts a sleigh worker
%
% launch(nwsName, nwsHost, nwsPort, maxWorkerCount, name, verbose) is
% to be executed from the sleigh worker script, via
% cmdLaunch, but it can also be executed manually, using a command
% that was copied from the value of the 'runMe' variable in the sleigh
% workspace (this is refered to as 'web launch').
%
% Arguments:
% nwsName -- Name of the sleigh workspace.
% nwsHost -- Host name of the NWS server used by the sleigh master.
%            The default value is 'localhost'.
% nwsPort -- Port number of the NWS server used by the sleigh master.
%            The default value is 8765.
% maxWorkerCount -- The maximum number of workers that should register
%            themselves.  The default value is -1, which means there is
%            no limit, but that primarily intended for support 'web
%            launch'.
% name -- Name to use for monitoring/display purposes.  The default
%            value is the fully qualified domain name of the local
%            machine.
% verbose -- Boolean flag used for displaying debug messages.  The
%            default value is 0.

% Copyright 2006-2008 REvolution Computing, Inc. 
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%

if nargin < 1; error('please provide workspace name'); end
if nargin < 2; nwsHost = 'localhost'; end
if nargin < 3; nwsPort = 8765; end
if nargin < 4; maxWorkerCount = -1; end
if nargin < 5 
  [status, name] = system('hostname'); 
  if status
    error('cannot get master''s machine name');
  end
  name = strtrim(name);
end
if nargin < 6; verbose = 0; end
  
opt.useUse = 1;
opt.host = nwsHost;
opt.port = nwsPort;
nws = netWorkSpace(nwsName, opt);
rank = fetch(nws, 'rankCount');

if (rank < 0) 
  store(nws, 'rankCount', rank);
  error('rankCount < 0');
  return;
elseif ((maxWorkerCount >= 0) && (rank+1 >= maxWorkerCount))
  % maxWorkerCount should not be zero, unless user calls launch manually
  store(nws, 'workerCount', maxWorkerCount);
  store(nws, 'rankCount', -1);
else
  store(nws, 'rankCount', rank + 1);
end

% initialize for monitoring
displayName = sprintf('%s@%d', name, rank);
declare(nws, displayName, 'single');
store(nws, displayName, '0');
nodeList = fetch(nws, 'nodeList');

if (length(nodeList) == 0)
  nodeList = displayName;
else
  nodeList = [nodeList ' ' displayName];
end
  
store(nws, 'nodeList', nodeList);

% post some info about this worker
info.host = name;
info.computer = computer;
info.matlab = version;
info.rank = rank;
info.workingDir = pwd;
info.logDir = getenv('MatlabSleighLogDir');
store(nws, 'worker info', info);

% wait for all workers to join
workerCount = find(nws, 'workerCount');

% enter the main worker loop
workerLoop(nws, displayName, rank, workerCount, verbose);

end

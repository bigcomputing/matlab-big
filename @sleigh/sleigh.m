function s = sleigh(sOpts)
% SLEIGH class constructor
%
% s = sleigh(nodeNames, sOpts) start remote matlab processes
% used to execute tasks. 
%  
% Arguments:
% sOpts -- an optional structure of fields. 
%   nodeList -- a cell array of hosts on which to execute
%     workers. One worker process is started for each of the 
%     host names in the cell array. The default value is 
%     {'localhost', 'localhost', 'localhost'}, which starts up two workers
%     on local machine. nodeList is irrelevant for local launch
%     and web launch.
%   workerCount -- a number indicating how many workers will be
%     created. Default value is 3. This variable is only relevant
%     to local launch.
%   nwsHost: netWorkSpace server host name. Default is local machine.
%   nwsPort: netWorkSpace server port. Default port is 8765.
%   nwsPath: directory path of where nws package is installed on
%     worker nodes. Default is set to the parent directory of '@sleigh'.
%   outfile: all remote workers' output will be redirected to this
%     file, if verbose mode is set. By default, this field does not exist. 
%   launch: mechanism to launch workers. Four mechanisms are supported:
%     ssh , rsh, web, and local. For local and web, set launch to a string, ''local''
%     and ''web'' respectively. For ssh and rsh, set launch to an anonymous function,
%     @sshcmd and @rshcmd respectively.
%     By default, local launch is used to start workers.
%   scriptDir: directory where matlab worker script is stored. 
%     Default is set to the bin directory under the parent directory of '@sleigh'.
%     This field is irrelevant for web launch. 
%   scriptName: script file name. Default is MatlabNWSSleighSession.sh
%   user: user name to use for remote execution of workers. This
%     argument may be ignored, depending on the launch type.
%     Default is the value set by environment variable, USER, on
%     the sleigh master. 
%   workingDir: define remote workers'' working directory. 
%     By default, this field does not exist. 
%     This field is also irrelevant for web launch.
%   logDir: define the directory where log files are stored.
%     By default, this field does not exist.  This field is also
%     irrelevant for web launch.
%   wsNameTemplate: template for the sleigh workspace name. This
%     must be a legal 'format' string, containing only an integer
%     format specifier. The default is 'sleigh_ride_%04d'.
%   verbose: verbose mode (0 or 1). Default value is 0. 

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

if nargin < 1;	sOpts.foo = 0;	end
s.status = 0;

% fill in various defaults if info not provided
sOptsd = defaultSleighOptions();
dfnames = fieldnames(sOptsd);
for x = 1:length(dfnames)
  fn = dfnames{x};
  if ~isfield(sOpts, fn)
    sOpts.(fn) = sOptsd.(fn);
  end
end

% master barrier out of phase wrt to session barrier.
[s.barrierNames, s.barrierCount] = barrierNames();
s.bxfh = bxGen(s.barrierCount);
s.busyfh = busyGen();

s.server = nwsServer(sOpts.nwsHost, sOpts.nwsPort);
s.nwsName = mktempWs(s.server, sOptsd.wsNameTemplate);

% duplicate nwsName information, so we can pass it to addWorker
sOpts.nwsName = s.nwsName;
s.nws = openWs(s.server, s.nwsName);

s.rankCount = 0;
s.nodeList = {};

% make options field accessible to other sleigh functions
s.options = sOpts;

% initialize for monitoring
global totalTasks
totalTasks = 0;
declare(s.nws, 'nodeList', 'single');
store(s.nws, 'nodeList', '');
declare(s.nws, 'totalTasks', 'single');
store(s.nws, 'totalTasks', '0');

declare(s.nws, 'rankCount', 'single');
store(s.nws, 'rankCount', s.rankCount);
declare(s.nws, 'workerCount', 'single');

if (isa(s.options.launch, 'function_handle'))
  s.nodeList = s.options.nodeList;
  s.workerCount = length(s.nodeList);
  for i = 1:s.workerCount
    % if names is a list of node/rsh/user trips, we could customize
    % access per machine here... (nwsPath may also have to change... )

    % should be more careful about use preferences for outfile ...
    if (s.options.verbose)
      s.options.outfile = sprintf('%s_%04d.txt', s.nwsName, i);
    end
    addWorker(s.nodeList{i}, i, s.workerCount, s.options)
  end
elseif (strcmp(s.options.launch, 'local'))
  s.workerCount = s.options.workerCount;
  for i = 1:s.workerCount
    s.nodeList{i} = 'localhost';
  end
  for i = 1:s.workerCount
    if (s.options.verbose)
      s.options.outfile = sprintf('%s_%04d.txt', s.nwsName, i);
    end
    addWorker(s.nodeList{i}, i, s.workerCount, s.options)
  end
elseif (strcmp(s.options.launch, 'web'))
  store(s.nws, 'runMe', sprintf('launch(''%s'', ''%s'', %d);',...
				s.nwsName, s.options.nwsHost, s.options.nwsPort));
  % try-catch block
  try
    fetch(s.nws, 'deleteMeWhenAllWorkersStarted');
  end
  deleteVar(s.nws, 'runMe');
  s.workerCount = fetch(s.nws, 'rankCount');
  store(s.nws, 'workerCount', s.workerCount);
  store(s.nws, 'rankCount', -1);
  s.rankCount = -1;
else
  error('unknown launch protocol');
end

s = class(s, 'sleigh');
end

function addWorker(machine, id, workerCount, sOpts)

env = [ ...
    ' MatlabSleighNwsHost="' sOpts.nwsHost '"' ...
    ' MatlabSleighNwsName="' sOpts.nwsName '"' ...    
    ' MatlabSleighNwsPort="' int2str(sOpts.nwsPort) '"' ...
    ' MatlabSleighName="' machine '"' ...
    ' MatlabSleighID="' int2str(id) '"' ...
    ' MatlabSleighWorkerCount="' int2str(workerCount) '"' ...
    ' MatlabSleighScriptDir="' sOpts.scriptDir '"' ...
    ' MatlabSleighScriptName="' sOpts.scriptName '"' ...
    ' MatlabSleighNwsPath="' sOpts.nwsPath '"' ...
    ' MatlabProg="' sOpts.matlabprog '"' ...
    ];

if (isfield(sOpts, 'outfile'))
  env = [env ' MatlabSleighWorkerOut="' sOpts.outfile '"'];
end

if (isfield(sOpts, 'workingDir'))
  env = [env ' MatlabSleighWorkingDir="' sOpts.workingDir '"'];
end

if (isfield(sOpts, 'logDir'))
  env = [env ' MatlabSleighLogDir="' sOpts.logDir '"'];
end


% remote execution command
if (isa(sOpts.launch, 'function_handle'))
  launchCmd = sOpts.launch(machine, sOpts);
else
  launchCmd = '';
end
scriptCmd = sOpts.scriptExec(machine, env, sOpts);
cmd = [launchCmd ' ' scriptCmd '&'];

if (sOpts.verbose)
  disp(cmd);
end

system(cmd);
end


% funky or freaky???
function h = bxGen(limit)
h = @bxStepper;
x = 1;
  function c = bxStepper()
  c = x;
  x = mod(x,limit) + 1;
  end
end


function h = busyGen()
h = @busy;
state = 0;
  function x = busy(op)
    if strcmp(op, 'clear'); state = 0; end
    if strcmp(op, 'query'); end
    if strcmp(op, 'set'); state = 1; end
    x = state;
  end
end


function x = defaultSleighOptions()
[status, hostname] = system('hostname');
if (status); error('failed to get host name'); end
x.nwsHost = sprintf('%s', strtrim(hostname));
pkg_path = mfilename('fullpath'); % get the full path of this file, sleigh.m
index = regexp(pkg_path, '@sleigh'); % trim the @sleigh directory off the path
if isempty(index)
  error('cannot find @sleigh directory');
end
x.nwsPath = pkg_path(1:index-2);
x.nwsPort = 8765;
x.scriptDir = fullfile(x.nwsPath, 'bin');
x.launch = 'local';

% the Python version is now the default for Unix platforms, as well as Windows
if 1
  x.scriptExec = @scriptcmd;
  x.scriptName = 'MatlabNWSSleighSession.py';
else
  x.scriptExec = @envcmd;
  x.scriptName = 'MatlabNWSSleighSession.sh';
end
x.workingDir = pwd;
x.user = getenv('USER');  % XXX may not work on Windows
x.wsNameTemplate = 'sleigh_ride_%04d';
x.verbose = 0;
x.workerCount = 3;
x.nodeList = {'localhost', 'localhost', 'localhost'};
x.matlabprog = matlabprog;
end


function m = matlabprog()
% XXX does this work on Windows, or does it need an extension?
m = fullfile(matlabroot, 'bin', 'matlab');
if exist(m) ~= 2
  m = '';
end
end

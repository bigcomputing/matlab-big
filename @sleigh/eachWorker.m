function x = eachWorker(s, toDo, varargin)
% EACHWORKER evaluates function exactly once for each worker in sleigh, s. 
%
% The results are normally returned as a cell array of cell array.
% However, if blocking field of execOptions is set to 0, then
% a sleighPending object is returned.
%
% The only required arguments are s, and toDo.
% The rest are optional arguments. 
%
% Arguments:
% s -- a sleigh class object.
%
% toDo -- function or expressions to be evaluated by sleigh workers. 
%   toDo must be a function name  (for 'invoke' and 'define' type) or 
%   expressions (for 'eval' type) in quotes. 
%  
% varargin --  fixed arguments/constants, and/or a structure of optional
%   arguments.  Optional arguments have to be after fixed arguments.
%   See execOptions below for more details on optional arguments.
%
%   Example:
%
%      eachWorker(s, @init)
%
%   will invoke the 'init' function on all workers without any arguments.
%
%      eachWorker(s, @init2, 1, 2)
%
%   will invoke the 'init2' function on all workers with two arguments.
%
% execOptions -- an optional structure of fields.
%   type: determines the type of function invocation to perform. This
%     can be 'invoke', 'define', or 'eval'. Default type is 'invoke'. 
%     If type is 'invoke' or 'define', then toDo argument must be a 
%     valid M function name. If type is 'eval', then toDo argument 
%     is evaluated as is. 
%
%   blocking: determines whether to wait for the results, or to reurn
%     as soon as the tasks have submitted. Default value is set to 1,
%     which means eachWorker is blocked until all tasks are completed. 
%     If value is set to 0, then eachWorker returns immediately with a 
%     sleighPending object that is used to monitor the status of the 
%     tasks, and eventually used to retrieve results. 
%     You must wait for the results to be completed before submitting
%     more tasks to the sleigh workspace.
%
% Example:
%   opts.blocking = 0
%   eachWorker(s, @init2, 1, 2, opts)   

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

if s.busyfh('query')
  error('wait your turn.');
end

if nargin < 2
  error('incorrect arguments')
end

if nargin == 2 || ~isstruct(varargin{end})
  execOptions.type = 'invoke'; 
  wl = length(varargin);
else
  execOptions = varargin{end};
  wl = length(varargin) - 1;
  if wl < 0
    wl = 0;
  end
end  

t.argCA = cell(wl, 1);

if wl > 0
  t.argCA(1:end) = varargin(1:wl);
end

try
  blocking = execOptions.blocking;
catch
  blocking = 1;
end

try
  t.type = execOptions.type;
catch
  t.type = 'invoke';
end

bx = s.bxfh();
bn = s.barrierNames{bx};

fetchTry(s.nws, bn);

%  update the total number of submitted tasks
global totalTasks;
totalTasks = totalTasks + s.workerCount;
store(s.nws, 'totalTasks', num2str(totalTasks));

if strcmp(t.type, 'invoke') 
  if isa(toDo, 'function_handle')
    t.funcName = func2str(toDo);
  elseif ischar(toDo)
    t.funcName = toDo;
  else
    error('toDo argument must be a string of function handle');
  end
elseif strcmp(t.type, 'define')
  t.funcName = toDo;
  % probably should appeal to m's path resolution mechanism here.
  try 
    fid = fopen([toDo '.m']);
    t.code = fread(fid, inf, '*char');
    fclose(fid);
  catch
    error('cannot access code for function.');
  end
elseif strcmp(t.type, 'eval')
  t.code = toDo;
else
  error('unrecognized type');
end

for i = 1:s.workerCount
  t.barrier = 1;
  t.tag = i;
  store(s.nws, 'task', t);
end

if ~blocking
  s.busyfh('set');
  x = sleighPending(s.nws, s.workerCount, bn, s.busyfh);
  return
end
  
rVec = cell(1, s.workerCount);

for i = 1:s.workerCount
  r = fetch(s.nws, 'result');
  if ~iscell(r.value)
    display(r.value);
    error('result is not a cell array');
  end
  if size(r.value, 1) > size(rVec, 1)
    rVec{size(r.value, 1), 1} = [];
  end
  [rVec{:, r.tag}] = r.value{:};
end

store(s.nws, bn, 1);
x = rVec;

end

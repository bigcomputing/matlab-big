function workerLoop(nws, displayName, rank, workerCount, verbose)
% WORKERLOOP executes tasks submitted by eachElem and eachWorker

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

% these are declared global so that the user's code can make use of them too.
global SleighNws SleighRank SleighName SleighWorkerCount

% we use alternating barriers to synchronize eachNode runs.
[bNames, bCount] = barrierNames();
bx = 1;
SleighNws = nws;
SleighRank = rank;
SleighName = displayName;
SleighWorkerCount = workerCount;

scratchDir = [tempname '_' num2str(SleighRank)];

mkdir(scratchDir);
addpath(scratchDir);

% monitoring stuff goes here
tasks = 0;

while 1
  % update the number of tasks executed
  store(SleighNws, SleighName, num2str(tasks));
  
  sleighTask = fetch(SleighNws, 'task');

  % use to generate an informal log
  if (verbose)
    disp(sleighTask);
  end
  
  if ~isa(sleighTask, 'struct')
    if ischar(sleighTask) && strcmp(sleighTask, 'Sleigh ride over')       
      store(SleighNws, 'bye', 0);
    end
    break; 
  end

  r.tag = sleighTask.tag;
  r.rank = rank

  if strcmp(sleighTask.type, 'invoke')
    % If user made any changes to the worker's working directory,
    % we need to rehash it, otherwise, workers won't get updated changes
    % until the next time new sleigh is constructed.
    rehash;
  
    if sleighTask.funcName(1) == '@'
      nouts = 1;
      fhandle = eval(sleighTask.funcName);
    else
      try 
        nouts = nargout(sleighTask.funcName);
        fhandle = str2func(sleighTask.funcName);
      catch  
        % nargout cannot be done on built-in function before MATLAB 7.1 SP 3. 
        % check if we are invoking built-in function
        if exist(sleighTask.funcName, 'builtin')
          nouts = 1;  % Assume built-in function returns at least one value
          fhandle = str2func(sleighTask.funcName);
        else      
          err = lasterror;
          r.value = {['TASK FAILED: cannot access function: ' sleighTask.funcName ...
                      ', ' err.message]};
        end
      end
    end
 
    % Only evaluate the function, if variable nouts was defined. 
    % nouts was not defined, because of the exception thrown earlier. 
    if exist('nouts', 'var')
      try
        if (verbose)
	  disp(sleighTask.funcName);
        end

        % function does not return any value
        if nouts == 0 
          r.value = cell(1, 1);
          fhandle(sleighTask.argCA{1:end});
          r.value{1, 1} = ['function has no return value'];
        else
          r.value = cell(nouts, 1);
          [r.value{:}] = fhandle(sleighTask.argCA{1:end});
        end
      catch 
        err = lasterror;
        r.value{1, 1} = ['TASK FAILED: ' err.message];
      end
    end
  elseif strcmp(sleighTask.type, 'define')
    if isfield(sleighTask, 'code') 
    try 
        clear sleighTask.funcName % remove previous definitions.
        fid = fopen(fullfile(scratchDir, [sleighTask.funcName '.m']), 'w');
        fwrite(fid, sleighTask.code, 'char');
        fclose(fid);
        r.value = {0};
        % EXTRA PARANOIA?!
        % We don't need to rehash the function here, because it is guaranteed 
        % to be rehashed before function evaluation.
        % However, we still rehash here in case there will be a change of rehashing 
        % logic in the workerLoop, and we don't break anything. 
        rehash; 
      catch
        error('cannot access code for function.');
      end
    else 
      r.value = {['This should not happened. We didn''t get any code transferred']};
    end
  elseif strcmp(sleighTask.type, 'eval')
    % refresh any changes that user made to the working directory.
    rehash;

    if (verbose)
      disp(sleighTask.code);
    end

    try
      r.value = {eval(sleighTask.code)};
    catch
      err = lasterror;
      r.value = {['TASK FAILED: ' err.message]};
    end
  end

  store(SleighNws, 'result', r);

  if (verbose)
    disp(r);
  end
 
  tasks = tasks + 1;

  if sleighTask.barrier
    find(SleighNws, bNames{bx});
    bx = mod(bx, bCount) + 1;
  end

end   % end while loop

rmdir(scratchDir, 's');

end

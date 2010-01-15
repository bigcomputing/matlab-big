function stop(s)
% STOP remote worker processes and delete the sleigh workspace. 
%
% Arguments:
% s -- a sleigh class object

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

% signal workers stop looking for more tasks
store(s.nws, 'task', 'Sleigh ride over');

% signal sentinel that workers are exiting
store(s.nws, 'Sleigh ride over', 1);

pause(3);

if (isa(s.options.launch, 'function_handle'))
  exitCount = 0;
  while fetchTry(s.nws, 'bye', -1) ~= -1; exitCount = exitCount + 1; end

  if exitCount ~= s.workerCount
    disp(sprintf('Only %d of %d have exited.', exitCount, ...
                 s.workerCount))
  end
end
deleteWs(s.server, s.nwsName);

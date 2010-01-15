function x = check(sp)
% CHECK returns the number of results yet to be generated for the pending sleigh job, sp.
% If the job has already completed and the results have been gathered, 0 is returned.
%
% Arguments:
% sp -- sleighPending class object. This object is usually obtained from the return
%   value of non-blocking eachElem or non-blocking eachWorker.

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

if sp.donefh('query')
  % debatable
  x = 0;
  return
end

vl = listVars(sp.nws);

x = 0;

for i = 1:length(vl)
  if strcmp(vl(i).name, 'result')
    x = sp.count - vl(i).values;
    return
  end
end

x = vl(i).values;
end

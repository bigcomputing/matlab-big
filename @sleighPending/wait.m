function rVec = wait(sp)
% WAIT waits and blocks for the results to be completed for the pending sleigh job sp.
%   If the job has already completed, then wait returns
%   immediately with generated results.
%
% Arguments:
% sp -- a sleighPending class object. This object is usually obtained from the return
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
  error('results already gathered');
end

rVec = cell(1, sp.count);

for i = 1:sp.count
  r = fetch(sp.nws, 'result');
  if ~iscell(r.value)
    display(r.value);
    error('result is not a cell array');
  end
  if size(r.value, 1) > size(rVec, 1)
    rVec{size(r.value, 1), 1} = [];
  end
  [rVec{:, r.tag}] = r.value{:};
end

if sp.tickleBarrier
  store(sp.nws, sp.tickleBarrier, 1);
end

sp.busyfh('clear');
sp.donefh('set');

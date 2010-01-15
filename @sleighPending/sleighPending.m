function sp = sleighPending(nws, count, tb, busyfh)
% SLEIGHPENDING class constructor
%   sp = sleighPending(nws, count, tb, busyfh) creates a pending sleigh job, sp.
%
% Arguments:
% nws -- netWorkSpace class object.
% count -- number of tasks.
% tb -- names of the barrier to wait at when complete.
% busyfh -- object representing the current state of the sleigh

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

sp.tickleBarrier = tb;
sp.count = count;
sp.nws = nws;
sp.busyfh = busyfh;
sp.donefh = doneGen();
sp = class(sp, 'sleighPending');

end

function h = doneGen()
h = @done;
state = 0;
  function x = done(op)
    if strcmp(op, 'query'); ; end
    if strcmp(op, 'set'); state = 1; end
    x = state;
  end
end

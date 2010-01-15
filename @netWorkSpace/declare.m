function X = declare(nws, varName, mode)
% DECLARE a variable with a particular mode in a shared netWorkSpace.
%
% If varName has not already been declared in nws, the behavior
% of varName will be determined by mode. Mode can be 'fifo',
% 'lifo', 'multi', or 'single'. In the first three cases,
% multiple values can be associated with varName. When a value is
% retrieved for varName, the oldest value stored will be used in
% fifo' mode, the youngest in 'lifo' mode, and a
% nondeterministic choice will be made in 'multi' mode. In
% 'single' mode, only the most recent value is retained.
%
% Arguments:
% nws -- netWorkSpace class object.
% varName -- variable name.
% mode -- variable mode.

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

nwsMex('declare var', socket(server(nws)), nws.currentWs, varName, mode);

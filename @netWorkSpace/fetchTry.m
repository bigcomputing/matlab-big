function [X, F] = fetchTry(nws, varName, ifMissing, opts)
% FETCHTRY  attempts to fetch something from the shared netWorkSpace nws.
%
% fetchTry (nws, varName, ifMissing, opts) looks in the shared
% netWorkSpace nws for a value bound to varName.
%
% If found, remove a value associated with varName from nws and
% return it in X. Set F to true. This operation is atomic. If
% multiple DCT sessions fetch or fetchTry a given varName, any
% given value from the set of values associated with varName will
% be return to just one DCT session. If there is more than one
% value associated with varName, the particular value removed
% depends on varName's behavior. See store(nws, ...) for
% details.
%
% If not found, return the value of ifMissing in X and set F to
% false.
%
% If ifMissing is not given, 0 is used.
%
% Arguments:
% nws -- netWorkSpace class object.
% varName -- name of variable to fetch.
% ifMissing -- value to return if variable has no values.
% opts -- optional arguments

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

if (nargin < 4)
  opts = struct;
  if (nargin < 3)
    ifMissing = 0;
  end
end

try
  [X, F] = nwsMex('fetchTry', socket(server(nws)), nws.currentWs, ...
	          varName, ifMissing, opts);
catch
  X = ifMissing;
  F = false;
end


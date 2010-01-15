function X = fetch(nws, varName, opts)
% FETCH fetches something from the shared netWorkSpace nws.
%
% fetch(nws, varName) blocks until a value for varName is found in the shared
% netWorkSpace nws. Once found, remove a value associated with
% varName from the shared netWorkSpace and return it in X.
% This operation is atomic. If multiple Distributed Computing
% Toolbox sessions fetch or fetchTry a given varName, any given
% value from the set of values associated with varName will be
% return to just one DCT session. If there is more than one
% value associated with varName, the particular value removed
% depends on varName's behavior. See store(nws, ...) for
% details.
%
% Arguments:
%   nws -- netWorkSpace class object.
%   varName -- name of the variable to fetch.
%   opts -- optional arguments

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

if nargin < 3
  opts.foo = 0;
end
X = nwsMex('fetch', socket(server(nws)), nws.currentWs, varName, opts);

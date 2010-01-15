function name = mktempWs(nwss, wsNameTemplate)
% MKTEMPWS creates a unique, temporary workspace
%
% name = mktempWs(nwss, wsNameTemplate) returns the name of a
% temporary space created on the server reached by nwss. The
% template should contain a '%d'-like construct which will be
% replaced by a serial counter maintained by the server to
% generate a unique new workspace name. The use must then
% invoke openWs() with this name to create an object to access
% this workspace. wsNameTemplate defaults to 'matlab_ws_%010d'.
%
% Arguments:
% nwss -- nwsServer class object.
% wsNameTemplate -- template for the netWorkSpace name.

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

wnt = 'matlab_ws_%010d';
if nargin > 1
  wnt = wsNameTemplate;
end

name = nwsMex('mktemp ws', nwss.s, wnt);

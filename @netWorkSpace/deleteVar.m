function X = deleteVar(nws, varName)
% DELETEVAR deletes a variable from a shared netWorkSpace.
%
% Arguments:
% nws -- netWorkSpace class object.
% varName -- name of the variable to delete.

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

nwsMex('delete var', socket(server(nws)), nws.currentWs, varName);

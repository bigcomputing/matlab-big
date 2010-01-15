function nws = openWs(nwss, netWorkSpaceName, opts)
% OPENWS creates a netWorkSpace class object.
%
% openWs(nwss, netWorkSpaceName) creates a shared netWorkSpace
% object for the netWorkSpace named netWorkSpaceName (which must
% be a string).
%
% If the shared netWorkSpace does not exist, it will be created
% (upon first use) and claimed the ownership of the workspace.
% This can be useful as an arbitration mechanism.
% The output of listWss indicates which netWorkSpaces this
% matlab process created. These will be destroyed when this
% matlab process closes the connection to the netWorkSpace
% server that was used to create these spaces.
%
% Arguments:
% nwss -- nwsServer class object.
% netWorkSpaceName -- name of the netWorkSpace to open.
% opts -- a structure of optional fields.
%   persistent: boolean value indicating whether the space is
%     persistent or not. If the space is persistent (value of 1),
%     then the workspace is not purged when it is removed from the
%     server, nwss.
%   space: netWorkSpace class object to use open operation.
%     If this field is not speicified, then openWs will construct
%     a netWorkSpace class object on this nws server, nwss.

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

if nargin == 2
  opts.foo = 'foo'; % cheap initialization of structure.
end

if isfield(opts, 'space')
  nws = opts.space;
else
  opts.server = nwss;
  nws = netWorkSpace(netWorkSpaceName, opts);
end

if isfield(opts, 'persistent')
  p = 'yes';
else
  p = 'no';
end

nwsMex('open ws', nwss.s, netWorkSpaceName, p);

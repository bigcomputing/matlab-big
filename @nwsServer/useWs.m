function nws = useWs(nwss, netWorkSpaceName, opts)
% USEWS creates a netWorkSpace object, but not own it.
%
% useWs(nwss, netWorkSpaceName, opts) creates a shared netWorkSpace
% object for the netWorkSpace named netWorkSpaceName (which
% must be a string).
%
% If the shared netWorkSpace does not exist, it will be
% created but no owner associates with it.
%
% Arguments:
% nwss -- nwsServer class object.
% netWorkSpaceName -- name of the netWorkSpace to open.
% opts -- optional options
%   space: netWorkSpace object that represents the workspace that
%     client wants to 'use'. If this field is not speicified,
%     then useWs will construct a netWorkSpace class object on
%     this nws server, nwss.

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
  opts.useUse = 1;
  nws = netWorkSpace(netWorkSpaceName, opts);
end

nwsMex('use ws', nwss.s, netWorkSpaceName);

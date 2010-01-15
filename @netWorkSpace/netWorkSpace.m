function ws = netWorkSpace(wsName, h, p)
% NETWORKSPACE class constructor.
%
% ws = netWorkSpace(wsName, h, p) creates an object for the shared
% netWorkSpace wsName residing in the netWorkSpace server running on
% host h, port p. If host name and port number are not provided,
% then 'localhost' is used as default value for host name, and
% 8765 is used as default value for port.
%
% Arguments:
% wsName -- name of the workspace. There can only be one work space
%   on the server with a given name, so two clients can
%   easily communicate with each other by both creating a
%   netWorkSpace object with the same name on the same server.
% h -- server host name. Default value is 'localhost'.
% p -- server port. Default value is 8765.
% opts -- an optional structure of fields. If opts is presented,
%   it is assumed that an nws server object or host name and port number
%   is provided as part of structure field. Therefore, h and p
%   CANNOT be provided as part of arguments. h and p can ONLY
%   provided as part of opts fieldds.
%
%   Opts may contain these fields:
%   server: nwsServer class object. This field is not needed, if host
%   name and port number are provided.
%   host: server host name. Default value is 'localhost'.
%   port: server port. Default value is 8765.
%   pesistent: If true, make the workspace persistent.
%     A persistent workspace won't be purged when the owner
%     disconnects from the NWS server. Note that only the
%     client who actually takes ownership of the workspace
%     can make the workspace persistent. The persistent
%     argument is effectively ignored if useUse is true.
%   useUse: By default 'open' semantic is used when
%     creating a workspace (i.e., try to claim
%     ownership). If useUse is set to 1, 'use' semantic
%     applies, which means no ownership is claimed.

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

ws.currentWs =  '__default';

useHost = 'localhost';
usePort = 8765;
useUse = 0;
opts.foo = 12321; % cheap instantiation of an option structure

ws.currentWs = wsName;

needServer = 1;
if nargin == 1
  ;
elseif nargin == 2 && isstruct(h)
  opts = h;
  if isfield(opts, 'server')
    needServer = 0;
  end
  if isfield(opts, 'host')
    useHost = opts.host;
  end
  if isfield(opts, 'port')
    usePort = opts.port;
  end
  if isfield(opts, 'useUse')
    useUse = opts.useUse;
  end
elseif nargin == 3
  useHost = h;
  usePort = p;
else
  error('incorrect arguments')
end

% if invoked (indirectly) via a server openWs or useWs method,
% the server will be passed in and used. if invoked directly,
% need to create a new server instance.
if needServer
  ws.server = nwsServer(useHost, usePort);
  % now give the server a chance to do its thing.
  if useUse
    useWs(ws.server, wsName);
  else
    opts.space = ws;
    openWs(ws.server, wsName, opts);
  end
else
  % reuse an existing connection.
  ws.server = opts.server;
end

ws = class(ws, 'netWorkSpace');


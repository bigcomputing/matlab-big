function nwss = nwsServer(h, p)
% NWSSERVER class constructor.
%
% nwss = nwsServer(h, p) creates an object encapsulating a
% connection to the netWorkSpace server running on host h, port p
%
% Arguments:
% h -- server host name
% p -- server port number

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

nwss.h = 'localhost';
nwss.p = 8765;

if nargin > 0
  nwss.h = h;
end
if nargin > 1
  nwss.p = p;
end

nwss.s = nwsMex('connect', nwss.h, nwss.p);
nwss = class(nwss, 'nwsServer');

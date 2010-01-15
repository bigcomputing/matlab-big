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
%
% Ping-pong client

function status = pong()
loops = 3;
wsname = 'ping-pong';
ws = netWorkSpace(wsname);
    
game = fetch(ws, 'game');
store(ws, 'game', game+1);
sprintf('Starting a ping-pong game %d', game)

pong = ['pong' int2str(game)];

for i=1:loops, 
    store(ws, 'ping', pong);
    reply = fetch(ws, 'pong');  
    sprintf('%s', reply)
end
status=1;    
deleteVar(ws, pong)

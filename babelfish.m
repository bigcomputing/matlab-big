function babelfish(nwsHost, nwsPort)
% BABELFISH translates objects for the web interface

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

if nargin < 2
  nwsPort = 8765
  if nargin < 1
    nwsHost = 'localhost'
  end
end

bnws = netWorkSpace('Matlab babelfish', nwsHost, nwsPort);

while 1
  v = fetch(bnws, 'food');
  store(bnws, 'doof', evalc('disp(v)'));
end

end

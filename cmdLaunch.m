function cmdLaunch(verbose)
% CMDLAUNCH launches a sleigh worker by calling LAUNCH
%
% cmdLaunch(verbose) is only intended to be called internally by
% the MatlabNWSSleighSession.sh
%
% Arguments:
% verbose -- Boolean flag used for displaying debug messages.  The
%            default value is 0.

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

nwsHost = getenv('MatlabSleighNwsHost');
nwsPort = sscanf(getenv('MatlabSleighNwsPort'), '%d');
nwsName = getenv('MatlabSleighNwsName');

name = getenv('MatlabSleighName');
maxWorkerCount = sscanf(getenv('MatlabSleighWorkerCount'), '%d');

scriptDir = getenv('MatlabSleighScriptDir');
nwsPath = getenv('MatlabSleighNwsPath');
workerOut = getenv('MatlabSleighWorkerOut');

if nargin < 1
  verbose = 0;
  if ~isempty(workerOut)
    verbose = 1; 
  end
end

try 
  launch(nwsName, nwsHost, nwsPort, maxWorkerCount, name, verbose);
catch
  err = lasterror;
  disp(err.message);
end

exit;

end

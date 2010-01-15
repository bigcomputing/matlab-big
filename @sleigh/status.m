function [workerCount, flag] = status(s, closeGroup, timeout)
% STATUS returns the status of the worker group
%
% [workerCount, flag] = status(s, closeGroup, timeout)
%
% The status includes the number of workers that have joined the
% group so far, and a flag that indicates whether the group has
% been closed (meaning that no more workers can join). Normally,
% the group is automatically closed when all the workers that were
% listed in the construct have joined. However, this method allows
% you to force the group to close after the timeout expires. This
% can be particularly useful if you are running on a large number
% nodes, and some of the nodes are slow or unreliable. If some of
% the workers are never started, the group will never close, and no
% tasks will ever be executed. 

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

if nargin<1; error('Please provide at least one argument'); end
if nargin<2; closeGroup=0; end
if nargin<3; timeout=0; end

flag = 0;
workerCount = 0;
stdout = 1;

if (s.rankCount < 0) 
  % join phase completed before
  s.status = 1;
  workerCount = s.workerCount;
  flag = s.status;
else
  initialSleep = min(2.0, timeout);
  sleepTime = initialSleep;
  repeatedSleep = 1.0;
  tic;
  
  while (1)
    n = fetch(s.nws, 'rankCount');
    
    if (n < 0)
      % all workers joined
      if (s.options.verbose)
	fprintf(stdout, 'all %d worker(s) have started\n', s.workerCount);
      end
	
      if (s.workerCount ~= find(s.nws, 'workerCount'))
	error('value for workerCount is not consistent');
      end
      s.rankCount = -1;
      store(s.nws, 'rankCount', s.rankCount);
      s.status = 1;
      workerCount = s.workerCount;
      flag = s.status;
      break;
    else
      % three choices: close now, return not closed, or sleep and
      % try again
      elapsedTime = toc;
      if (elapsedTime >= timeout)
	% time is up, so either close the join, or return the
        % current status
	if (closeGroup)
	  if (s.options.verbose)
	    fprintf(stdout, 'closing group: %d worker(s)\n', n);
	  end	  
	  
	  s.workerCount = n;
	  store(s.nws, 'workerCount', s.workerCount);
	  s.rankCount = -1;
	  store(s.nws, 'rankCount', s.rankCount);
	  s.status = 1;
	  workerCount = s.workerCount;
	  flag = s.status;
	  break;
	else
	  if (s.options.verbose)
	    fprintf(stdout, 'group not formed: %d worker(s)\n', n);
	  end
	  
	  s.rankCount = n;
	  store(s.nws, 'rankCount', s.rankCount);
	  s.workerCount = s.rankCount;
	  s.status = 0;
	  workerCount = s.workerCount;
	  flag = s.status;
	  break;
	end
      else
	if (s.options.verbose)
	  fprintf(stdout, 'only %d worker(s): sleeping ...\n', n);
	end	
	s.rankCount = n;
	store(s.nws, 'rankCount', n);
	pause(sleepTime);
	sleepTime = repeatedSleep;
      end
    end
  end
end    

end

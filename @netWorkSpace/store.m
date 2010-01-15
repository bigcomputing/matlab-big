function store(nws, a0, a1, opts)
% STORE something in a netWorkSpace, nws.
%
% store(nws, varName, v) associates the value v with varName in the
% shared netWorkSpace nws, thereby making the value available to
% all the instances of MATLAB running in
% the current Distributed Computing Toolbox session.  v may be
% any MATLAB value -- matrix, structure, function handle, etc.
%
% If a mode has not already been set for varName, 'fifo' will be
% used (see declare(nws, ...)).
%
% If no variable name is given, then value v must itself be a variable,
% and the value v will be asssociated with the variable's name in
% the netWorkSpace nws.
%
% Example:
%     M = magic(5);
%     store(nws, M)
%   and
%     store(nws, 'M', magic(5))
%   do the same thing.
%
% Note that by default the mode is 'fifo', so store is not idempotent:
% repeating store(nws, 'X', v) will add additional values to the
% set of values associated with the name 'X'.
%
% Example:
%   for x = 1:10
%     store(nws, 'numList', x)
%   end
% will associated ten distinct values with the name 'numList'.
%
%   for i = 1:10
%     fetch(nws, 'numList')
%   end
% will retrieve these distinct values, one at a time from the
% first to last stored.
%
% Arguments:
% nws -- netWorkSpace class object.
% a0 -- variable name.
% a1 -- value to store in the variable.
% opts -- options.

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

if nargin < 4
  opts.raw = 0;
end

if nargin < 2 || nargin > 4
  error('incorrect arguments')
elseif nargin == 2
  name = inputname(2);
  if strcmp(name, '')
    error('When used without name argument, the expression argument must be a variable.')
  end
  val = a0;
else
  name = a0;
  val = a1;
end

nwsMex('store', socket(server(nws)), val, nws.currentWs, name, opts.raw);

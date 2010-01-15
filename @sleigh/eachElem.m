function x = eachElem(s, toDo, elementArgs, fixedArgs, execOptions)
% EACHELEM evaluates multiple argument sets using workers in a sleigh, s.
%
% eachElem(s, toDo, elementArgs, fixedArgs, execOptions) forms
% argument sets from vectors passed in elementArgs and fixedArgs.
% elementArgs is a cell array of vectors (x, y, ... z), where all
% vectors must be of the same length. Argument set i consists of
% the ith element of x, y, ... z. If fixedArgs is provided, then these
% additional arguments are appended to the argument set. The
% ordering of arguments can be changed by using argPermute vector,
% which defined as part of execOptions, more details below.
%
% The results from eachElem are normally returned as a cell array
% of cell array.  However, if blocking field of execOptions is set
% to 0, then a sleighPending object is returned.
%
% Arguments:
% s -- a sleigh class object.
%
% toDo -- function or expressions to be evaluated by sleigh workers.
%   toDo must be a function name  (for 'invoke' type) or
%   expressions (for 'eval' type) in quotes.
%
% elementArgs -- a vector, a single-dimensional cell array with multiple
%   entries, or a two-dimensional cell array. If it's a single-dimensional
%   cell array with entries (x, y, ... z), then all entries must be of
%   same length, which is determined by the iterating scheme (variable
%   'by' in execOptions struct).  For example, if 'by' variable indicates
%   to iterate varying arguments by row, then the number of rows for each
%   argument has to be equal.  If function to be executed requires only
%   one varying argument, then elementArgs can be expressed as a vector
%   instead of a cell array.  If elementArgs is a two-dimensional cell
%   array, then the number of tasks equals to the number of rows in two-
%   dimensional cell array. The number of arguments to the function equals
%   to the number of columns in two-dimensional cell array.  Both
%   elementArgs and fixedArgs can be accessed through a global variable
%   named sleighTask.argCA, which is a cell array of values formed by
%   elementArgs and fixedArgs.  This global variable is useful when using
%   'eval' type.
%
%   Example:
%
%     eachElem(s, 'foo', {1:3, 4:6, 7:9})
%
%   will generate three invocations of 'foo':
%
%     foo(1, 4, 7)
%     foo(2, 5, 8)
%     foo(3, 6, 9)
%
% fixedArgs -- a cell array of fixed arguments/constants. Normally, this
%   is appended to each argument set of elementArgs, but the order can be
%   altered using the argPermute field of execOptions argument described
%   below.  If function to be executed requires only one fixed argument,
%   then fixedArgs can be expressed as a vector instead of a cell array.
%   fixedArgs can be accessed through a global variable named
%   sleighTask.argCA, which is a cell array of values from elementArgs and
%   fixedArgs.
%
%   Example:
%
%     fixedArgs = {100, 200, 300}
%     elementArgs = {1:3, 4:6, 7:9}
%     eachElem(s, 'foo', elementArgs, fixedArgs)
%
%   will generate:
%
%     foo(1, 4, 7, 100, 200, 300)
%     foo(2, 5, 8, 100, 200, 300)
%     foo(3, 6, 9, 100, 200, 300)
%
% execOptions -- an optional structure of field.
%   type: determines the type of function invocation to perform. This
%     can be 'invoke' or 'eval'. Default type is 'invoke'.
%     If type is 'invoke', then toDo argument must be a
%     valid M function name. If type is 'eval', then toDo argument
%     is evaluated as is.
%
%   blocking: determines whether to wait for the results, or to reurn
%     as soon as the tasks have submitted. Default value is set to 1,
%     which means eachElem is blocked until all tasks are completed.
%     If value is set to 0, then eachElem returns immediately with a
%     sleighPending object that is used to monitor the status of the
%     tasks, and eventually used it to retrieve results.
%     You must wait for the results to be completed before submitting
%     more tasks to the sleigh workspace.
%
%     If blocking is set to 0, then the loadFactor argument is disabled
%     and ignored.
%
%   argPermute: a vector of integers used to permute each (elementArgs +
%     fixedArgs) argument list to match the calling convention of toDo.
%
%     Example:
%
%       fixedArgs = {100, 200, 300}
%       elementArgs = {1:3, 4:6, 7:9}
%       execOptions.argPermute = [3 2 1 6 4 5]
%       eachElem(s, 'foo', elementArgs, fixedArgs, execOptions)
%
%     will generate:
%
%       foo(7, 4, 1, 300, 100, 200)
%       foo(8, 5, 2, 300, 100, 200)
%       foo(9, 6, 3, 300, 100, 200)
%
%   loadFactor: if set, no more than loadFactor*# of worker
%     tasks will be posted at once. This help to control resource
%     demands on the nws server. It is mutually exclusive with
%     'blocking' set to 0.
%
%   by: one of three iterating schemes: 'cell', 'row', or
%     'column'. Default value is to iterate by cell. All elements of
%     elementArgs iterates based on the 'by' value. If different
%     iterating scheme is needed for each element of the
%     elementArgs, a cell array of different iterating schemes can
%     be specified. For example: opt.by = {'row', 'column'}.
%     Each index of the 'by' cell array represents the iterating
%     scheme for the corresponding elements in the elementArgs.
%     If no value is specified, then default value 'cell' is assumed.
%     The 'by' field is ignored if elementArgs is a two-dimensional
%     cell array.

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

% this code is very similar to eachWorker, should refactor.
if s.busyfh('query')
  error('sleigh is busy');
end

if nargin < 3
  error('incorrect arguments');
end

if iscell(elementArgs)
  ea = elementArgs;
else
  ea = {elementArgs};
end

% ea has to be a single or two-dimensional cell array
eaDim = size(ea);
if length(eaDim) > 2
  error('elementArgs cannot have more than 2 dimensions');
end

numElem = eaDim(2);

if numElem == 0
  error('elementArgs length must be greater than zero');
end

try
  blocking = execOptions.blocking;
catch
  blocking = 1;
end

try
  loadFactor = execOptions.loadFactor;
catch
  loadFactor = 0;
end

try
  by = execOptions.by;
catch
  by = 'cell';
end

try
  chunkSize = execOptions.chunkSize;
catch
  chunkSize = 1;
end

try
  t.type = execOptions.type;
catch
  t.type = 'invoke';
end

twodim_ea = 0;
if eaDim(1) == 1
  v = ea{1};
  vl = countElement(v, getIterateScheme(by, 1));
  for i = 2:numElem
    if vl ~= countElement(ea{i}, getIterateScheme(by, i))
      error('all argument vectors must be the same length');
    end
  end
else
  % check if any entry in the two-dimensional cell array is empty
  for j = 1:eaDim(1)
    for k = 1:eaDim(2)
      if isempty(ea{j,k})
        error('one or more entries of elementArgs is empty');
      end
    end
  end
  twodim_ea = 1;
end

% construct argument sets
try
  if iscell(fixedArgs)
    fa = fixedArgs;
  else
    fa = {fixedArgs};
  end
  numFixed = length(fa);
  argCA = cell(numElem+numFixed, 1);
  argCA(numElem+1:end) = fa;
catch
  argCA = cell(numElem, 1);
end

try
  argPermute = execOptions.argPermute;
catch
  argPermute = 1:length(argCA);
end

% eachElem execution does not require a barrier.
t.barrier = 0;

if strcmp(t.type, 'invoke')
  if isa(toDo, 'function_handle')
    t.funcName = func2str(toDo);
  elseif ischar(toDo)
    t.funcName = toDo;
  else
    error('toDo argument must be a string or function handle');
  end
elseif strcmp(t.type, 'eval')
  t.code = toDo;
else
  error('unrecognized type');
end

if twodim_ea
  numTasks = eaDim(1);
else
  numTasks = countElement(ea{1}, getIterateScheme(by, 1));
end
taskLimit = numTasks;
wc = s.workerCount;

global totalTasks;

% update the total number of submitted tasks
totalTasks = totalTasks + numTasks;
store(s.nws, 'totalTasks', num2str(totalTasks));

if blocking && wc < numTasks && loadFactor > 0
  taskLimit = loadFactor * wc;
  if taskLimit < wc
    taskLimit = wc;
  elseif taskLimit > numTasks
    taskLimit = numTasks;
  end
end

% fill the pool
for i = 1:taskLimit
  if twodim_ea
    argCA(1:numElem) = getElement(ea, i, 'row');
  else
    for j = 1:numElem
      argCA{j} = getElement(ea{j}, i, getIterateScheme(by, j));
    end
  end
  t.argCA = argCA(argPermute);
  t.tag = i;
  store(s.nws, 'task', t);
end

if ~blocking
  s.busyfh('set');
  x = sleighPending(s.nws, numTasks, '', s.busyfh);
  return
end


% create two dimensional cell arrays to store results.
% we make column size = 1, but cell arrays can be
% expanded dynamically, if number of output arguments
% is more than one.
rVec = cell(1, numTasks);

% WHAT ABOUT variable output arguments and zero output argument

% submit one new task for every task completed
for i = taskLimit+1:numTasks
  r = fetch(s.nws, 'result');
  if ~iscell(r.value)
    display(r.value);
    error('result is not a cell array');
  end
  if size(r.value, 1) > size(rVec, 1)
    rVec{size(r, 1), 1} = [];
  end
  [rVec{:, r.tag}] = r.value{:};

  if twodim_ea
    argCA(1:numElem) = getElement(ea, i, 'row');
  else
    for j = 1:numElem
      argCA{j} = getElement(ea{j}, i, getIterateScheme(by, j));
    end
  end
  t.argCA = argCA(argPermute);
  t.tag = i;
  store(s.nws, 'task', t);
end

% drain the pool
for i = 1:taskLimit
  r = fetch(s.nws, 'result');
  if ~iscell(r.value)
    display(r.value);
    error('result is not a cell array');
  end
  if size(r.value, 1) > size(rVec, 1)
    rVec{size(r.value, 1), 1} = [];
  end
  [rVec{:, r.tag}] = r.value{:};
end

x = rVec;
end

% Get iterating scheme
function iterate = getIterateScheme(by, index)
try
  iterate = by{index};
catch
  iterate = by;
end
end


% Determine number of elements contain in x based on iterating
% scheme, by. If x is a cell array, then number of elements equals
% to the length of x. If x is a matrix, then depends on the
% iterating scheme, different size would be returned.
% For example, if by = 'row', then number of rows in x is
% returned. If by = 'column', then number of columns in x is
% returned.
function nElem = countElement(x, by)
dim = size(x);
switch by
  case 'row'
    nElem = dim(1);
  case 'column'
    nElem = dim(2);
  otherwise
    nElem = dim(1) * dim(2);
end
end


% Return element either in matrix or cell array based on the input
% variable, x.  If x is a cell array. then return ith element of the cell
% array. The return value is a cell array.  If x is a matrix, then return
% a vector or a matrix based on iterating scheme.
function elem = getElement(x, i, by)
maxElement = countElement(x, by);
if i < 1 || i > maxElement
  error('i outside of valid range for x');
end

switch by
  case 'row'
    if iscell(x)
      elem = {x{i,:}};
    else
      elem = x(i,:);
    end
  case 'column'
    if iscell(x)
      elem = {x{:,i}};
    else
      elem = x(:,i);
    end
  otherwise
    if (iscell(x))
      elem = x{i};
    else
      elem = x(i);
    end
end
end

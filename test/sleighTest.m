function sleighTest
% sleighTest
% primary function name cannot start with "test"

printresult = 1;
% Standard boilerplate for any test .m file
% The following two lines are required to auto-scan and run test methods
tests = str2func(suite([mfilename '.m']));
[passres, failres, warnres] = runner(tests, printresult);
% End boilerplate


function test01
  global s
  s = sleigh;

% add one to each element of the vectors
% use eachWorker to initialize data and
% use eachElem to do calculation
function test02
  global s
  eachWorker(s, 'init', 1);
  temp = eachElem(s, 'add', 1:10);
  C = cell2mat(temp);
  answer = (1:10) + 1;
  if any(C ~= answer)
    fail('test02: add one to each element of the vector failed.')
  end

% add two vectors
function test03
  global s
  A = 1:10;
  B = 11:20;
  temp = eachElem(s, @(x, y) x + y, {A, B});
  C = cell2mat(temp);
  answer = A + B;
  if any(C ~= answer)
    fail('test03: add two vectors failed.');
  end

% matrix addition
function test04
  global s
  A = floor(10*rand(3, 3));
  B = floor(10*rand(3, 3));
  C = matAddTest(s, A, B);
  answer = A + B;
  if any(C ~= answer)
    fail('test04: matrix addition failed.');
  end

% matrix multiplication
function test05
  global s
  A = floor(10*rand(9, 3));
  B = floor(10*rand(3, 8));
  C = matMultTest(s, A, B);
  answer = A * B;
  if any(C ~= answer)
    fail('test05: matrix multiplication failed.');
  end

% permute arguments
function test06
  global s
  opt.argPermute = [2 1 3];
  A = floor(10*rand(8, 9));
  B = floor(10*rand(8, 9));
  temp = eachElem(s, 'calculate', {A, B}, {'-'}, opt);
  C = cell2mat(reshape(temp, size(A)));
  answer = B - A;
  if any(C ~= answer)
    fail('test06: subtract two vectors failed.');
  end

% subtract one cell array of matrices from another cell array of
% matrices.
function test07
  global s
  A = floor(10*rand(2, 3));
  B = floor(10*rand(2, 3));
  C = floor(10*rand(2, 3));
  D = floor(10*rand(2, 3));
  list1 = {A, B};
  list2 = {C, D};
  temp = eachElem(s, 'calculate', {list1, list2}, {'-'});
  for i = 1:length(temp)
    if any(temp{i} ~= (list1{i} - list2{i}))
      fail('test07: subtract two matrices failed')
    end
  end

% test non-blocking eachElem
function test08
  global s
  opt.blocking = 0;
  sp = eachElem(s, 'calculate', {101:200}, {2, '*'}, opt);
  while check(sp)
    pause(1);
  end

  temp = wait(sp);
  result = cell2mat(temp);
  answer = (101:200) * 2;
  assertEquals('test08: nonblocking eachElem failed', answer, result);

% test different invocation types
% First, use define invocation type to define add function in each worker.
% Then use eval invocation type to do calculation
function test09
  global s;
  opt.type = 'define';
  eachWorker(s, 'add', {}, opt);
  opt.type = 'eval';
  temp = eachElem(s, 'add(sleighTask.argCA{1})', {1:10}, {}, opt);
  result = cell2mat(temp);
  answer = (1:10) + 1;
  assertEquals('test09 failed', answer, result);

% test join phase
function test10
  opt.nodeList = {'localhost', 'abc'};
  opt.launch = @sshcmd;
  opt.verbose = 1;
  s2 = sleigh(opt);
  [numWorkers, ready] = status(s2);
  if ~ready
    [numWorkers, ready] = status(s2, 0, 30);
  end

  % close the group after 10 seconds
  if ~ready
    [numWorkers, ready] = status(s2, 1, 10);
  end

  opt.by = 'row';
  temp = eachElem(s2, 'calculate', {11:20, 1:10}, {'-'}, opt);
  result = temp{1};
  answer = (11:20) - (1:10);
  assertEquals('test10: join phase test failed', answer, result);

  stop(s2);

function test11
  global s;
  varying = 1:10;
  fixed = 100;
  expected = num2cell([varying + fixed; repmat(2, 1, length(varying))]);

  actual = eachElem(s, @multivalue, 1:10, 100);
  assertTrue('multivalue test 1 failed', isequal(expected, actual));

  actual = eachElem(s, @multivalue, {1:10}, {100});
  assertTrue('multivalue test 2 failed', isequal(expected, actual));

  actual = eachElem(s, @multivalue, {num2cell(1:10)}, 100);
  assertTrue('multivalue test 3 failed', isequal(expected, actual));

function test12
  global s;
  actual = eachElem(s, @none, 1:2);
  expected = {'function has no return value', 'function has no return value'};
  assertEquals('test12: no return values test failed', expected, actual);

function test99
  global s
  stop(s);

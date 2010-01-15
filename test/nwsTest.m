function nwsTest
% nwsTest
% primary function name cannot start with "test"

printresult = 1;
% Standard boilerplate for any test .m file
% The following two lines are required to auto-scan and run test methods
tests = str2func(suite([mfilename '.m']));
[passres, failres, warnres] = runner(tests, printresult);
% End boilerplate

function testCreateNws
  global ws
  ws = netWorkSpace('matlab test space');    
  nwss = server(ws);
  X = listWss(nwss);
  names = {X.name};
  owned = {X.owned};
  for i = 1:length(names)
     if strcmp(names(i), 'matlab test space') && owned{i}
        return
     end
  end
  fail('netWorkSpace creation failed, or someone already created and owned the workspace with the same name')   
   
function testStore
  global ws
  for i = 1:100
    store(ws, 'x', i);
  end
  vars = listVars(ws);
  varNames = {vars.name};
  for i=1:length(varNames)
    if strcmp(varNames(i), 'x')
      values = {vars.values};
      if (values{i}==100)
        return;
      else
        fail('variable x exists, but the number of values is not correct')
      end
    end
  end
  fail('store failed')

function testFetch
  global ws
  y = 0;
  for i = 1:100
      y = y+fetch(ws, 'x');
  end
  assertEquals('Fetched values must be equal to 5050', y, 5050)

function testFetchTry
  global ws
  X = fetchTry(ws, 'emptyvar');
  assertEquals('isMissing value did not work', X, 0);
  [X, F] = fetchTry(ws, 'emptyvar');
  assertEquals('isMissing value did not work', X, 0);
  assertFalse('found flag is not correct', F);
  store(ws, 'emptyvar', 99);
  [X, F] = fetchTry(ws, 'emptyvar');
  assertEquals('incorrect value returned', X, 99);
  assertTrue('found flag is not correct', F);

function testFetchTryMissing
  global ws
  X = fetchTry(ws, 'emptyvar', []);
  assertTrue('isMissing value did not work', isempty(X))
  [X, F]  = fetchTry(ws, 'emptyvar', []);
  assertTrue('isMissing value is not correct', isempty(X))
  assertFalse('found flag is not correct', F);
  store(ws, 'emptyvar', 999);
  [X, F] = fetchTry(ws, 'emptyvar', []);
  assertEquals('incorrect value returned', X, 999);
  assertTrue('found flag is not correct', F);

function testFind
  global ws
  x = 10;
  store(ws, x);
  y = find(ws, 'x');
  assertEquals('x must be 10', y, 10);

function testFindTry
  global ws
  X = findTry(ws, 'emptyvar');
  assertEquals('isMissing value did not work', X, 0);
  [X, F] = findTry(ws, 'emptyvar');
  assertEquals('isMissing value did not work', X, 0);
  assertFalse('found flag is not correct', F);
  store(ws, 'emptyvar', 77);
  [X, F] = findTry(ws, 'emptyvar');
  assertEquals('incorrect value returned', X, 77);
  assertTrue('found flag is not correct', F);
  [X, F] = fetchTry(ws, 'emptyvar');
  assertEquals('incorrect value returned', X, 77);
  assertTrue('found flag is not correct', F);

function testFindTryMissing
  global ws
  X = findTry(ws, 'emptyvar', []);
  assertTrue('isMissing value did not work', isempty(X))
  [X, F]  = findTry(ws, 'emptyvar', []);
  assertTrue('isMissing value is not correct', isempty(X))
  assertFalse('found flag is not correct', F);
  store(ws, 'emptyvar', 777);
  [X, F] = findTry(ws, 'emptyvar', []);
  assertEquals('incorrect value returned', X, 777);
  assertTrue('found flag is not correct', F);
  [X, F] = fetchTry(ws, 'emptyvar', []);
  assertEquals('incorrect value returned', X, 777);
  assertTrue('found flag is not correct', F);

function testDeclare
  global ws
  declare(ws, 'pi', 'single');
  store(ws, 'pi', 123456);
  store(ws, 'pi', 3.1415);
  pi = fetch(ws, 'pi');
  assertEquals('pi must be 3.1415', pi, 3.1415);

function testDeleteVar
  global ws
  deleteVar(ws, 'x');
  [X, F] = fetchTry(ws, 'x', -1);
  assertFalse('X variable is missing', F)

function testClose
  global ws
  close(ws);
  nwss = nwsServer();
  X = listWss(nwss);
  names = {X.name};
  for i = 1:length(names)
     name = names{i};
     if strcmp(names{i}, 'matlab test place')
        fail('netWorkSpace failed to close')
     end
  end

function testDeleteWs
  ws = netWorkSpace('test delete');
  nwss = server(ws);
  deleteWs(nwss, 'test delete');
  X = listWss(nwss);
  names = {X.name};
  for i = 1:length(names)
     name = names{i};
     if strcmp(name, 'test delete')
        fail('netWorkSpace delete failed')
     end
  end

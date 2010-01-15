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
% Simple example

ws = netWorkSpace('m box');
display('connected, listing contents of netWorkSpace (should be nothing there).')
listVars(ws);

store(ws, 'x', 1);
display('should now see x.')
listVars(ws);

me = 12321;
store(ws, me);
display('should now see me.')
listVars(ws);

display('find (but don''t consume) x.')
find(ws, 'x')
display('check that it is still there.')
listVars(ws);

display('associate another value with x.')
store(ws, 'x', 2);
listVars(ws);

display('consume values for x, should see them in order saved.')
fetch(ws, 'x')
fetch(ws, 'x')
display('no more values for x... .')
listVars(ws);

display('so try to fetch and see what happens... .')
fetchTry(ws, 'x', 'no go')

display('create a single-value variable.')
declare(ws, 'pi', 'single')
listVars(ws);

display('get rid of x.')
deleteVar(ws, 'x')
listVars(ws);

display('try to store two values to pi.')
store(ws, 'pi', 2.171828182)
store(ws, 'pi', 3.141592654)
listVars(ws);

display('check that the right one was kept.')
find(ws, 'pi')

display('what about the rest of the world?')
listWss(server(ws));

display('here''s some help.')
help netWorkSpace
help netWorkSpace.store

%% NetWorkSpaces for MATLAB(R) Demo
%
% NetWorkSpaces (NWS) is a MATLAB(R) toolbox that makes it easy to
% communicate and coordinate multiple MATLAB(R) programs running on
% potentially different machines.  In this demo,  we will demonstrate
% how to share data using NetWorkSpaces.
%
% Assuming that you have an NWS server running, the first step is
% to create a shared workspace.  We'll name it 'bayport':

ws = netWorkSpace('bayport')

%%
% This workspace is created on the NWS server running on the local machine,
% and listening on port 8765.  Additional arguments can be specified to
% change these default settings.
%
% Once we have a netWorkSpace object, we can write data to a variable
% in that workspace using the |store| method:

store(ws, 'joe', 17)

%%
% The variable 'joe' in workspace 'bayport' now contains the value of 17.
%
% We can get a copy of that value using the |find| method:

age = find(ws, 'joe')

%%
% Although we call 'joe' a variable, it's not actually a simple
% variable: it's a *queue*, or *FIFO*, which can contain multiple values,
% and can also be empty.  If 'joe' had been empty, the |find| method
% wouldn't have returned until a value was stored into the variable
% by another process.  We call that behaviour *blocking*.  Since this
% demo will only use a single MATLAB(R) session, we will be careful
% never to block, otherwise you'd have to |store| a value to the variable
% from another session, or delete the workspace using the web interface,
% in order to *unblock* the |find| method.
%
% To avoid blocking, we can use the |findTry| method:

age = findTry(ws, 'chet')

%%
% By default, the value 0 is returned if the variable is empty.
% You can specify a different value to return using a third argument:

age = findTry(ws, 'chet', [])

%%
% Both the |find| and |findTry| methods are *non-destructive*.
% That is, they don't remove the value from the variable.
% The |fetch| and |fetchTry| methods work like |find| and |findTry|,
% except they also remove the value from the variable:

age = fetchTry(ws, 'joe')
age = fetchTry(ws, 'joe')

%%
% Since the |find| method does not remove the value from the workspace,
% we cannot use it to read more than one value in a variable.
% To read through all the values, we  can use the |fetch| method.
% This can be useful for sending a sequence of values from one program to
% another.
%
% Let's try writing multiple values to a variable:

for v = [16 19 25 22]
    store(ws, 'biff', v);
end

%%
% To read the values, we just call fetch repeatedly:

m = [];
for k = 1:4
    m = [m fetch(ws, 'biff')];
end
m

%%
% If we didn't know how many values were stored in a variable, we could
% have done the following:

for v = 16:2:22
    store(ws, 'biff', v);
end

m = [];
while 1
    t = fetchTry(ws, 'biff', []);
    if isempty(t)
        break
    end
    m = [m t];
end
m

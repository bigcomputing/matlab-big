function nonblocking(host, port, numTasks, verbose)
% NONBLOCKING: Example of a non-blocking sleigh program

if nargin < 1; host = 'localhost'; end
if nargin < 2; port = 8765; end
if nargin < 3; numTasks = 10; end
if nargin < 4; verbose = 0; end

% create a workspace to communicate with the workers
server = nwsServer(host, port);
wsName = mktempWs(server);
ws = openWs(server, wsName);

% create a sleigh and compute the number of workers
opt.verbose = verbose;
opt.nwsHost = host;
opt.nwsPort = port;
s = sleigh(opt);

wopt.blocking = 0;
eachWorker(s, 'worker', wsName, wopt);

for i = 1:numTasks
  store(ws, 'task', i);
end

for i = 1:numTasks
  result = fetch(ws, 'result');
  fprintf(1, '%d times 2 is %d\n', result{1}, result{2});
end

close(ws);
stop(s);

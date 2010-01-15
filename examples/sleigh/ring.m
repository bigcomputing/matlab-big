function ring(useWebLaunch, numTasks, opt)
% RING: Pass tokens around the ring in parallel

if nargin < 1; useWebLaunch = 0; end
if nargin < 2; numTasks = 10; end
if nargin < 3; opt = struct; end

if ~isfield(opt, 'nwsHost')
  opt.nwsHost = 'localhost';
end
if ~isfield(opt, 'nwsPort')
  opt.nwsPort = 8765;
end
if ~isfield(opt, 'verbose')
  opt.verbose = 0;
end

% create a workspace to communicate with the workers
server = nwsServer(opt.nwsHost, opt.nwsPort);
wsName = mktempWs(server);
ws = openWs(server, wsName);

% create a sleigh and compute the number of workers
if (useWebLaunch); opt.launch = 'web'; end
s = sleigh(opt);

numWorkers = find(nws(s), 'workerCount');

% include the master as one of the workers
numWorkers = numWorkers + 1;

% tell the worker to execute the ring function defined in this
% file
wopt.blocking = 0;
eachWorker(s, 'worker_ring', wsName, numWorkers, numTasks, wopt);
  
global SleighRank SleighNws
SleighRank = numWorkers - 1;
SleighNws = nws(s);
  
fprintf(1, 'Master assigned rank %d\n', SleighRank);
 
store(ws, 'worker_0', 0);
tic;
worker_ring(wsName, numWorkers, numTasks);
totalTime = toc;
token = fetch(ws, 'worker_0');
if (token ~= (numTasks*numWorkers))
  error('token not equal to numTasks multiply by numWorkers');
end

fprintf(1, 'The token was passed %d times in %f seconds\n', token, totalTime);
fprintf(1, 'Seconds per operation: %d\n', totalTime/(2*token));

close(ws);
stop(s);

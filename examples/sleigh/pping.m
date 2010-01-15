function pping(useWebLaunch, numTasks, size, opt)
% PPING: A Parallel Ping Program

if nargin < 1; useWebLaunch = 0; end
if nargin < 2; numTasks = 10; end
if nargin < 3; size = 10; end
if nargin < 4; opt = struct; end

if ~isfield(opt, 'nwsHost')
  opt.nwsHost = 'localhost';
end
if ~isfield(opt, 'nwsPort')
  opt.nwsPort = 8765;
end
if ~isfield(opt, 'verbose')
  opt.verbose = 0;
end

% create a workspace to communicate with workers
server = nwsServer(opt.nwsHost, opt.nwsPort);
wsName = mktempWs(server);
ws = openWs(server, wsName);

% create a sleigh and compute the number of workers
if (useWebLaunch)
  opt.launch = 'web';
end
s = sleigh(opt);

numWorkers = find(nws(s), 'workerCount');

wopt.blocking = 0;
eachWorker(s, 'pong', wsName, numTasks, size, wopt);

totalTasks = numWorkers*numTasks;
tic;
ping(ws, totalTasks);
totalTime = toc;
fprintf(1, 'Seconds per operation: %f\n', totalTime/(4*totalTasks));
fprintf(1, 'Payload size is approximately %d bytes\n', size);

close(ws);
stop(s);

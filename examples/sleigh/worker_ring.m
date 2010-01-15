function worker_ring(wsName, numWorkers, numTasks)
% WORKER_RING: This is the "worker" function for the "ring" example

global SleighRank SleighNws
ws = useWs(server(SleighNws), wsName);
mine = sprintf('worker_%d', SleighRank);
next = mod((SleighRank + 1), numWorkers);
his = sprintf('worker_%d', next);
  
for i = 1:numTasks
  j = fetch(ws, mine);
  store(ws, his, j+1);
end

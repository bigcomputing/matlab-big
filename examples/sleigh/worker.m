function worker(wsName) 
% WORKER: This is the "worker" function for the "nonblocking" example

global SleighNws SleighRank

ws = useWs(server(SleighNws), wsName);
while 1
  task = fetch(ws, 'task');
  result = 2 * task;
  store(ws, 'result', {task, result})
end

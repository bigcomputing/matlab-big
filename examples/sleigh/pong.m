function pong (wsName, numTasks, size)

global SleighNws SleighRank

ws = useWs(server(SleighNws), wsName);
pong = sprintf('pong_%d', SleighRank);
str = repmat('#', 1, size);
payload = sprintf('%s',str);

for i=1:numTasks
  store(ws, 'ping', {pong, payload});
  j = fetch(ws, pong);
end

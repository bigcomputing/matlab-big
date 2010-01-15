function ping(ws, totalTasks)

for i=1:totalTasks
  r = fetch(ws, 'ping');
  if (length(r) ~= 2)
    error('length of r is not equal to 2');
  end
  store(ws, r{1}, r{2});
end

function res = psbootstrapHelper(iterNo, data, func, ssize, reps)
thisReps = reps(iterNo + 1) - reps(iterNo);
f = eval(func);
res = [];
for i = (1:thisReps)
  thisSamp = data(ceil(rand(1, ssize) * length(data)));
  res = [res ; f(thisSamp)];
end

function res = psbootstrap(sleigh, nreps, nchunks, ssize, func, data)
reps = floor(linspace(0, nreps, nchunks+1));
fixed_args = {data, func, ssize, reps};
tmpres = eachElem(sleigh, 'psbootstrapHelper', 1:nchunks, fixed_args);
res = [];
for i = 1:length(tmpres)
  res = [res; tmpres{i}{1}];
end

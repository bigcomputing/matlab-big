function res = pbootstrap(sleigh, nreps, nchunks, func, data)
reps = floor(linspace(0, nreps, nchunks+1));
fixed_args = {data, func, reps};
tmpres = eachElem(sleigh, 'pbootstrapHelper', num2cell([1:nchunks]'), fixed_args);
res = [];
for i = 1:length(tmpres)
  res = [res; tmpres{i}];
end

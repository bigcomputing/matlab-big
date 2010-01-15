function [seqTime, parTime] = pbootstrapBench(benchReps, sleigh, nreps, nchunks, func, data)
parTime = [];
seqTime = [];
the_func = eval(func);
for i = 1:benchReps
  tic;
  pbootstrap(sleigh, nreps, nchunks, func, data);
  parTime = [parTime; toc];

  tic;
  bootstrp(nreps, the_func, data);
  seqTime = [seqTime; toc];
end

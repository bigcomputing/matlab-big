function result = glob()
% GLOB: Test that global variables can be used in workers

opt.verbose = 1;
opt.logDir = '/tmp';
s = sleigh(opt);
eachWorker(s, @globInit, 42);
r = eachWorker(s, @globGet);
result = cell2mat(r);

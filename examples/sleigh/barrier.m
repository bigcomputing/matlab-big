function barrier 
% BARRIER: a simple test of eachWorker
% This calls eachWorker a hundred times, each time
% pausing for a random period of time.

s = sleigh;
options.type='eval';
for i=1:100
  eachWorker(s, 'pause(abs(rand(1)))', options);
end
stop(s);

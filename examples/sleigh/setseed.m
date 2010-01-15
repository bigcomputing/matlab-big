function status = setseed()
% SETSEED: set seed number
% return status = 0

global SleighRank;
rand('seed', SleighRank);
status = SleighRank;

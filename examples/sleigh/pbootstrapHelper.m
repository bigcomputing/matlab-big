function res = pbootstrapHelper(iterNo, data, func, reps)
thisReps = reps(iterNo + 1) - reps(iterNo);
f = eval(func);
res = bootstrp(thisReps, f, data);

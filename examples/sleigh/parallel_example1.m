%  Parallel version of example1.m in BOOTSTRAP package.
%  BOOTSTRAP package can be downloaded at 
%  http://www.csp.curtin.edu.au/downloads/bootstrap_toolbox.html
%  It is developed by CSP Group at Gurtin University of Technology.
%
%  This Matlab script provides an interactive way to reproduce 
%  Example 1: Confidence interval for the mean reported in:
%  Zoubir, A.M. and Boashash, B. The Bootstrap and Its Application in
%  Signal Processing. IEEE Signal  Processing Magazine, 
%  Vol. 15, No. 1, pp. 55-76, 1998.

%  Created by A. M. Zoubir and D. R. Iskander
%  June 1998
disp('   ')
disp('This Matlab script provides an interactive way to reproduce')
disp('Example 1: Confidence interval for the mean reported in:')
disp('Zoubir, A.M. and Boashash, B. The Bootstrap and Its Application')
disp('in Signal Processing. IEEE Signal  Processing Magazine,')
disp('Vol. 15, No. 1, pp. 55-76, 1998.')
disp('   ')
disp('   ')
disp('           CONFIDENCE INTERVAL FOR THE MEAN')
disp('           --------------------------------')
disp('   ')
disp('   ')
disp('Let X_1,...,X_n be n independent and identically distributed')
disp('random variables from some unknown distribution, and suppose') 
disp('that we wish to find an estimator and an (1-alpha)100% interval')
disp('for the mean mu. Usually, we estimate mu by the sample mean')
disp('   ')
disp('                hat{mu}=(X_1+...X_n)/n') 
disp('   ')
disp('A confidence interval for mu can be found by determining the')
disp('distribution of hat{mu} (over repeated samples of size n from')
disp('the underlying distribution), and finding values hat{mu}_L and')
disp('hat{mu}_U such that')
disp('   ')
disp('        P(hat{mu}_L<=mu<=hat{mu}_U)=1-alpha') 
disp('   ')
disp('Press any key to continue')
pause
disp('   ')
disp('The bootstrap paradigm suggests that we assume that the sample')
disp('X={X_1,...,X_n} itself constitutes the underlying distribution;')
disp('then by resampling from X many times and computing hat{mu} for')
disp('each of these resamples, we get a bootstrap distribution of')
disp('hat{mu}, and from which a confidence interval for mu is derived')
disp('   ')
disp('STEP 0: Conduct the experiment. Say')
disp('   ')
disp('X=randn(1,20)')

X=randn(1,20)
disp('hatmu=mean(X)')
hatmu=mean(X)

% start sleigh workers
s = sleigh;
% number of workers
n = 2;   

% set each worker's seed number based on their SleighRank
% This ensures that they have truly random number sequences 
% when bootrap function calles rand()
eachWorker(s, 'setseed');

disp('Press any key to continue')
pause
disp('   ')
disp('STEP 1: Resampling.')
disp('   ')
disp('result=eachElem(s, bootrsp, list, eo);')
% number of resampling is one. 
list = [1];
eo.argPermute=[2 1];
result=eachElem(s,  'bootrsp', list, X, eo);
Xstar = cell2mat(result{1})

disp('Press any key to continue')
pause
disp('   ')
disp('STEP 2: Calculation of the bootstrap estimate')
disp('   ')
disp('hatmu1=mean(Xstar)')
hatmu1=mean(Xstar)


disp('Press any key to continue')
pause
disp('   ')
disp('STEP 3: Repetition. Repeat steps 1 and 2 a large number of times,')
disp('        say B=1000.') 
disp('    ')
disp('result=eachElem(s, bootrsp, list, eo);')
disp('hatmu1=mean(Xstar);')
% number of resampling is 1000
iterations = 1000;
partition = 20;
chunk = iterations/partition;
list = repmat(chunk, 1, partition); 
eo.argPermute=[2 1];
result=eachElem(s,  'bootrsp', list, X, eo);
Xstar = [];
for (i=1:partition)
   Xstar = [Xstar result{i}{1}];
end
hatmu1=mean(Xstar);

disp('   ')
disp('Now hatmu1 is a vector of 1000 elements')
disp('   ')
disp('Press any key to continue')
pause
disp('   ')
disp('STEP 4: Approximation of the distribution. Sort hatmu1')
disp('   ')

disp('hatmusorted=sort(hatmu1);')
hatmusorted=sort(hatmu1);


disp('   ')
disp('Press any key to continue')
pause
disp('   ')
disp('STEP 5: Confidence interval. Calculate the (1-alpha)100%') 
disp('        confidence interval. Let alpha=0.05.')
disp('   ')
disp('muL=hatmusorted(25)')
muL=hatmusorted(25)
disp('muU=hatmusorted(976)')
muU=hatmusorted(976)
disp('Press any key to continue')
pause
disp('   ')
disp('The confidence interval example presented above can be')
disp('simply evaluated using the following bootstrap command:')
disp('   ')
disp('M=confinth(X, ''mean'',0.05,1000)')
disp('    ')
disp('Please wait ...')

% Further parallelism need to be done here because
% bootstrp is called within confinth
% [muL,muU]=confinth(X,'mean',0.05,1000)
fixedArgs={X, 'mean', 0.05};
eo.argPermute=[2 3 4 1];
iterations = 1000;
partition = 20;
chunk = iterations/partition;
list = repmat(chunk, 1, partition);
result=eachElem(s, 'confinth', list, fixedArgs, eo);
% reconstruct results (cell array of cell array) back to matrix
muL_total = 0;
muU_total = 0;
for i = 1:partition
  muL_total = muL_total + result{i}{1};
  muU_total = muU_total + result{i}{2};
end

muL = muL_total/partition
muU = muU_total/partition


disp('Now we plot the histogram of hatmu1 and the theoretical')
disp('probability density function under the Gaussian assumption.')
disp('   ') 
disp('Press any key to continue')
pause

[a,b]=hist(hatmu1,20);
%figure;bar(b,a/trapz(b,a));hold on;
%plot(-1:0.01:1,normpdf(-1:0.01:1,0,1/sqrt(20)),'r');hold off        
%xlabel('Sample')
%ylabel('Density Function')

%disp('   ')
%disp('You may note that the resulting bootstrap PDF depends on')
%disp('the initial estimate hatmu. Re-run this example several')
%disp('times and refer for more comments to abovementioned article.')  
%disp('   ')
%disp('Press any key to continue')
%pause
%disp('    ')
stop(s)
%disp('End of Example 1')

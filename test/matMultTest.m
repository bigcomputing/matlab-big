function C = matMultTest(s, A, B) 

% iterate by row
opt.by = 'row';
Carray = eachElem(s, @(x, y) x * y, A,  B, opt);
C = vertcat(Carray{:});

% iterate by column
opt.by = 'column';
Darray = eachElem(s, @(y, x) x * y, B,  A, opt);
D = [Darray{:}];

n = norm(C - D);
if n > 1.0e-14
  error('results are not equal');
end

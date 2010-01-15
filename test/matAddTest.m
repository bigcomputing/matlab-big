function C = matAddTest(s, A, B)

% add by cell (default)
temp = eachElem(s, @(x, y) x + y, {A, B});
C = cell2mat(reshape(temp, size(A)));

% add by row
opt.by = 'row';
temp = eachElem(s, @(x, y) x + y, {A, B}, {}, opt);
result1 = vertcat(temp{:});

n = norm(C - result1);
if n > 1.0e-14
  error('error: result1 is not equal to C');
end

% add by column
opt.by = 'column';
temp = eachElem(s, @(x, y) x + y, {A, B}, {}, opt);
result2 = [temp{:}];

n = norm(C - result2);
if n > 1.0e-14
  error('error: result2 is not equal to C');
end

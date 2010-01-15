function testEachElem
% this function tests two different ways in passing varying
% arguments to eachElem

s = sleigh;
result = eachElem(s, 'mean', {{1:10, 11:20}});
if result{1} == mean(1:10)
    disp('success');
else
    error('failed');
end

if result{2} == mean(11:20)
    disp('success');
else
    error('failed');
end

result = eachElem(s, 'add2', {{1:10}, [1]});
if result{1} == ((1:10)+1)
    disp('success');
else
    error('failed');
end

% pass varying argument and fixed argument
result = eachElem(s, 'add2', {{1:10}}, 1);
if result{1} == ((1:10)+1)
    disp('success');
else
    error('failed');
end

% change order using argPermute
opt.argPermute = [2 1];
result = eachElem(s, 'minus2', {{1:10}}, 1, opt);
if result{1} == (1-(1:10))
    disp('success');
else
    error('failed');
end

% use two dimensional cell array
result = eachElem(s, 'mean', {1:10; 11:20});
if result{1} == mean(1:10)
    disp('success');
else
    error('failed');
end

if result{2} == mean(11:20)
    disp('success');
else
    error('failed');
end

result = eachElem(s, 'add2', {1:10 11:20; 21:30 31:40});
if result{1} == (1:10)+(11:20)
    disp('success');
else
    error('failed');
end

if result{2} == (21:30)+(31:40)
    disp('success');
else
    error('failed');
end

% use two dimensional cell array and fixed argument
result = eachElem(s, 'add2', {1:10; 11:20}, 1);
if result{1} == (1:10)+1
    disp('success');
else
    error('failed');
end

if result{2} == (11:20)+1
    disp('success');
else
    error('failed');
end

% use two dimensional cell array and argPermute
result = eachElem(s, 'minus2', {1:10; 11:20}, 1, opt);
if result{1} == 1-(1:10)
    disp('success');
else
    error('failed');
end

if result{2} == 1-(11:20)
    disp('success');
else
    error('failed');
end

opt.argPermute = [2 3 1];
result = eachElem(s, 'add3', {1:10 11:20; 21:30 31:40}, 1, opt);
if result{1} == (11:20)+1+(1:10)
    disp('success');
else
    error('failed');
end

if result{2} == (31:40)+1+(21:30)
    disp('success');
else
    error('failed');
end

result = eachElem(s, 'minus3', {1:10 11:20; 21:30 31:40}, 1, opt);
if result{1} == (11:20)-1-(1:10)
    disp('success');
else
    error('failed');
end

if result{2} == (31:40)-1-(21:30)
    disp('success');
else
    error('failed');
end

stop(s)

end

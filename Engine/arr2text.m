function t = arr2text(x)
% t = arr2text(x)
%
% Convert back any array x to MATLAB expression t
%
%   Author: Giuseppe Palma
%   Date: 22/04/2022

t = '';
n = ndims(x);
if iscell(x)
    b = '{}';
elseif ischar(x)
    if isrow(x)
        b = '  ';
    elseif isempty(x)
        b = '''''';
    else
        b = '[]';
    end
elseif isscalar(x)
    b = '  ';
else
    b = '[]';
end
if n > 2
    ix = repmat({':'}, 1, n - 1);
    t = [t 'cat(' num2str(n) ', '];
    for i = 1 : size(x, n) - 1
        t = [t arr2text(x(ix{:}, i)) ', '];
    end
    t = [t arr2text(x(ix{:}, size(x, n))) ')'];
elseif isempty(x)
    t = [t b];
else
    t = [t b(1)];
    for i = 1 : size(x, 1) - 1
        t = [t row2text(x(i, :)) '; '];
    end
    t = [t row2text(x(size(x, 1), :)) b(2)];
end
t = t(1 + (t(1) == ' ') : end - (t(end) == ' '));

function t = row2text(x)
t = '';
if iscell(x)
    f = @(i) arr2text(x{i});
elseif isnumeric(x)
    f = @(i) num2str(x(i));
end
if iscell(x) || isnumeric(x)
    for i = 1 : numel(x)
        t = [t f(i) ' '];
    end
    t(end) = '';
elseif ischar(x)
    t = ['''' x ''''];
else
    t = ['##' strtrim(evalc('disp(x)')) '##'];
end
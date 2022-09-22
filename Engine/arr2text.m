function t = arr2text(x, ~)
% t = arr2text(x)
%
% Convert back any array x to MATLAB expression t
%
%   Author: Giuseppe Palma
%   Date: 09/05/2022

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
        t = [t arr2text(x(ix{:}, i), true) ', '];
    end
    t = [t arr2text(x(ix{:}, size(x, n)), true) ')'];
elseif isempty(x)
    t = [t b];
else
    t = [t b(1)];
    for i = 1 : size(x, 1) - 1
        t = [t row2text(x(i, :)) '; '];
    end
    try
        t = [t row2text(x(size(x, 1), :)) b(2)];
    catch err
        if ~strcmp(err.message, 'Parentheses indexing is not allowed')
            rethrow(err)
        end
        t = [t '##' strtrim(evalc('disp(x)')) '##' b(2)];
    end
end
t = t(1 + (t(1) == ' ') : end - (t(end) == ' '));
if nargin < 2 && isnumeric(x) && ~isa(x, 'double')
    t = [class(x) '(' t ')'];
end

function t = row2text(x)
t = '';
if iscell(x)
    f = @(i) arr2text(x{i});
elseif isnumeric(x)
    f = @(i) num2str(x(i));
elseif isstruct(x)
    f = @(i) struct2str(x(i));
elseif islogical(x)
    f = @(i) logical2str(x(i));
end
if iscell(x) || isnumeric(x) || isstruct(x) || islogical(x)
    for i = 1 : numel(x)
        t = [t f(i) ' '];
    end
    t(end) = '';
elseif ischar(x)
    t = ['''' x ''''];
else
    t = ['##' strtrim(evalc('disp(x)')) '##'];
end

function x = struct2str(s)
x = cellfun(@(f) ['''' f ''', ' arr2text(dc(s.(f))) ', '], ...
    fieldnames(s), 'UniformOutput', false);
x = ['struct(', x{:}, ')'];
x(end - 2 : end - 1) = '';

function x = dc(x)
if iscell(x)
    x = {x};
end

function x = logical2str(l)
if l
    x = 'true';
else
    x = 'false';
end
function x = norm_fields(x)
if isempty(x) || islogical(x) && ~x
    x = {};
elseif ~iscell(x)
    x = {x};
end
x = x(:)';
end
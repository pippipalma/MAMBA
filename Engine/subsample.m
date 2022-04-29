function s = subsample(s, grain, sample)
% Y = subsample(X, grain, sample)
% ND-array X is first averaged over blocks of size grain (scalar or vector)
% and then sampled at intervals of sample (scalar or vector)
%
%   Author: Giuseppe Palma
%   Date: 17/09/2020

if isempty(s)
    return
end
if nargin < 3
    sample = 1;
end
UO = {'UniformOutput' false};
if iscell(s)
    s = cellfun(@(x) subsample(x, grain, sample), s, UO{:});
    return
end
bl = islogical(s);
nd = ndims(s);
if isscalar(grain)
    grain = grain*ones(1, nd);
end
if isscalar(sample)
    sample = sample*ones(1, nd);
end
sz_f = ceil(size(s)./grain);
ind = num2cell(sz_f.*grain);
s(ind{:}) = 0;
sz_prep = [grain; sz_f];
s = mean(reshape(permute(reshape(s, sz_prep(:)'), ...
    [2*(1 : nd) 2*(1 : nd) - 1]), [sz_f prod(grain)]), nd + 1);
inda = arrayfun(@(x) 1 : sample(x) : sz_f(x), 1 : nd, UO{:});
s = s(inda{:});
if bl
    s = logical(round(s));
end
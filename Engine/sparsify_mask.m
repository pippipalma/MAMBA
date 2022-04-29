function [mask, shrunk_mask] = sparsify_mask(mask, subs)
% [mask, shrunk_mask] = sparsify_mask(mask, subs)
%
% mask: ND mask to be sparsified (subsampled)
% subs: sparsifying logical mask (same size of mask), or scalar or vector
%   (of length = ndims(mask)) defining the intervals for subsampling (in
%   this case, the additional subsampled mask shrunk_mask is returned).
%   (default: 1)

%   Author: Giuseppe Palma
%   Date: 05/04/2022

l = ndims(mask);
if isscalar(subs)
    subs = subs + zeros(1, l);
end
if numel(subs) == l || isnumeric(subs)
    sz = size(mask);
    gr = arrayfun(@(x) 1 : subs(x) : sz(x), 1 : l, 'UniformOutput', false);
    shrunk_mask = mask(gr{:});
    subs = false(sz);
    subs(gr{:}) = true;
end
mask = mask & subs;
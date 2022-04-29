function t = tfce(t, varargin)
% T = tfce(t, options)
%
% Threshold-free cluster enhancement of ND-array t
% T has the same size as t (see option tails for further details)
%
% Options (default):
%   - E: TFCE support power (default: 0.5)
%   - H: TFCE level power (default: 2)
%   - res: number of integration points (default: 100)
%   - mva_dim: multi-contrast dimension (default: N + 1)
%   - tails: scalar or vector specifying the tail for each contrast
%     (1: right; -1: left; 2: both); if tails is a vector and t a
%     single-contrast array, t is replicated along mva_dim (default: 1)
%   - mfix: MD-logical array such that sum(mfix(:)) = numel(single-contrast t)
%     (default: true array of the same size as single-contrast t)
%   - subsampling: scalar or vector (of length = ndims(mfix)) defining the
%     intervals for subsampling of mfix (default: 1)
%   - C: connectivity (default: 3^M - 1)
%
%   Author: Giuseppe Palma
%   Date: 02/10/2020

s = opt_pars('res', 100, 'mva_dim', ndims(t) + 1, 'tails', 1, varargin{:});
sz = size(t);
l = size(t, s.mva_dim);
if isscalar(s.tails)
    s.tails = s.tails + zeros(l, 1);
elseif l == 1
    l = numel(s.tails);
    ns = ones(1, max(2, s.mva_dim));
    ns(s.mva_dim) = l;
    t = repmat(t, ns);
end
sz(s.mva_dim) = 1;
s = opt_pars('mfix', squeeze(true(sz)), 'subsampling', 1, s);
[~, s.mfix] = sparsify_mask(s.mfix, s.subsampling);
I = double(s.mfix);
s = opt_pars('H', 2, 'E', .5, 'C', 3^ndims(I) - 1, s);
ss = keep_rem(s, {'res' 'H' 'E' 'C'});
inx(1 : ndims(t)) = {':'};
for i = 1 : l
    inx{s.mva_dim} = i;
    I(s.mfix) = t(inx{:});
    if s.tails(i) == 2
        dh = max(abs(I(:)))/s.res;
        T = tfcep(I, ss, dh) - tfcep(-I, ss, dh);
    else
        st = sign(s.tails(i));
        dh = max(st*I(:))/s.res;
        T = st*tfcep(st*I, ss, dh);
    end
    t(inx{:}) = reshape(T(s.mfix)*dh, sz);
end

function T = tfcep(I, s, dh)
I = max(0, I);
T = zeros(size(I));
for h = dh*(1 : s.res)
    CC = bwconncomp(I >= h, s.C);
    if CC.NumObjects == 0
        break
    end
    integ = cellfun(@numel, CC.PixelIdxList).^s.E*h^s.H;
    for c = 1 : CC.NumObjects
        T(CC.PixelIdxList{c}) = T(CC.PixelIdxList{c}) + integ(c);
    end
end
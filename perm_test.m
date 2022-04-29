function p = perm_test(data, labels, varargin)
% p = perm_test(data, outcome_names, options)
% p = perm_test(EVs, outcomes, options)
%
% Options:
%   - dump2file
%   - N
%   - perm_EVs
%   - perm_outcomes
%   - perm_test_workers
%   - rng
%   - tails
%   - tfce
%   Further options are shared with functions VBmodel, standard_out_EV and
%   tfce.
%
%   Author: Giuseppe Palma
%   Date: 28/04/2022

o = opt_pars('tails', 1, 'tfce', true, 'N', 1e4, 'rng', 'shuffle', ...
    'perm_test_workers', inf, 'progress_bar', true, ...
    'dump2file', '', varargin{:});
wk = parfor_det(o.perm_test_workers);
vbo = VBmodel([], [], o, 'VBmodel_proc_opt', true);
o = opt_pars('perm_EVs', vbo.EVOIs, 'perm_outcomes', [], o);
[data, labels, msk, ix, s] = ...
    standard_out_EV(data, labels, o, 'keep_all_voxels', true, ...
    'EVs_inx', keep_rem(o, {'EVOIs' 'perm_EVs' 'perm_outcomes'}));
o.mfix = s.mfix;
o.EVOIs = ix.EVOIs;
o.vars = ':';
o_VBm = {{} {'mfix' true}};
o_tfce = {{'subsampling' 1} {}};
f = @(d, l, i) sign(o.tails(:)).*VBmodel(d, l, o, 'subsampling', 1, o_VBm{i}{:});
o.tails = abs(o.tails);
if o.tfce
    f = @(d, l, i) tfce(f(d, l, i), o, o_tfce{i}{:}, 'mva_dim', 1);
end
f = @(d, l, i) abs2(f(d, l, i), o.tails);
T0 = f(struct('variables', data, 'msk', msk), labels, 1);
L = size(data, 1);
ip = 1 : o.N;
s = RandStream('mt19937ar', 'Seed', o.rng);
p = cell2mat(arrayfun(@(x) randperm(s, L), ip', 'UniformOutput', false));
[t, N, I] = dump(o.dump2file);
n = min(o.N, numel(t));
if max(I) > o.N
    I = 1 : n;
    [t, N] = dump(N, t(I), I);
    if ~strcmpi(o.rng, 'shuffle')
        warning('The effective permutation stream has changed')
    end
end
ip(I) = [];
p(I, :) = [];
T = NaN(size(T0, 1), 1, o.N + 1);
T(:, 1, end - n : end) = cat(3, t{:}, max(T0, [], 2));
n = o.N - n;
if n
    [data, labels, msk, ~, s] = standard_out_EV(data, labels, o);
    if any(s.subsampling - 1)
        corr = T(:, 1, end)./max(f(struct('variables', data, 'msk', msk), labels, 2), [], 2);
    else
        corr = 1;
    end
    ppm = ProgrBar(o.progress_bar, 'create', n, wk, 'Permutation test', 1);
    parfor (i = 1 : n, wk)
        d = data;
        d(:, :, ix.perm_EVs) = d(p(i, :), :, ix.perm_EVs);
        l = labels;
        l(:, :, ix.perm_outcomes) = l(p(i, :), :, ix.perm_outcomes);
        T(:, 1, i) = dump(N, corr.*max(f(struct('variables', d, 'msk', msk), l, 2), [], 2), ip(i));
        ProgrBar(ppm, 'update')
    end
    ProgrBar(ppm, 'delete')
end
dump(N)
p = mean(T >= T0, 3) + isnan(T0);

function x = abs2(x, tails)
x(tails == 2, :) = abs(x(tails == 2, :));
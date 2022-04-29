function [stat, sf] = VBmodel(d, l, varargin)
% [stats_array, codec] = VBmodel(data, outcome_names, options)
% [stats_array, codec] = VBmodel(EVs, outcomes, options)
%
% Options:
%   - distr
%   - EVOIs
%   - fit_pars
%   - model
%   - outs
%   - progress_bar
%   - VBmodel_workers
%   Further options are shared with function standard_out_EV.
%
%   Author: Giuseppe Palma
%   Date: 26/04/2022

o = opt_pars('model', 'glm', 'outs', 't', 'fit_pars', {}, 'EVOIs', {}, ...
    'VBmodel_workers', inf, 'progress_bar', true, ...
    'VBmodel_proc_opt', false, varargin{:});
if o.VBmodel_proc_opt
    stat = o;
    return
end
if ~iscell(o.outs)
    o.outs = {o.outs};
end
[d, l, msk, EVs_inx] = standard_out_EV(d, l, o, 'EVs_inx', o.EVOIs);
lg = islogical(msk);
n_vox = size(d, 2);
fp = o.fit_pars;
dd = default_distr(squeeze(l(:, 1, :)));
if all(strcmpi({o.model dd}, {'glm' 'cox'}))
    o.model = 'cox';
end
model = o.model;
if strcmpi(model, 'cox')
    o.outs(strcmp('t', o.outs)) = {'z'};
    if size(l, 3) == 1
        l(:, :, 2) = 0;
    end
elseif strcmpi(model, 'anova')
    o.outs(strcmp('t', o.outs)) = {'f'};
elseif strcmpi(model, 'glm')
    o = opt_pars('distr', dd, o);
    fp = [o.distr fp];
else
    fp = [size(l, 3) fp];
end
if isempty(EVs_inx)
    EV = {};
else
    EV = {o.outs ones(size(EVs_inx))};
end
[s, nc] = fn(squeeze(d(:, 1, :)), squeeze(l(:, 1, :)), true(size(l(:, 1))), ...
    fp, model, EV{:});
if nc
    EV{2} = EVs_inx + nc - size(d, 3);
end
sf = cellfun(@(x) {x size(s.(x))}, o.outs(:), 'UniformOutput', false);
stat = NaN(sum(cellfun(@(x) prod(x{2}), sf)), n_vox);
wk = parfor_det(o.VBmodel_workers);
ppm = ProgrBar(o.progress_bar, 'create', n_vox, wk, 'Voxelwise model', 1);
parfor (j = 1 : n_vox, wk)
    lastwarn('')
    if lg
        m = msk(:, j);
        w = [];
    else
        m = msk(:, j) > 0;
        w = msk(:, j);
    end
    if any(m)
        s = fn(squeeze(d(:, j, :)), [squeeze(l(:, j, :)) w], m, fp, model, EV{:});
        stat(:, j) = cell2mat(cellfun(@(x) double(s.(x{1})(:)), sf, ...
            'UniformOutput', false));
    end
    if ~isempty(lastwarn)
        fprintf('Warning raised for voxel #%d\n', j)
    end
    ProgrBar(ppm, 'update')
end
ProgrBar(ppm, 'delete')

function [s, nc] = fn(dm, l, m, fp, model, outs, EVs_inx)
if strcmpi(model, 'anova')
    tv = dm(m, EVs_inx);
    dm(:, EVs_inx) = [];
    sz = size(dm, 2);
    g = {l(m)};
    if sz
        g = [g mat2cell(dm(m, :), sum(m), ones(1, sz))];
    end
    [~, tbl] = anovan(tv, g, 'display', 'off', fp{:});
    s.f = cell2mat(tbl(2 : 2 + sz, strcmp(tbl(1, :), 'F')));
    EVs_inx = 1;
elseif strcmpi(model, 'cox')
    if size(l, 2) > 2
        fp = ['Frequency' l(m, 3) fp];
    end
    [~, ~, ~, s] = coxphfit(dm(m, :), l(m, 1), 'Censoring', l(m, 2), fp{:});
elseif strcmpi(model, 'glm')
    if size(l, 2) > 1
        fp = [fp 'Weights' l(m, 2)];
    end
    [~, ~, s] = glmfit(dm(m, :), l(m, 1), fp{:});
else
    s = model(dm(m, :), l(m, 1 : fp{1}), l(m, fp{1} + 1 : end), fp{2 : end});
end
nc = 0;
if nargin > 5
    for i = outs
        if ~isscalar(s.(i{:}))
            nc = size(s.(i{:}), 1);
            s.(i{:}) = s.(i{:})(EVs_inx, :);
        end
    end
end
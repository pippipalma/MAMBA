function [d, l, msk, EVs_inx, s] = standard_out_EV(d, l, varargin)
% [EVs, outcomes, patient_masks, EVs_inx, options] = ...
%    standard_out_EV(data, outcomes, options)
%
% Standardize variables for VBmodel and perm_test
%
% data: variables in a form suitable for function destr
% outcomes: model outcomes in form of
%   - an input suitable for function destr;
%   - cell array with the list of variable names (in this case, data is
%     required to be a table) or variable indices (in this case, data is
%     allowed to be a generic input of function destr).
%
% Options:
%   - dim_vars_outcomes: scalar integer specifying the dim_vars option of
%     destr for the outcomes if this comes in a form suitable for destr
%     (default is left to destr)
%   Further options are specific of function destr
%
%   Author: Giuseppe Palma
%   Date: 20/04/2022

o = opt_pars(varargin{:});
dv = {'rc_name' 'outcomes' 'EVs_inx'};
rl = {'rc_name' 'EVs'};
if isfield(o, 'EVs_inx') && isfield(o.EVs_inx, 'perm_outcomes')
    dv = [dv {o.EVs_inx.perm_outcomes}];
    o.EVs_inx = rmfield(o.EVs_inx, 'perm_outcomes');
else
    dv = [dv {{}}];
end
if ischar(l) || iscell(l)
    rl = [rl {'labels' l}];
    [l, ~, l_inx, S] = destr(d, o, 'vars', l, dv{:});
else
    if istable(d) && ~isempty(d.Properties.RowNames) && ...
            istable(l) && ~isempty(l.Properties.RowNames)
        nd = d.Properties.VariableNames;
        nl = l.Properties.VariableNames;
        d = innerjoin(d, l, 'Keys', 'Row');
        l = d(:, end - width(l) + 1 : end);
        d(:, end - width(l) + 1 : end) = [];
        l.Properties.VariableNames = nl;
        d.Properties.VariableNames = nd;
    end
    if isfield(o, 'dim_vars_outcomes')
        dv = [dv {'dim_vars' o.dim_vars_outcomes}];
    end
    [l, ~, l_inx, S] = destr(l, keep_rem(o, [], 'dim_vars'), 'vars', ':', dv{:});
end
[d, msk, EVs_inx, s] = destr(d, o, rl{:});
if isstruct(EVs_inx)
    EVs_inx.perm_outcomes = l_inx;
end
sd = size(d, 2);
sl = size(l, 2);
if sl ~= sd
    if sd == 1
        d = repmat(d, 1, sl);
        msk = repmat(msk, 1, sl);
        s.mfix = S.mfix;
    elseif sl == 1
        l = repmat(l, 1, sd);
    else
        error('Size mismatch between outcomes and EVs.')
    end
end
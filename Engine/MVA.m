function [vars, log_m] = MVA(T, outcome, varargin)
% vars = MVA(T, outcome, varargin)
%
% MVA for variable selection; non-scalar variables automatedly enter.
%
%   Author: Giuseppe Palma
%   Date: 08/10/2021

opt = opt_pars('MVA_scheme', 'lasso', 'vars', T.Properties.VariableNames, ...
    varargin{:});
if ~iscell(opt.vars)
    opt.vars = {opt.vars};
end
if isempty(opt.vars)
    vars = opt.vars;
    log_m = [];
    return
end
arr = any(cellfun(@(x) numel(x) > 1, T{:, opt.vars}));
vars = opt.vars(arr);
opt.vars(strcmp(outcome, opt.vars) | arr) = [];
if strcmpi(opt.MVA_scheme, 'lasso')
    for i = keep_rem(T.Properties.VariableNames, opt.vars, [])
        T.(i{:}) = cell2mat(T.(i{:}));
    end
    l = cell2mat(T.(outcome{:}));
    opt = opt_pars('lasso_distr', default_distr(l), 'lasso_opt', {}, opt);
    [B, log_m] = lassoglm(T{:, opt.vars}, l, opt.lasso_distr, ...
        'CV', min(10, height(T)), 'MCReps', 100, opt.lasso_opt{:});
    vars = [opt.vars(logical(B(:, log_m.Index1SE))) vars];
else
    opt = opt_pars('cut_R', .7, 'cut_p', .1, opt, 'CV', false);
    [~, log_m] = model(T, outcome, opt, 'type', 'logistic');
    vars = [log_m.details.M.m.Formula.PredictorNames vars];
end
function s = tstat2(d, l, ~, varargin)
% stats = model_prototype(EVs, outcomes, masks, options)
%
% stats: model statistics, returned as a structure
%
% EVs, outcomes, masks: each in the form of [#patients #variables] array
% Options: in a form suitable for opt_pars

o = opt_pars('tail', 'right', varargin{:});
s1 = sum(l);
s0 = size(d, 1) - s1;
m1 = sum(d.*l)./s1;
m0 = sum(d.*~l)./s0;
s.delta = (m1 - m0)*(1 - 2*strcmpi(o.tail, 'left'));
s.t = s.delta./sqrt(sum((d - m1).^2.*l)./(s1.*(s1 - 1)) + ...
    sum((d - m0).^2.*~l)./(s0.*(s0 - 1)));
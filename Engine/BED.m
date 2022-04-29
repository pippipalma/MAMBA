function bed = BED(D, n, asub, a, t, tk, tp)
% bed = BED(D, n, asub, a, t, tk, tp)
if nargin < 7 || isempty(tp)
    tp = inf;
end
if nargin < 6 || isempty(tk)
    tk = 0;
end
if nargin < 5 || isempty(t)
    t = 0;
end
if nargin < 4 || isempty(a)
    a = inf;
end
if nargin < 3 || isempty(asub)
    asub = 3;
end
if nargin < 2 || isempty(n)
    n = inf;
end
bed = D.*(1 + D./(n.*asub)) - log(2)*(t - tk)./(a.*tp);
function s = censoring_event(tt, vn, end_follow_up, treatment_date, use_fit)
if isempty(tt)
    s.x = [];
    s.d = [];
else
    if nargin < 5
        use_fit = true;
    end
    tt = sortrows(tt);
    n = tt.Properties.DimensionNames{1};
    ti = cell2mat(cellfun(@(x) x(:)', tt{:, vn}, 'UniformOutput', false));
    sz = size(tt{1, vn}{:});
    time = days(tt.(n)(:) - treatment_date);
    fup = days(end_follow_up - treatment_date);
    if use_fit
        if isscalar(time)
            s.x = [];
            s.d = [];
        else
            t2e = [ones(size(time)) -time]\log(abs(ti));
            t2e = log(500/400)./t2e(2, :);
            t2e(isnan(t2e)) = inf;
            s.x = reshape(t2e > fup, sz);
            s.d = repmat(fup, sz);
            s.d(~s.x) = t2e(~s.x);
        end
    else
        s.d = repmat(time, 1, size(ti, 2));
        s.d(ti < -400) = inf;
        s.d = min(s.d, [], 1);
        s.x = reshape(s.d == inf, sz);
        s.d(s.x) = fup;
        s.d = reshape(s.d, sz);
    end
end
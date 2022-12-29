function H = ProgrBar(h, op, it, wk, tit, T)
% h = ProgrBar(h, operation, iterations, workers, title, refresh_time)
%
%   Author: Giuseppe Palma
%   Date: 27/12/2022

if islogical(h) && ~h
    if nargout
        H = h;
    end
    return
end
persistent c t_beg N ti
switch lower(op)
    case 'create'
        if ~isempty(N) || is_in_parallel || wk && ~isICT
            H = false;
            return
        end
        N = it;
        ti = get(0, 'defaulttextInterpreter');
        set(0, 'defaulttextInterpreter', 'none')
        if wk
            H = ParforProgressbar(N, 'showWorkerProgress', true, ...
                'progressBarUpdatePeriod', T, 'title', tit);
        else
            c = 0;
            if isscalar(N) && iscell(tit)
                t_beg = tic;
                H = waitbar(0, 'Just started...', 'Name', tit{1});
            else
                if ischar(tit)
                    tit = {tit};
                end
                t(1 : numel(N)) = {''};
                t(1 : min(end, numel(tit))) = tit(1 : min(end, numel(t)));
                N = cumprod(N, 'reverse');
                progressbar(t{:})
                H = h;
            end
        end
    case 'update'
        if isempty(c)
            h.increment
        else
            c = c + 1;
            if isempty(t_beg)
                a = num2cell((mod(c - 1, N) + 1)./N);
                progressbar(a{:})
            else
                if nargin < 3
                    it = [num2str(100*c/N, '%.2f') '% completed; ' ...
                    sec2timestr(toc(t_beg)*(N - c)/c) ' remaining...'];
                end
                waitbar(c/N, h, it)
            end
        end
    case 'delete'
        if isempty(c) || ~isempty(t_beg)
            delete(h)
        else
            progressbar(1)
        end
        set(0, 'defaulttextInterpreter', ti)
        clear c t_beg N ti
end
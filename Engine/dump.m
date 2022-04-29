function [T, N, I] = dump(f, T, I)
if nargout > 1
    if nargin > 1
        dump(f)
    end
    if nargin < 2
        T = {};
    end
    if nargin < 3
        I = [];
    end
    ic = ischar(f);
    N = ic || f;
    if N
        if ic && ~isempty(f)
            N = f;
        else
            [~, N] = fileparts(tempname);
            fprintf('The max_T values will be dynamically stored in ''%s''\n', N)
        end
        [~, Nn] = fileparts(N);
        if ~isfolder(N)
            mkdir(N)
        end
        f = fullfile(N, '*.mat');
        d = dir(f);
        for j = 1 : length(d)
            if ~strcmp(d(j).name(1 : numel(Nn)), Nn)
                error('The dump folder contains non-standard MAT-files')
            end
        end
        D = arrayfun(@(x) load(fullfile(N, x.name), 't', 'i'), d);
        if ~isempty(D)
            T = [D.t];
            I = [D.i];
            fprintf('%d values were recovered from previous runs\n', numel(T))
        end
        delete(f)
        t = T(:)';
        i = I(:)';
        save(fullfile(N, Nn), 't', 'i')
    end
elseif nargout
    if f
        if is_in_parallel
            j = getCurrentTask;
            j = j.ID;
        else
            j = 0;
        end
        [~, Nn] = fileparts(f);
        f = fullfile(f, [Nn num2str(j)]);
        if isfile([f '.mat'])
            load(f, 't', 'i')
        else
            t = [];
            i = [];
        end
        t = [t {T}];
        if nargin > 2
            i = [i I];
        end
        save(f, 't', 'i')
    end
elseif ischar(f)
    rmdir(f, 's')
end
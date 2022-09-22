function IDs = ID_select(folder, ID_include, ID_exclude, ext)
if nargin < 2
    ID_include = '*';
end
if nargin < 3
    ID_exclude = '';
end
if nargin < 4
    ext = 'mat';
end
fold_char = ischar(folder);
IDs = unique(proc_ID(ID_include));
[i, ~] = find(string(IDs) == string(proc_ID(ID_exclude))');
IDs(i) = [];

function N = proc_ID(ID)
    UO = {'UniformOutput' false};
    if isnumeric(ID)
        N = arrayfun(@num2str, ID(:), UO{:});
        if fold_char
            set = arrayfun(@(x) id(x.name), dir(fullfile(folder, ['*.' ext])), UO{:});
        else
            set = name_match(folder, '*');
        end
        [I, ~] = find(string(N) == string(set(:))');
        N = N(I);
    elseif ischar(ID)
        if fold_char
            N = arrayfun(@(x) id(x.name), dir(fullfile(folder, [ID '.' ext])), UO{:});
        else
            N = name_match(folder, ID);
        end
    else
        N = {};
        for I = 1 : length(ID)
            NN = proc_ID(ID{I});
            N = [N; NN(:)];
        end
    end
end
end

function x = id(x)
[~, x] = fileparts(x);
end
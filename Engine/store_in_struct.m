function X = store_in_struct(v)
for i = 1 : numel(v)
    X.(v{i}) = evalin('caller', v{i});
end
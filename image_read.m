function [img, CCS, img_pre] = image_read(varargin)
% [img_sn, CCS, img_pre] = image_read(options)
%
% Options:
%   - ID_exclude
%   - ID_include
%   - images
%   - join_images
%   - masks
%   - mobile_masks
%   - path_proc
%   - progress_bar
%   - sigma
%   - smooth_mobile_masks
%   - subsample_grain
%   - template_images
%   - time_images
%
%   Author: Giuseppe Palma
%   Date: 20/04/2022

def = {'path_proc' '' 'ID_include' '*' 'ID_exclude' [] ...
    'join_images' true 'masks' {} 'template_images' 'ct' 'images' 'dose' ...
    'mobile_masks' {} 'time_images' false 'sigma' 5 ...
    'smooth_mobile_masks' true 'subsample_grain' 1 'progress_bar' true};
s = opt_pars(def{:}, varargin{:});
moving = fullfile(s.path_proc, 'cohort');
IDs = norm_fields(ID_select(moving, s.ID_include, s.ID_exclude));
img = table('RowNames', IDs);
if s.join_images
    s.masks = norm_fields(s.masks);
    s.template_images = norm_fields(s.template_images);
    s.images = norm_fields(s.images);
    s.mobile_masks = norm_fields(s.mobile_masks);
    s.time_images = norm_fields(s.time_images);
    ff = [s.masks s.template_images s.images {'vox'}];
    CCS = load(fullfile(s.path_proc, 'template.mat'), ff{:});
    ref = keep_rem(fieldnames(CCS), ff, 'vox');
    sz = size(CCS.(ref{1}));
    if ~isfield(CCS, 'vox')
        CCS.vox = 1;
    end
    names = [s.images s.mobile_masks s.time_images];
    sigma = s.sigma./CCS.vox;
    s.subsample_grain = round(max(1, s.subsample_grain));
    CCS.vox = CCS.vox.*s.subsample_grain;
    for i = ref(:)'
        CCS.(i{:}) = ss(CCS.(i{:}));
    end
    if nargout > 2
        img_pre = rd('pre');
    end
    img = rd('sn');
else
    img_pre = img;
end
s.image_read_default = def;
CCS.config = s;
    function x = rd(data)
        x = img;
        x{:, s.images} = {[]};
        if any(sigma) && s.smooth_mobile_masks
            x{:, s.mobile_masks} = {zeros(sz)};
        else
            x{:, s.mobile_masks} = {false(sz)};
        end
        x{:, s.time_images} = {timetable};
        ppm = ProgrBar(s.progress_bar, 'create', numel(IDs), false, ['Reading ' data]);
        for I = IDs
            D = load(fullfile(moving, I{:}), data);
            for J = names
                if isfield(D.(data), J{:})
                    if strcmp(J{:}, s.time_images)
                        for K = 1 : height(D.(data).(J{:}))
                            D.(data).(J{:}){K, 'Images'}{:}...
                                (isnan(D.(data).(J{:}){K, 'Images'}{:})) = 0;
                        end
                    else
                        D.(data).(J{:})(isnan(D.(data).(J{:}))) = 0;
                    end
                    x{I{:}, J{:}} = {D.(data).(J{:})};
                elseif ~any(strcmp(J, s.mobile_masks))
                    warning(['Missing field ''' J{:} ''' in ' data ...
                        ' of patient ' I{:}])
                end
            end
            ProgrBar(ppm, 'update')
        end
        ProgrBar(ppm, 'delete')
        x{:, s.images} = ss(sm(x{:, s.images}, ['Processing images in ' data]));
        if ~isempty(s.mobile_masks)
            if s.smooth_mobile_masks
                x{:, s.mobile_masks} = sm(x{:, s.mobile_masks}, ...
                    ['Processing mobile masks in ' data]);
            end
            x{:, s.mobile_masks} = ss(x{:, s.mobile_masks});
        end
        if ~isempty(s.time_images)
            ppm = ProgrBar(s.progress_bar, 'create', numel(IDs), false, ...
                ['Processing timetable in ' data]);
            for I = IDs
                if ~isempty(x{I{:}, s.time_images{:}}{:})
                    x{I{:}, s.time_images{:}}{:}{:, 'Images'} = ...
                        ss(sm(x{I{:}, s.time_images{:}}{:}{:, 'Images'}));
                end
                ProgrBar(ppm, 'update')
            end
            ProgrBar(ppm, 'delete')
        end
    end
    function x = sm(x, p)
        if any(sigma)
            if nargin < 2
                a = {};
            else
                a = {'process' p};
            end
            k = sph(sigma(:).*ones(ndims(CCS.(ref{1})), 1), 'gauss');
            x = local_moments(x, k, 'progress_bar', s.progress_bar, a{:});
        end
    end
    function x = ss(x)
        if any(s.subsample_grain > 1)
            x = subsample(x, s.subsample_grain);
        end
    end
end
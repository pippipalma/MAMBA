function synthetic_cohort(varargin)

% Options (in a form suitable for opt_pars function):
%   - clin_table: demographic and clinical table or MAT-file containing it
%     (default: 'clin.mat').
%   - path_proc: folder of destination containing template (template.mat)
%     and cohort (in subfolder 'cohort\*.mat') images (default: '').
%   - N_pat: number of patients (default: 500).
%   - image_size: size of the images (default: [128 128 64]).
%   - progress_bar: flag for displaying the progress bar (default: true).
%   - time_images: flag for generating the time images (default: true).
%   - rng: seed for the MATLAB random number generator (default: 1).

o = opt_pars('clin_table', 'clin.mat', 'path_proc', '', 'N_pat', 500, ...
    'image_size', [128 128 64], 'progress_bar', true, 'time_images', true, ...
    'rng', 1, varargin{:});
S = RandStream('mt19937ar', 'Seed', o.rng);
sz = [o.N_pat 1];
UO = {'UniformOutput' false};
sex = rand(S, sz) > .5;
CHT = rand(S, sz) > .5;
weight = round(70 + 10*randn(S, sz));
weight(rand(S, sz) < .1) = nan;
inx_high_dose = rand(S, sz) > .5;
recurrence = -inx_high_dose - 1.5*CHT + 2*randn(S, sz);
recurrence = recurrence > prctile(recurrence, 65);
y = randi(S, 60, sz);
m = randi(S, 12, sz);
d = randi(S, 31, sz);
birth_date = datetime(1920 + y, m, d);
treatment_date = birth_date + round(365*(40 + 10*randn(S, sz)));
toxicity_date = treatment_date + round(365*exp(.2*sex - inx_high_dose - .5*CHT + 1.7*randn(S, sz)));
fu = 100 + randi(S, 400, sz);
end_follow_up = treatment_date + fu;
toxicity = toxicity_date <= end_follow_up;
toxicity_date(~toxicity) = NaT;
np = arrayfun(@(x) ['Pat' num2str(x)], 1 : o.N_pat, UO{:});
T = table(birth_date, treatment_date, weight, sex, CHT, recurrence, ...
    end_follow_up, toxicity, toxicity_date, 'RowNames', np);
s = fileparts(o.clin_table);
if ~isfolder(s)
    mkdir(s)
end
save(o.clin_table, 'T')
v = false(o.image_size);
s = size(v, 1 : 3);
vox = 512./s;
dose_box = v;
dose_box(ceil(.45*s(1) : .55*s(1)), ceil(.15*s(2) : .85*s(2)), ceil(.35*s(3) : .65*s(3))) = true;
heart = v;
i = {ceil(.4*s(1) : .6*s(1)) ceil(.4*s(2) : .7*s(2)) ceil(.4*s(3) : .6*s(3))};
sp = sph(floor(cellfun(@numel, i)/2));
i = arrayfun(@(x) floor(min(i{x})) + (1 : size(sp, x)), 1 : 3, UO{:});
heart(i{:}) = sp;
left_lung = v;
left_lung(ceil(.05*s(1) : .95*s(1)), ceil(.55*s(2) : .95*s(2)), ceil(.05*s(3) : .95*s(3))) = true;
left_lung = left_lung & ~heart;
right_lung = v;
right_lung(ceil(.05*s(1) : .95*s(1)), ceil(.05*s(2) : .45*s(2)), ceil(.05*s(3) : .95*s(3))) = true;
right_lung = right_lung & ~heart;
lung = left_lung | right_lung;
CT = 40*heart - 500*lung;
c = fullfile(o.path_proc, 'cohort');
mkdir(c)
save(fullfile(o.path_proc, 'template.mat'), 'vox', 'heart', 'left_lung', 'right_lung', 'CT')
kd = sph(round(10./vox));
kt = sph(ceil(20./vox));
gr = linspace(-1, 1, s(2));
ppm = ProgrBar(o.progress_bar, 'create', o.N_pat, false, 'Synthetic Cohort');
for i = 1 : o.N_pat
    tumor = v;
    tumor(ceil(.45*s(1) : .55*s(1)), ceil(.45*s(2) : .55*s(2)), ceil(.45*s(3) : .55*s(3))) = true;
    tumor = circshift(tumor, round(rand(S, 1, 3).*s));
    dose = local_moments(1 + randn(S, s) + morph(tumor, kt) + ...
        inx_high_dose(i)*dose_box, kd);
    r = randn(S);
    spect = abs(heart.*(1 - dose/4*(1 + .75*r)*(rand(S) > .5)));
    if o.time_images
        ti = cumsum(randi(S, 150, 500, 1));
        ti(ti > fu(i)) = [];
        Images = arrayfun(@(x) CT.*exp(-(2 + dose.*gr + .5*randn(S, s)).*lung*x/800), ti, UO{:});
        ti = ti + treatment_date(i);
        Types = repmat({'CT'}, size(Images));
        tt_imaging = timetable(ti, Types, Images);
        tti = {'tt_imaging'};
    else
        tti = {};
    end
    sv = {'tumor' 'spect'};
    sv = sv(rand(S, size(sv)) > .05);
    sn = store_in_struct(['dose' tti{:} sv]);
    save(fullfile(c, np{i}), 'sn')
    ProgrBar(ppm, 'update')
end
ProgrBar(ppm, 'delete')
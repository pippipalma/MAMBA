clear
%%% test1
description = 'glm on global binary outcome without mfix and additional EVs';
template_images = 'CT';
images = 'dose';
outcome = 'toxicity';
EVOIs = 'dose';
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test1.mat')
clear

%%% test2
description = 'glm on global binary outcome';
masks = {'heart' 'left_lung' 'right_lung'};
images = 'dose';
mobile_masks = 'tumor';
der_vars = {{'age_at_start' {'years' {'-' 'treatment_date' 'birth_date'}}}};
outcome = 'recurrence';
clin_vars = {'CHT' 'weight' 'sex'};
vars = {'age_at_start' images};
EVOIs = 'dose';
tails = -1;
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test2.mat')
clear

%%% test3
description = 't-test on global outcome';
masks = {'heart' 'left_lung' 'right_lung'};
images = 'dose';
der_vars = {{'adult' {'>' {'years' {'-' 'treatment_date' 'birth_date'}} 18}}};
outcome = 'recurrence';
select_patients = 'adult';
EVOIs = 'dose';
model = @tstat2;
fit_pars = {'tail' 'left'};
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test3.mat')

clear
%%% test4
descritpion = 'glm on global continuous outcome';
masks = {'heart' 'left_lung' 'right_lung'};
images = 'dose';
mobile_masks = 'tumor';
der_vars = {{'age_at_start' {'years' {'-' 'treatment_date' 'birth_date'}}} ...
{'time_to_event' {'days' {'-' {'first' 'toxicity_date' 'end_follow_up'} 'treatment_date'}}} ...
} ;
outcome = 'time_to_event';
clin_vars = {{'weight' 'sex' 'age_at_start'} 'sex' 'CHT'};
EVOIs = 'dose';
distr = 'poisson';
tails = -1;
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test4.mat')

clear
%%% test5
description = 'cox with global time to event and censoring';
masks = {'heart' 'left_lung' 'right_lung'};
images = 'dose';
mobile_masks = 'tumor';
der_vars = {
{'time_to_event' {'days' {'-' {'first' 'toxicity_date' 'end_follow_up'} 'treatment_date'}}} ...
{'censoring' {'~' 'toxicity'}} ...
} ;
outcome = {'time_to_event' 'censoring'};
clin_vars = {{'weight'}};
vars = {'weight' images};
EVOIs = 'dose';
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test5.mat')

clear
%%% test6
description = 'glm on voxel-based continuous outcome';
masks = 'heart';
images = {'dose' 'spect'};
mobile_masks = 'tumor';
outcome = 'spect';
vars = ['sex' images];
refine_mask = @(x,y) morph(y.heart, sph(1),'e');
EVOIs = 'dose';
tails = -1;
tfce = false;
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test6.mat')

clear
%%% test7
description = 'glm with global EV and voxel-based outcome';
masks = {'heart'};
images = {'spect' 'dose'};
der_vars = {{'mean_heart_dose' {'/' {'sum' {'.*' 'dose' '#heart'} 'all'} {'sum' '#heart' 'all'}}}} ;
outcome = 'spect';
vars = 'mean_heart_dose';
EVOIs = 'mean_heart_dose';
tails = -1;
tfce = false;
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test7.mat')

clear
%%% test8
description = 'cox with voxel-based time to event and censoring';
masks = {'left_lung' 'right_lung'};
images = {'dose'};
mobile_masks = 'tumor';
time_images = 'tt_imaging';
der_vars = {{'VBcox_struct' {'censoring_event' 'tt_imaging' 'Images' 'end_follow_up' 'treatment_date'}}...
    {'VB_censoring' {'getfield' 'VBcox_struct' 'x'}} ...
    {'VB_time2event' {'getfield' 'VBcox_struct' 'd'}} ...
    {'n_time_points' {'>' {'height' 'tt_imaging'} 2}} ...
} ;
outcome = {'VB_time2event' 'VB_censoring'};
select_patients = 'n_time_points';
EVOIs = 'dose';
save('C:\Docs_WS\MATLAB\MedicalImaging\RT\MAMBA\WorkedExamples\test8.mat')
clear
function [cfg, S] = get_cfg(S,EEG_name)

%% Read info for this subject and get file names and dirctories.
rootfilename = which('get_cfg.m');
rootpath     = '/media/sv/';

cfg.dir_main = rootpath;
cfg.subject_name  = EEG_name;
cfg.dir_raw       = [cfg.dir_main 'Raw_eeg/'];
cfg.dir_eeg       = [cfg.dir_main 'Preprocessed_eeg/' cfg.subject_name filesep]; 

%     cfg.dir_behavior  = [cfg.dir_main 'Logfiles/'];
%     cfg.dir_raweye    = [cfg.dir_main 'EDF/'];
%     cfg.dir_eye       = [cfg.dir_main 'EYE/' cfg.subject_name filesep]; 
%     cfg.dir_tf        = [cfg.dir_main 'TF/'  cfg.subject_name filesep]; 
%     cfg.dir_filtbert  = [cfg.dir_main 'Filtbert/' cfg.subject_name filesep];    

%% Data organization and content.
% Triggers that mark stimulus onset. These events will be used for
% epoching.
cfg.trig_target = []; %e.g., [21:29 221:229]; 
cfg.epoch_tmin  = 0; %e.g., -2.000;
cfg.epoch_tmax  = 2.000; %e.g., 0.500;

cfg.genfaketrigger = 1;
cfg.triggernumber  = [12];

% Time limits of epochs.
cfg.bsl_t_min = cfg.epoch_tmin;
cfg.bsl_t_max = 0; 

%% Parameters for data import and preprocessing.
% Indices of channels that contain data, including external electrodes, but not bipolar channels like VEOG, HEOG.
cfg.data_urchans    = [1:257];%[1,3:15,17:50,52:63]; 
cfg.data_chansAfter = [1:203];

% Indices of channels that contain data after rejecting the channels not
% selected in cfg.data_urchans. 
cfg.data_chans = 1:length(cfg.data_urchans);

% Indicate if you want to remove channels
cfg.rmchanels = 0;
cfg.rmchanum  = [];

% what to select bad electrodes à la fieldtrip?
cfg.detectbadchanels = 1;

% Use these channels for computing bipolar HEOG and VEOG channel.
cfg.heog_chans = []; % if empty do nothing
cfg.veog_chans = [];

% Channel location file. If you use your own custom file, you have to
% provide the full path and filename.
cfg.chanlocfile = '/media/sv/Elements/Tonia_backup/raw_data_test/9_18AverageNet256_v1.sfp';%standard-10-5-cap385.elp';

%% Reference
% Do you want to rereference the data at the import step (recommended)?
% Since Biosemi does not record with reference, this improves signal
% quality. This does not need ot be the postprocessing refrence you use for
% subsequent analyses.

% Before ICA:
cfg.ImportReference     = 257;
cfg.do_preproc_reref    = 0;  
cfg.preproc_reference   = 257; % (31=Pz@Biosemi,32=Pz@CustomM43Easycap) AFTER impor
cfg.do_reref_before_ica = 0;  
cfg.do_reref_after_ica  = 1;
cfg.postproc_reference  = [];  % empty = average reference

%% Do you want to have a new sampling rate?
cfg.do_resampling     = 1;
cfg.new_sampling_rate = 512;

%% Interpolate missing channels after ICA:
cfg.interpolMissingChan = 1;
cfg.chanlocsBE4interpol = '/home/sv/Matlabtoolboxes/Analysis_Data_Scripts/Code/chanlocsBE4interpol.mat';
cfg.chanlocsBE4interpol_noRefChan = '/home/sv/Matlabtoolboxes/Analysis_Data_Scripts/Code/chanlocsBE4interpol_noRefChan.mat';

%% Filter parameters
% Do you want to high-pass filter the data?
cfg.do_hp_filter    = 0;
cfg.hp_filter_type  = 'hamming'; % or 'butterworth' - not recommended or hamming or kaiser
cfg.hp_filter_limit = 0.5; 
cfg.hp_filter_tbandwidth = 0.2;
cfg.hp_filter_pbripple = 0.01;

% Do you want to low-pass filter the data?
cfg.do_lp_filter    = 0;
cfg.lp_filter_type  = 'hamming'; % or 'blackman'
cfg.lp_filter_limit = 100; 
cfg.lp_filter_tbandwidth = 5;

% Do you want to bandpass
cfg.bandpass = 1;
cfg.bp_filter_type = 'basicfilter'; % firwsord (band pass is done in once--not recomanded)
                                    % or basicfilter (which is a combination between pop_basicfilter & pop_newfilt)
cfg.lp_filter_limit = 45;
cfg.hp_filter_limit = 1; 

% Do you want to use a notch filter? Note that in most cases Cleanline
% should be sufficient.
cfg.do_notch_filter    = 0;
cfg.notch_filter_lower = 49;
cfg.notch_filter_upper = 51;
cfg.notch_filter_order = []; % try this before with the gui, and change this! as it is related to the EEG.srate

cfg.do_ICA_hp_filter    = 0;
cfg.hp_ICA_filter_type  = 'hamming';
cfg.hp_ICA_filter_limit = 1;

% Do you want to use cleanline to remove 50Hz noise?
cfg.do_cleanline = 0; % avoid if do beamformer

% Do hp before ICA?
cfg.do_ICA_hp_filter = 0;
cfg.hp_ICA_filter_type = 'butterworth';
cfg.hp_ICA_filter_limit = 1;
 

%% Artifact detection:
% Do you want to use linear detrending (requires Andreas Widmann's
% function).?
cfg.do_detrend = 0;

% In case you use automatic artifact detection, do you want to
% automatically delete detected trials or inspect them after deletion?
cfg.rej_auto = 0;

% Visual inspection of the data
cfg.do_visual_inspection_preICA  = 0;
cfg.do_visual_inspection_postICA = 1;

% Do you want to reject trials based on amplitude criterion? (automatic and
% manual)
cfg.do_apmli_rej_preICA = 1;
cfg.do_rej_thresh   = 0;
cfg.rej_thresh_pre  = 400;
cfg.rej_thresh_post = 250;
cfg.rej_thresh_tmin = cfg.epoch_tmin;
cfg.rej_thresh_tmax = cfg.epoch_tmax;

% Do you want to reject trials based on slope?
cfg.do_rej_trend       = 0;
cfg.rej_trend_winsize  = cfg.new_sampling_rate * abs(cfg.epoch_tmin - cfg.epoch_tmax);
cfg.rej_trend_maxSlope = 30;
cfg.rej_trend_minR     = 0; %0 = just slope criterion

% Do you want to reject trials based on joint probability?
cfg.do_rej_prob         = 0;
cfg.rej_prob_locthresh  = 6;
cfg.rej_prob_globthresh = 3; 

% Do you want to reject trials based on kurtosis?
cfg.do_rej_kurt         = 0;
cfg.rej_kurt_locthresh  = 8;
cfg.rej_kurt_globthresh = 4; 


% The SubjectsTable.xlsx contains a column "interp_chans". Do you want to
% interpolate these channels in prep02 (i.e., prior to ICA)?
cfg.do_interp = 0;

% ...If not interpolating, do you want to ignore those channels in
% automatic artifact detection methods? 1 = use only the other channels.
cfg.ignore_interp_chans = 0;

%% Parameters for ICA.
cfg.ica_type     = 'binica';
cfg.ica_extended = 1; % Run extended infomax ICA?
cfg.ica_rank     = 0;
cfg.ica_ncomps   = 0;
cfg.ica_chans    = cfg.data_chans; % Typicaly, ICA is computed on all channels, unless one channel is not really EEG.
cfg.ica_variance = 1;
cfg.amica        = 0;


%[numel(cfg.data_chans)-3]; % if ica_ncomps==0, determine data rank from the ...
% data (EEGLAB default). Otherwise, use a fixed number of components. Note: subject-specific
% settings will override this parameter.

%% Parameters for SASICA.
cfg.sasica_heogchan = num2str(cfg.data_chans+1);
cfg.sasica_veogchan = num2str(cfg.data_chans+2);
cfg.sasica_autocorr = 20;
cfg.sasica_focaltopo = 'auto';

%% Stuff below this line is for experiment-specific analyses.

%% Hilbert-Filter anaylsis
cfg.hilb_flimits       = [5 12];
cfg.hilb_transbwidth   = 2;
cfg.hilb_quant_tlimits = [-0.800 0];
cfg.hilb_quant_chans   = [1:64];
cfg.hilb_quant_nbins   = 2;

%% TF analysis
cfg.tf_chans       = cfg.data_chans;
cfg.tf_freqlimits  = [2 40];
cfg.tf_nfreqs      = 20;
% cfg.tf_freqsout    = linspace(cfg.tf_freqlimits(1), cfg.tf_freqlimits(2), cfg.tf_nfreqs);
cfg.tf_cycles      = [1 6];
cfg.tf_causal      = 'off';
cfg.tf_freqscale   = 'log';
cfg.tf_ntimesout    = 400;
cfg.tf_verbose     = 'off'; % if not specified: overwritten by EP.verbose

%% Reject ICA components
function m04_rejectICs(whichsubject)

filename=[pwd filesep 'Number_of_components_rejected_v2.csv'];
if exist(filename,'file')==2,delete(filename),end
resultfileData = fopen(filename,'at');

    [who_idx,ID,EEG_ID,EEG_name,patient] = get_subjects(whichsubject);

    for isub = 1:length(who_idx)

        % -------------
        % Prepare data.
        % -------------
        cfg = get_cfg(who_idx(isub),EEG_name{isub}); 
        
        % Write a status message to the command line.
        fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',EEG_name{isub},isub,length(who_idx));   

        % Load data set.
        EEG = pop_loadset('filename', [cfg.subject_name '_ICA.set'],'filepath', cfg.dir_eeg, 'loadmode', 'all');
        %% Run SASICA
         [EEG, com] = SASICA(EEG);
    %     [EEG,com] = SASICA(EEG,'MARA_enable',0,'FASTER_enable',0,'FASTER_blinkchanname',[],'FASTER_blinkchans',[],...
    %         'ADJUST_enable',1,...
    %         'chancorr_enable',0,'chancorr_channames',71,'chancorr_corthresh','auto 4',...
    %         'EOGcorr_enable',0,'EOGcorr_Heogchannames',66,'EOGcorr_corthreshH','auto 4','EOGcorr_Veogchannames',67,'EOGcorr_corthreshV','auto 4',...
    %         'resvar_enable',0,'resvar_thresh',15,...
    %         'SNR_enable',0,'SNR_snrcut',0,'SNR_snrBL',[-Inf 0] ,'SNR_snrPOI',[0 Inf] ,...
    %         'trialfoc_enable',1,'trialfoc_focaltrialout','auto',...
    %         'focalcomp_enable',1,'focalcomp_focalICAout','auto',...
    %         'autocorr_enable',1,'autocorr_autocorrint',20,'autocorr_dropautocorr','auto',...
    %         'opts_noplot',0,'opts_FontSize',14);


        keyboard
        EEG = evalin('base','EEG'); %SASICA stores the results in base workspace via assignin. So we have to use this workaround...
        EEG = eegh(com,EEG);

        %%
        fprintf(['\n I will remove ' num2str(sum(EEG.reject.gcompreject)) ' components\n']);
        ncomps = sum(EEG.reject.gcompreject);
        [EEG,com] = pop_subcomp(EEG,find(EEG.reject.gcompreject),1);
        
        fprintf(resultfileData,'%d %s %s %d \n',isub,ID{isub},EEG_name{isub},ncomps);

        if isempty(com)
            return
        end
        EEG = eegh(com,EEG);
               
        % ----------
        % Save data.
        % ----------
        EEG = pop_editset(EEG,'setname',[cfg.subject_name '_ICArejected.set']);
        EEG = pop_saveset(EEG, [cfg.subject_name '_ICArej.set'],cfg.dir_eeg);
        
        clear ncomps

    end
fclose(resultfileData);
fprintf('Done.\n')   

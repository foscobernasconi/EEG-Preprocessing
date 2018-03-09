function m05_preprp_afterICArmv(whichsubject)

filename=['/media/sv/Elements/22q11/Preprocessing_details/Number_of_rej_trials_subjects_v2.csv'];
if exist(filename,'file')==2,delete(filename),end
resultfileData = fopen(filename,'at');

[who_idx,ID,EEG_ID,EEG_name,patient] = get_subjects(whichsubject);

for isub = 1:length(who_idx)
    
     EEG = [];
    
    % get cfgs
    cfg = get_cfg(who_idx(isub),EEG_name{isub}); 
    
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
     fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',EEG_name{isub},isub,length(who_idx));    
    
    % Load data set.
    EEG = pop_loadset('filename',[cfg.subject_name '_ICArej.set'],...
        'filepath',cfg.dir_eeg,'loadmode','all');
    
    % add if is a patient:
    for itrial = 1:EEG.trials
        EEG.epoch(itrial).patient = patient{isub};
    end
    EEG = eeg_checkset(EEG);
    
    trinum1 = EEG.trials;

    % Interpolate channels:
    if cfg.interpolMissingChan
        originalEEG.chanlocs = load(cfg.chanlocsBE4interpol_noRefChan);
        [EEG,com] = pop_interp(EEG,originalEEG.chanlocs.a,'spherical');
        EEG = eegh(com, EEG);
    end
    
    [EEG,com] = pop_eegthresh(EEG,1,1:EEG.nbchan,-cfg.rej_thresh_post,cfg.rej_thresh_post,EEG.xmin, EEG.xmax,[],1); % this is an extra check
    trinum2 = EEG.trials;
    trinum3 = trinum1 - trinum2;
    
%     fprintf(resultfileData,'%d %s %s %d %d %d \n',isub,EEG_name{isub},EEG_ID{isub},trinum1,trinum3,trinum2);  
    
    if cfg.do_visual_inspection_postICA
        
        %visual inspection:
        global eegrej

        pop_eegplot(EEG,1,1,1);
        
        disp('Interrupting function now. Waiting for you to press')
        disp('"Update marks", and hit "Continue" in Matlab editor menu')        
        keyboard

   
    if cfg.do_reref_after_ica
        [EEG, com] = pop_reref(EEG,[],'keepref','on');
        EEG = eegh(com, EEG);
    end
    
    EEG = pop_editset(EEG, 'setname', [cfg.subject_name '_VisCleanAfterIca.set']);
    EEG = pop_saveset(EEG,[cfg.subject_name '_VisCleanAfterIca.set'] ,cfg.dir_eeg);
    
    clear trinum1 trinum2 trinum3
end
% fclose(resultfileData);
fprintf('Done.\n')

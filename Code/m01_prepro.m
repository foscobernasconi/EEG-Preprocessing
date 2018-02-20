function m01_prepro(whichsubject)

    % which subjects you want to process?
    [who_idx,ID,EEG_ID,EEG_name,patient] = get_subjects(whichsubject);
    addpath('/home/sv/Matlabtoolboxes/Functions/erplab_4.0.3.1');

for isub = 1:length(who_idx)

    % get cfgs
    cfg = get_cfg(who_idx(isub),EEG_name{isub});   
    EEG = [];
    
    % ---------------------------
    % Import parameters & path(s)
    % --------------------------- 
    % Write a status message to the command line.
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',EEG_name{isub},isub,length(who_idx));    

    % Create output directory if necessary.
    if ~isdir(cfg.dir_eeg)
        mkdir(cfg.dir_eeg);
    end

    %-------------
    % Import data
    %-------------                  
    eegData = [cfg.dir_raw EEG_name{isub} '_' num2str(EEG_ID{isub}) '.eeg']; 

    if ~exist(eegData,'file')
        error('%s Does not exist!\n',eegData)
    else
        fprintf('Importing %s\n',eegData)
        EEG = pop_biosig(eegData,'ref',cfg.ImportReference);
    end

    %----------------------------------------
    % Preprocessing (filtering,epoching etc.)
    %----------------------------------------
    EEG = func_prepareEEG(EEG,cfg);

    %------------------------
    % Import behavioral data
    %------------------------
%         EEG = func_importBehavior(EEG,cfg);

    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    [EEG, com] = pop_editset(EEG, 'setname', [cfg.subject_name ' import']);
    EEG = eegh(com, EEG);
    pop_saveset( EEG, [cfg.subject_name  '_import.set'] , cfg.dir_eeg);
end
fprintf('Done.\n')

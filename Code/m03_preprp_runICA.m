function m03_preprp_runICA(whichsubject)

[who_idx,ID,EEG_ID,EEG_name,patient]= get_subjects(whichsubject);
addpath('/home/sv/Matlabtoolboxes/eeglab14_1_1b/bin/binica');

parfor isub = 1:length(who_idx)
    
    EEG = [];
    
    % get cfgs
    cfg = get_cfg(who_idx(isub),EEG_name{isub});   
    
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',EEG_ID{isub}, isub, length(who_idx));    
    
    % Load data set.
    EEG = pop_loadset('filename',[cfg.subject_name '_CleanBeforeICA.set'] , ...
        'filepath',cfg.dir_eeg,'loadmode','all');
    
    
    % Compute avg ref before ICA to improve performance:
    if cfg.do_reref_before_ica
       [EEG,com] = pop_reref(EEG,cfg.postproc_reference,'keepref','off','exclude',[]) 
    end
    
        % If wanted, use extra high-pass filter to enhance ICA results
    % see, e.g., here: https://sccn.ucsd.edu/wiki/Makoto%27s_preprocessing_pipeline#High-pass_filter_the_data_at_1-Hz_.28for_ICA.2C_ASR.2C_and_CleanLine.29.2803.2F29.2F2017_updated.29
    if cfg.do_ICA_hp_filter
        % make a backup of the original data. We'll only save the ICA
        % weights produced with the hp-filtered data.
        nonhpEEG = EEG;
        switch(cfg.hp_ICA_filter_type)
            
            case('butterworth') % This is a function of the separate ERPlab toolbox.
                [EEG, com] = pop_ERPLAB_butter1(...
                    EEG, cfg.hp_ICA_filter_limit, 0, 5); % requires ERPLAB plugin
                EEG = eegh(com, EEG);
                
            case('kaiser')
                m = pop_firwsord('kaiser', EEG.srate,...
                    cfg.hp_ICA_filter_tbandwidth,cfg.hp_ICA_filter_pbripple);
                beta = pop_kaiserbeta(cfg.hp_ICA_filter_pbripple);
                
                [EEG, com] = pop_firws(EEG, 'fcutoff',cfg.hp_ICA_filter_limit, ...
                    'ftype', 'highpass', 'wtype', 'kaiser', ...
                    'warg', beta, 'forder', m);
                EEG = eegh(com, EEG);
        end
    end
        
    % -------------------------------------------------------------- 
    % Check how many components to extract and then run ICA. We need a
    % separate call to pop_runica in every test section because runica does
    % not accept 'pca', 0, even though the help message claims that this
    % defaults to not doing PCA.
    % If exists, use the subject-specific number of ICA components.
    % Otherwise, let EEGLAB determine the number of components
    % (CFG.ica_ncomps==0) or use a fixed number of components
    % (CFG.ica_ncomps>0).
    % --------------------------------------------------------------
    
    %create a subfolder for the temporary binica files, in case binica is used
    if strcmp(cfg.ica_type,'binica')
        mkdir([cfg.dir_eeg 'binica']);
        cd([cfg.dir_eeg 'binica']);
    end
    
    if cfg.ica_rank 
        fprintf('Extracting mandatory number of %d ICA components from %d channels.\n', ...
            cfg.ica_ncomps,EEG.nbchan);
        
        n = rank(EEG.data(:,:),100);       
        [EEG, com] = pop_runica(EEG, 'icatype',cfg.ica_type, ...
            'extended',cfg.ica_extended, ...
            'chanind', 1:EEG.nbchan, ...
            'pca',n);
        
    elseif cfg.ica_ncomps
        fprintf('Extracting mandatory number of %d ICA components from %d channels.\n', ...
            cfg.ica_ncomps, length(cfg.ica_chans));
        [EEG, com] = pop_runica(EEG, 'icatype',cfg.ica_type, ...
            'extended',cfg.ica_extended, ...
            'chanind', 1:EEG.nbchan, ...
            'pca',cfg.ica_ncomps);
        
    elseif cfg.ica_variance
        fprintf('ICA based on variance.\n')  
        EEG.data = reshape(EEG.data,size(EEG.data,1),size(EEG.data,2)*size(EEG.data,3));
        [COEFF,SCORE,latent,tsquare] = princomp(EEG.data');
        num_components_to_keep = find(cumsum(latent) ./ sum(latent)>0.99,1)+1;
        [EEG,com] = pop_runica(EEG, 'icatype',cfg.ica_type,'pca',num_components_to_keep,'chanind',1:length(EEG.chanlocs));
        
    elseif cfg.amica
        dataRank = rank(EEG.data(:,:),100);
        runamica15(EEG.data, 'num_chans', EEG.nbchan,...
        'outdir', cfg.dir_eeg,...
        'pcakeep', dataRank, 'num_models', 1,...
        'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
        EEG.etc.amica   = loadmodout15(cfg.dir_eeg);
        EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); % Weirdly, I saw size(S,1) be larger than rank. This process does not hurt anyway.
        EEG.icaweights  = EEG.etc.amica.W;
        EEG.icasphere   = EEG.etc.amica.S;
        EEG = eeg_checkset(EEG,'ica');        
    else
        fprintf('Let EEGLAB calculate the number of components to extract.\n')        
        [EEG, com] = pop_runica(EEG, 'icatype',cfg.ica_type, ...
            'extended',cfg.ica_extended, ...
            'chanind',1:EEG.nbchan); % compute on all channels
    end
    
    %copy weight & sphere to original data
    if cfg.do_ICA_hp_filter
        nonhpEEG.icaweights  = EEG.icaweights;
        nonhpEEG.icasphere   = EEG.icasphere;
        nonhpEEG.icawinv     = EEG.icawinv;
        nonhpEEG.icachansind = EEG.icachansind;
        nonhpEEG.icaact      = EEG.icaact;
        EEG = nonhpEEG;
    end
    
    EEG = eegh(com, EEG);
    
    %in case binica has been used, cd back to the main folder and delete
    %binica folder
    if strcmp(cfg.ica_type,'binica')
        cd(cfg.dir_main);
        rmdir([cfg.dir_eeg 'binica'],'s');
    end
    
    % ----------
    % Save data.
    % ----------
    EEG = pop_editset(EEG, 'setname', [cfg.subject_name '_ICA.set']);
    EEG = pop_saveset( EEG, [cfg.subject_name '_ICA.set'],cfg.dir_eeg);
end
fprintf('Done.\n')

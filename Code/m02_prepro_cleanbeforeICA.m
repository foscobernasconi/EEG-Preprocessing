clear all

[who_idx,ID,EEG_ID,EEG_name,patient]= get_subjects([]); 

savepath = '/media/sv/Elements/22q11/';
filename=[savepath, 'Preprocessing_summary.csv'];
if exist(filename,'file')==2,delete(filename),end
resultfileData = fopen(filename,'at'); 

for isub = 1:length(who_idx)
    
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    cfg = get_cfg(who_idx(isub),EEG_name{isub});    
    
    % Write a status message to the command line.
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',EEG_name{isub},isub,length(who_idx));     
    
    % --------------
    % Load data set.
    % --------------
    EEG = pop_loadset('filename', [cfg.subject_name '_import.set'] , ...
        'filepath', cfg.dir_eeg, 'loadmode', 'all');
    
    %-----------------------
    % remove useless chanels
    %-----------------------
    if cfg.rmchanels
        [EEG,com] = pop_select(EEG,'nochannel',cfg.rmchanum);
        EEG = eegh(com, EEG);        
    end
    
%     % convert to fieldtrip:
%     % channel selection, cutoff and padding
%     data = eeglab2fieldtrip(EEG,'preprocessing');
%     
%     cfg.artfctdef.zvalue.channel    = 'EEG';
%     cfg.continous                   = 'no';
%     cfg.artfctdef.zvalue.cutoff     = 20;
%     cfg.artfctdef.zvalue.trlpadding = 0;
%     cfg.artfctdef.zvalue.artpadding = 0;
%     cfg.artfctdef.zvalue.fltpadding = 0;
% 
%     % algorithmic parameters
%     cfg.artfctdef.zvalue.cumulative    = 'yes';
%     cfg.artfctdef.zvalue.medianfilter  = 'yes';
%     cfg.artfctdef.zvalue.medianfiltord = 9;
%     cfg.artfctdef.zvalue.absdiff       = 'yes';
% 
%     % make the process interactive
%     cfg.artfctdef.zvalue.interactive = 'yes';
% 
%     [cfg, artifact_jump] = ft_artifact_zvalue(cfg,data);

    %-------------------
    % remove bad chanels
    %-------------------
    %1. check electrodes:
    level = [];
    sensorvar = [];
    badsensorsIndex = [];
    
    for i=1:EEG.trials
        level(:,i) = std(EEG.data(:,:,i),[],2).^2;
    end
    
    % check if eog chans:
    Index_veog = find(contains({EEG.chanlocs.labels},'VEOG'));
    Index_heog = find(contains({EEG.chanlocs.labels},'HEOG'));
    noEOGchans = [Index_veog Index_heog];
    if noEOGchans ~=0
        Chns = EEG.nbchan-length(noEOGchans)
    else
        Chns = EEG.nbchan;
    end
       
    for s=1:Chns % this assumes that eog are the last electrodes
        sensorvar(s,:) = max(level(s,:));
    end
    
    badsensorsIndex = find(sensorvar>(median(sensorvar)+(2*iqr(sensorvar))));
    badelectrodeslabel = {EEG.chanlocs(badsensorsIndex).labels};
    
    %     figure('Color','w');
    %     scatter(sensorvar,[1:EEG.nbchan],'fill');
  
    [EEG,com]  = pop_select(EEG,'nochannel',{EEG.chanlocs(badsensorsIndex).labels});
    EEG = eegh(com, EEG);
    EEG = eeg_checkset(EEG);    
    
    % 2. check trials:
    if cfg.do_apmli_rej_preICA
        [EEG,com] = pop_eegthresh(EEG,1,1:EEG.nbchan,-cfg.rej_thresh_pre,cfg.rej_thresh_pre,...
            EEG.xmin, EEG.xmax, [], 1); % this is an extra check
    end
        
    level2 = [];
    trial = [];
    badtrials = [];   
    
    for i=1:EEG.trials
        level2(:,i) = std(EEG.data(:,:,i),[],2).^2;
    end
    
    for t=1:EEG.trials
        trial(t,:) = max(level2(:,t));
    end

%     figure('Color','w');
%     scatter([1:EEG.trials],trial,'fill');

    badtrials = find(trial> (median(trial)+(2*iqr(trial))));
    [EEG,com] = pop_select( EEG,'notrial',badtrials');
    EEG = eegh(com,EEG);
    EEG = eeg_checkset(EEG);
  
    for ibad = 1:size(badsensorsIndex,1)
        fprintf(resultfileData,'%d %d %s %d\n',isub,size(badsensorsIndex,1),badelectrodeslabel{ibad},size(badtrials,1));
    end
    
    if cfg.do_reref_before_ica
        [EEG, com] = pop_reref(EEG,[],'keepref','on');
    end
        
    if cfg.do_visual_inspection_preICA
        %visual inspection:
        global eegrej

        mypop_eegplot(EEG, 1, 1, 0,'submean','on','winlength',10,'command','global eegrej, eegrej = TMPREJ');

        disp('Interrupting function now. Waiting for you to press')
        disp('"Update marks", and hit "Continue" in Matlab editor menu')
        keyboard

        % eegplot2trial cannot deal with multi-rejection
        rejTime = eegrej(:,1:2);
        [~,firstOccurences,~] = unique(rejTime,'rows');
        eegrej = eegrej(firstOccurences,:);

        [badtrls, badChnXtrl] = eegplot2trial(eegrej,EEG.pnts,length(EEG.epoch));
        trials_to_delete = find(badtrls);
        clear eegrej;
        % ---------------------------------------------------------------------
        %  Execute interpolation and rejection
        % ---------------------------------------------------------------------
        EEG = pop_selectiveinterp(EEG,badChnXtrl);
        [EEG, com] = pop_rejepoch(EEG, trials_to_delete, 1);
        EEG = eegh(com,EEG);
    end

    clear sensorvar level trial badtrials badsensorsIndex
    
    EEG = pop_editset(EEG, 'setname', [cfg.subject_name '_CleanBeforeICA.set']);
    EEG = pop_saveset(EEG, [cfg.subject_name '_CleanBeforeICA.set'], cfg.dir_eeg);    
end
fclose(resultfileData);

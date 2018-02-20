function PSD2R(whichsubject)

freqbands = {[4 7];[8 12];[13 30];[31 45]};
[who_idx,ID,EEG_ID,EEG_name,patient,elim,P1,P2,P3,P4,P5,Panss_pos,Panss_neg,Panns_gen,Panss_comp,...
     Panss_thought] = get_subjects(whichsubject);

filename=['/media/sv/Elements/22q11/22q11_PowerSpectrum.csv'];
if exist(filename,'file')==2,delete(filename),end
resultfileData = fopen(filename,'at');

for isub = 1:length(who_idx)
    
    EEG  = [];   
    data = [];
    % get cfgs
    cfg = get_cfg(who_idx(isub),EEG_name{isub}); 
     
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',ID{isub},isub,length(who_idx));   
    
    % Load data set.
    EEG = pop_loadset('filename',[cfg.subject_name '_VisCleanAfterIca.set'],...
        'filepath',cfg.dir_eeg,'loadmode','all');
        
    % convert to ft:
    dataft = eeglab2fieldtrip(EEG,'preprocessing');
    dataft.label=dataft.label';
    data = dataft;            
    
    % Compute Power:        
    cfg1 = [];
    cfg1.method  = 'mtmfft';
    cfg1.output  = 'pow';
    cfg1.channel = 'all';
    cfg1.taper   = 'hanning';
    cfg1.layout  = 'elec1005.lay';
    cfg1.trials  = 'all';
    cfg1.keeptrials = 'yes';
    cfg1.pad     = 'nextpow2';

    for freq = 1:length(freqbands)      
        % this avg the frequency band of interest:
        cfg1.foi       = ((freqbands{freq}(2)-freqbands{freq}(1))/2)+freqbands{freq}(1);
        cfg1.tapsmofrq = ((freqbands{freq}(2)-freqbands{freq}(1))/2);
        Power = ft_freqanalysis(cfg1,data);
       
        switch patient{isub}
            case 0
                condi = 'HC';
            case 1
                condi = '22q11';
        end
        
        switch freq
            case 1
                fr = 'theta';
            case 2
                fr = 'alpha';
            case 3
                fr = 'beta';
            case 4
                fr = 'gamma';
        end
        
        for itrial = 1:size(Power.powspctrm,1)
            for ichan = 1:size(Power.powspctrm,2)
                fprintf(resultfileData,'%f %s %d %s %d %d %d %d %d %d %d %d %d %d %d %d %d %s %s \n',Power.powspctrm(itrial,ichan),...
                    condi,isub,fr,patient{isub},elim{isub},P1{isub},P2{isub},P3{isub},P4{isub},P5{isub},Panss_pos{isub},Panss_neg{isub},...
                    Panns_gen{isub},Panss_comp{isub},Panss_thought{isub},...
                    itrial,EEG.chanlocs(ichan).labels,EEG_name{isub});
            end
        end
        
        clear condi Power
    end
    clear data
end
fclose(resultfileData);
end


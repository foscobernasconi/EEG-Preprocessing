% function [pvalues1,mask1,pvalues,mask] = PSD(whichsubject)

whichsubject = [];
[who_idx,ID,EEG_ID,EEG_name,patient,elim,P1,P2,P3,P4,P5,Panss_pos,Panss_neg] = get_subjects(whichsubject);

freqbands = {[4 7];[8 12];[13 30];[31 45]};
fblabels  = {'Theta [4 7]';'Alpha [8-12Hz]';'Beta [13 30Hz]';'Gamma [31-45Hz]'};
cont = 0;
pat  = 0;
subjincl = 0;
pow  = 'powspctrm';

for isub = 1:length(who_idx)
    
    EEG  = [];   
    data = [];
    
    % get cfgs
    cfg = get_cfg(who_idx(isub),EEG_name{isub}); 
    
    % -------------
    % Prepare data.
    % -------------
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n',EEG_name{isub},isub,length(who_idx));    
    
    % Load data set.
    EEG = pop_loadset('filename',[cfg.subject_name '_VisCleanAfterIca.set'],...
        'filepath',cfg.dir_eeg,'loadmode','all');
    
%     if ~elim{isub}
        subjincl = subjincl+1;
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
        cfg1.layout  = 'layoutEGI22q11.mat';
        cfg1.trials  = 'all';
        cfg1.keeptrials = 'no';
        cfg1.pad     = 'nextpow2';

        switch patient{isub}
            case 0
                cont = cont +1;
            case 1
                pat = pat+1;
        end

        for freq = 1:length(freqbands)      
            % this avg the frequency band of interest:
            cfg1.foi       = ((freqbands{freq}(2)-freqbands{freq}(1))/2)+freqbands{freq}(1);
            cfg1.tapsmofrq = ((freqbands{freq}(2)-freqbands{freq}(1))/2);

            switch patient{isub}
                case 0
                    PowerHC{cont,freq} = ft_freqanalysis(cfg1,data);
                    PowerHC{cont,freq}.powspctrm = log(PowerHC{cont,freq}.powspctrm);
                    PowerHC{cont,freq}.dimord = 'chan_freq';
                case 1
                    PowerPD{pat,freq} = ft_freqanalysis(cfg1,data);
                    PowerPD{pat,freq}.powspctrm = log(PowerPD{pat,freq}.powspctrm);
                    PowerPD{pat,freq}.dimord = 'chan_freq';
            end 
        end
%     end
end

f1=figure;
figpos1 = 1;
for ifreq = 1:length(freqbands)
    
    % Avg subjects:
    cfg = [];
    cfg.keepindividual = 'yes';
    cfg.foilim      = 'all';
    cfg.parameter   = pow;
    cfg.channel     = 'all';
    cfg.avgoverchan = 'no';
    cfg.avgoverfreq = 'no';  

    grandavg{:,1} = ft_freqgrandaverage(cfg,PowerHC{:,ifreq}); 
    grandavg{:,2} = ft_freqgrandaverage(cfg,PowerPD{:,ifreq});
    
    % compute t-test (HC vs. 22q11)
    cfg             = [];
    cfg.channel     = 'all';
    cfg.method      = 'montecarlo';
    cfg.statistic   = 'indepsamplesT';
    cfg.alpha       =  0.05;
    cfg.numrandomization = 5000;
    cfg.layout      = 'layoutEGI22q11.mat';
    cfg.frequency   = 'all';
    cfg.parameter   =  pow;
    cfg.avgoverchan = 'no';
    cfg.avgovertime = 'no';
    cfg.avgoverfreq = 'no';
    cfg.correcttail = 'alpha';

    % parameters for clustering:
%     cfg.correctm         = 'cluster'; % cluster fdr holm max
%     cfg.clusteralpha     = 0.05;
%     cfg.clusterstatistic = 'maxsum'; % 'maxsum', 'maxsize', 'wcm' 
%     cfg.minnbchan        = 1;
%     cfg.tail             = 0;
%     cfg.clustertail      = 0;
%     cfg_neighb           = [];
%     cfg.layout           = 'layoutEGI22q11.mat';
%     cfg.feedback         = 'yes';
%     cfg_neighb.method    = 'distance';
% %     cfg_neighb.template  = 'elec1005_neighb.mat';
%     neighbours           = ft_prepare_neighbours(cfg_neighb,data);
%     cfg.neighbours       = neighbours;

    % define a matrix according to trials numbers:
    switch pow
        case 'powspctrm'
            Nsub = 1:length(who_idx);
            cfg.design(1,1:subjincl) = [ones(1,size(grandavg{1,1}.powspctrm,1)) 2*ones(1,size(grandavg{1,2}.powspctrm,1))];
            cfg.ivar = 1;
        case 'powspctrmZ'
            Nsub = 1:length(who_idx);
            cfg.design(1,1:subjincl) = [ones(1,size(grandavg{1,1}.powspctrmZ,1)) 2*ones(1,size(grandavg{1,2}.powspctrmZ,1))];
            cfg.ivar = 1;
    end

    % Do stats:
    [stat1] = ft_freqstatistics(cfg,grandavg{:,1},grandavg{:,2});
    
    tvalues1{ifreq,:} = stat1.stat;
    pvalues1{ifreq,:} = stat1.prob;
    mask1{ifreq,:}    = stat1.mask;
    
    cfg = [];
    cfg.parameter = pow;
    cfg.layout    = 'layoutEGI22q11.mat';
    cfg.comment   = 'no';
    cfg.colorbar  = 'no';
    
    set(f1,'Color','w');
        subplot(5,3,figpos1)
            figpos1 = figpos1 +1;
            switch pow
                case 'powspctrm'
%                     cfg.zlim = [min(mean(grandavg{:,1}.powspctrm)) max(mean(grandavg{:,1}.powspctrm))];
                    cfg.zlim = 'maxmin';
                case 'powspctrmZ'
                    cfg.zlim = [min(mean(grandavg{:,1}.powspctrmZ)) max(mean(grandavg{:,1}.powspctrmZ))];
            end
            title(['HC ' fblabels(ifreq) ' Hz']); hold on; 
            ft_topoplotER(cfg,grandavg{:,1});
        subplot(5,3,figpos1)
            figpos1 = figpos1 +1;
            title(['22q11 ' fblabels(ifreq) ' Hz']); 
            ft_topoplotER(cfg,grandavg{:,2});
            
        if isempty(stat1.mask) == 0
            cfg.highlightchannel = [find(stat1.mask)];
        elseif isempty(stat1.mask) == 1
            cfg.highlightchannel = [];
        end
        
        cfg.parameter = 'stat';
        cfg.marker    = 'on';
        cfg.highlight = 'on';
        cfg.highlightsymbol = '*';
        cfg.highlightsize   = 10;
        cfg.zlim      = 'maxmin';
        cfg.comment   = 'no';
        cfg.colorbar  = 'no';
        subplot(5,3,figpos1) 
        title(['t -values ' fblabels(ifreq) ' Hz']);
        figpos1 = figpos1 +1;
        ft_topoplotER(cfg,stat1);
        
        clear grandavg stat
end

% f=figure;
% figpos = 1;
% for ifreq = 1:length(freqbands)
%     
%     % Avg subjects:
%     cfg = [];
%     cfg.keepindividual = 'yes';
%     cfg.foilim      = 'all';
%     cfg.parameter   =  pow;
%     cfg.channel     = 'all';
%     cfg.avgoverchan = 'no';
%     cfg.avgoverfreq = 'no';
% 
%     grandavg{:,1} = ft_freqgrandaverage(cfg,PowerHC{:,ifreq}); 
%     grandavg{:,2} = ft_freqgrandaverage(cfg,PowerPD_MH{:,ifreq});
%     grandavg{:,3} = ft_freqgrandaverage(cfg,PowerPDnoMH{:,ifreq});
%       
%     % compute anova
%     cfg             = [];
%     cfg.channel     = 'all';
%     cfg.method      = 'montecarlo';
%     cfg.statistic   = 'indepsamplesF';
%     cfg.alpha       =  0.05;
%     cfg.numrandomization = 2000;
%     cfg.layout      = 'elec1005.lay';
%     cfg.frequency   = 'all';
%     cfg.parameter   =  pow;
%     cfg.avgoverchan = 'no';
%     cfg.avgovertime = 'no';
%     cfg.avgoverfreq = 'no';
%     cfg.correcttail = 'alpha';
% 
%     % parameters for clustering:
%     cfg.correctm         = 'fdr'; % cluster fdr holm max
% %     cfg.clusteralpha     = 0.05;
% %     cfg.clusterstatistic = 'maxsum'; % 'maxsum', 'maxsize', 'wcm' 
% %     cfg.minnbchan        = 1;
% %     cfg.tail             = 1;
% %     cfg.clustertail      = 1;
% %     cfg_neighb           = [];
% %     cfg.feedback         = 'yes';
% %     cfg_neighb.method    = 'template';
% %     cfg_neighb.template  = 'elec1005_neighb.mat';
% %     neighbours           = ft_prepare_neighbours(cfg_neighb,data);
% %     cfg.neighbours       = neighbours;
% 
%     % define a matrix according to trials numbers:
%     switch pow
%         case 'powspctrm'
%             Nsub = 1:length(who_idx);
%             cfg.design(1,1:length(who_idx)) = [ones(1,size(grandavg{1,1}.powspctrm,1)) 2*ones(1,size(grandavg{1,2}.powspctrm,1)) 3*ones(1,size(grandavg{1,3}.powspctrm,1))];
%             cfg.ivar = 1;
%         case 'powspctrmZ'
%             Nsub = 1:length(who_idx);
%             cfg.design(1,1:length(who_idx)) = [ones(1,size(grandavg{1,1}.powspctrmZ,1)) 2*ones(1,size(grandavg{1,2}.powspctrmZ,1)) 3*ones(1,size(grandavg{1,3}.powspctrmZ,1))];
%             cfg.ivar = 1;
%     end
% 
%     % Do stats:
%     [stat] = ft_freqstatistics(cfg,grandavg{:,1},grandavg{:,2},grandavg{:,3});
%     
%     tvalues{ifreq,:} = stat.stat;
%     pvalues{ifreq,:} = stat.prob;
%     mask{ifreq,:}    = stat.mask;
%     
%     cfg = [];
%     cfg.parameter = pow;
%     cfg.layout    = 'elec1005.lay';
%     cfg.comment   = 'no';
%     cfg.colorbar  = 'no';
%     
%     set(f,'Color','w');
%         subplot(5,4,figpos)
%             figpos = figpos +1;
%             switch pow
%                 case 'powspctrm'
% %                     cfg.zlim = [min(mean(grandavg{:,1}.powspctrm)) max(mean(grandavg{:,1}.powspctrm))];
%                     cfg.zlim = 'maxmin';
%                 case 'powspctrmZ'
%                     cfg.zlim = [min(mean(grandavg{:,1}.powspctrmZ)) max(mean(grandavg{:,1}.powspctrmZ))];
%             end
%             title(['HC ' fblabels(ifreq) ' Hz']); hold on; 
%             ft_topoplotER(cfg,grandavg{:,1});
%         subplot(5,4,figpos)
%             figpos = figpos +1;
%             title(['PDMH + ' fblabels(ifreq) ' Hz']); 
%             ft_topoplotER(cfg,grandavg{:,2});
%         subplot(5,4,figpos)
%             figpos = figpos +1;
%             title(['PDMH - ' fblabels(ifreq) ' Hz']); 
%             ft_topoplotER(cfg,grandavg{:,3});
%             
%         if isempty(stat.mask) == 0
%             cfg.highlightchannel = [find(stat.mask)];
%         elseif isempty(stat.mask) == 1
%             cfg.highlightchannel = [];
%         end
%                
%         cfg.parameter = 'stat';
%         cfg.marker    = 'on';
%         cfg.highlight = 'on';
%         cfg.highlightsymbol = '*';
%         cfg.highlightsize   = 10;
%         cfg.zlim     = 'maxmin';
%         cfg.comment  = 'no';
%         cfg.colorbar = 'no';
%         subplot(5,4,figpos) 
%         title(['F -values ' fblabels(ifreq) ' Hz']);
%         figpos = figpos +1;
%         ft_topoplotER(cfg,stat);
%         
%         clear grandavg stat
% end
% end

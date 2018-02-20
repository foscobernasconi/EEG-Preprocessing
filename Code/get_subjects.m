 function [who_idx,ID,EEG_ID,EEG_name,patient,elim,P1,P2,P3,P4,P5,Panss_pos,Panss_neg,Panss_gen,Panss_comp,...
     Panss_thought] = get_subjects(whichsubject)
% helper function to decode which subjects are to be processed.

% EP.who = 1; % Single numerical index.
% EP.who = [1 3]; % Vector of numerical indices.
% EP.who = 'AI01'; % Single string.
% EP.who = {'Pseudonym', {'AI01', 'AI02'}}; % One pair of column name and requested values.
% EP.who = {'Pseudonym', {'AI01', 'AI03'}; 'Include', 1; 'has_import', 0}; % Multiple columns and values. Only subjects fullfilling all criteria are included.

if isempty(whichsubject)
    [~,num,Raw] = xlsread('/media/sv/Elements/22q11/Info/SubjectsInfo.xlsx','Sheet2'); 
    Raw(1,:)=[]; % remove header
    who_idx = 1:size(Raw(:,1),1);
    ID      = Raw(:,2);
    EEG_ID  = Raw(:,6);
    EEG_name= Raw(:,5);
    patient = Raw(:,3);
    elim    = Raw(:,10);
    P1      = Raw(:,13);
    P2      = Raw(:,14);
    P3      = Raw(:,15);
    P4      = Raw(:,16);
    P5      = Raw(:,17);
    Panss_pos = Raw(:,18);
    Panss_neg = Raw(:,19);
    Panss_gen = Raw(:,20);
    Panss_comp = Raw(:,23);
    Panss_thought = Raw(:,26);
    
elseif isnumeric(whichsubject) % If who is just a numeric index.
    [~,num,Raw] = xlsread('/media/sv/Elements/22q11/Info/SubjectsInfo.xlsx','Sheet2');
    Raw(1,:)=[]; % remove header
    who_idx = Raw(whichsubject,1);
    ID      = Raw(whichsubject,2);
    EEG_ID  = Raw(whichsubject,6);
    EEG_name= Raw(whichsubject,5);
    patient = Raw(whichsubject,3);
    elim   = Raw(whichsubject,10);
    P1      = Raw(whichsubject,13);
    P2      = Raw(whichsubject,14);
    P3      = Raw(whichsubject,15);
    P4      = Raw(whichsubject,16);
    P5      = Raw(whichsubject,17);
    Panss_pos = Raw(whichsubject,18);
    Panss_neg = Raw(whichsubject,19);
    Panss_gen = Raw(whichsubject,20);
    Panss_comp = Raw(whichsubject,23);
    Panss_thought = Raw(whichsubject,26);
       
% elseif isstr(whichsubject.who) % If who is a single string.
%     names = whichsubject.S.Name;
%     who_idx = find(strcmp(whichsubject.who, names));
    
    
% elseif iscell(whichsubject.who) % If who is a set of field names and values
%     
%     for ivar = 1:size(whichsubject.who,1)
%         
%         req_varname = whichsubject.who{ivar,1}; %requested field name, e.g. Pseudonym or Include
%         req_values =  whichsubject.who{ivar,2}; % requested value, e.g. 'AI01' or 1.
%         
%         subject_values = whichsubject.S.(req_varname);
%         
%         if isnumeric(subject_values)
%             subject_values(isnan(subject_values)) = 0;
%         end
%         
%         var_idx(ivar,:) = ismember(subject_values, req_values);
%     end
%     
%     who_idx = find(all(var_idx, 1)); % select subjects who fullfill all criteria.
    
end
# EEG-Preprocessing

Matlab functions for preprocessing of electroencephalography (EEG) data.

The functions can be used to import the EEG data into Matlab and run through the most common preprocessing steps (filtering, epoching, etc.). 
Note that the code provided here consists basically of wrapper functions that rely on functions from the EEGLAB toolbox & fieldtrip toolbox for Matlab.

### What you need:

* EEGLAB/Fieldtrip

* plugins: SASICA (optional: Cleanline, erplab and erptools)

* **Important**: if you want to use 'binica' on linux 64bits make sure to: sudo apt-get install lib32z1 (as binica is coded on 32bits).  

* configuration (cfg) file: this file specifies all variable aspects of your analysis (paths to data files, sampling rate, filter setting, etc.).

* SubjectsTable.xlsx (a sample is included in this repository): An Excel spreadsheet containing a list of your subjects and information about these datasets. 

Important columns in this table are:

* "Name", which contains a name, code or pseudonym for each dataset.

Eventually, you may want to have also a column for:

* "replace_chans": sometimes electrodes are broken and are replaced during recording with an external electrode. Suppose electrodes 31 and 45 are broken and are to be replaced with external electrodes 71 and 72, respectively. The information in this column should read: 31,71;45,72

* "interp_chans": sometimes you discover that an electrode was dysfunction, but you did not record an external electrode to replace it with. You can still interpolate this electrode entirely.

* "ica_ncomps": by default, ICA calculates automatically the number of independent components to estimate, or you can set a fixed number in the cfg file. But sometimes a dataset will not compute with either procedure. In such cases, it sometimes helps to have ICA estimate a much smaller number of ICs. This number can be set here.



### Suggestions & Acknowledgments are always welcome

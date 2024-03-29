function [res, dprime, pvals,cellids,computed, not_computed] = load_STA_population(which_switch, this_force, slim_data, bad_strength)
%which_switch = 'generative'; % 'model' or 'generative' or 'accumulation'

cd ~/Dropbox/spikes/bin
addpath ~/ratter/Manuscripts/TimHanks/PBupsPhys/Code/
addpath ~/ratter/Manuscripts/TimHanks/PBupsPhys/Code/Carlosbin
addpath ~/ratter/svn_papers/TimHanks/PBupsPhys/Code/
addpath ~/ratter/svn_papers/TimHanks/PBupsPhys/Code/Carlosbin
addpath ~/ratter/ExperPort/bin
addpath ~/ratter/Analysis/Pbups
addpath ~/ratter/ExperPort/MySQLUtility
addpath ~/ratter/ExperPort/Analysis
addpath ~/ratter/ExperPort/Analysis/SameDifferent/
addpath ~/ratter/ExperPort/HandleParam
addpath ~/ratter/Analysis/helpers
addpath ~/Dropbox/spikes/cell_packager_data/
addpath ~/Dropbox/spikes/bin/tuning_curves

if nargin < 2
    this_force = 0;
end
if nargin < 3
    slim_data = 1;
end

if ~this_force && exist(['../cell_packager_data/population_STA_' which_switch '_' num2str(bad_strength) '.mat']) == 2
    load(['../cell_packager_data/population_STA_' which_switch '_' num2str(bad_strength) '.mat']);
else
    % get the list of cells
    cell_list = dyn_cells_db;
    % only look at cells with reasonable firing rates during the trial
    select_str = 'normmean > .5';
    save_switch = [which_switch '_' num2str(bad_strength)];

    %%%%% logic here for rat specific model
    if which_switch(end-4) == '_' % Rat specific
        this_rat = which_switch(end-3:end);
        which_switch = which_switch(1:end-5);
        select_str = ['normmean > .5 & strcmp(ratname, ''' this_rat ''')'];
    end 

    cellids = cell2mat(extracting(cell_list, 'cellid',select_str));
%    sessids = cell2mat(extracting(cell_list, 'sessid',select_str));
    % iterate over cells and compute STAs
    computed        = zeros(size(cellids));
    not_computed    = ones(size(cellids));
    res = cell(1,length(cellids));
    nn = 1;
     for cc = nn:length(cellids)
         try
             res{nn} =  compute_switch_triggered_average(cellids(cc),'post',2,'which_switch',which_switch, 'n_shuffles', 1000,'save_file',1,'mask_other_switch',1, 'bad_strength', bad_strength);
             res{nn}.STR_right_shuff = [];
             res{nn}.STR_left_shuff  = [];
             res{nn}.STR_right_real  = [];
             res{nn}.STR_left_real   = [];
             res{nn}.dprime_shuff    = [];
            if slim_data
             res{nn}.params          = [];
            end

             disp(cc)
             nn = nn+1;
            computed(cc) = 1;
            not_computed(cc) = 0;
         catch ME
            disp(ME.message)
         end 
     end
     
     %% turn this into a matrix that we can plot
     dprime = [];
     pvals = [];
     
     for ccall = 1:length(cellids)
         if ~isempty(res{ccall})
         pval_plot_lags = res{ccall}.lags > -.5 & res{ccall}.lags < 1;
         dprime = [dprime; res{ccall}.dprime_real(pval_plot_lags)'];
         pvals =  [pvals;  res{ccall}.pval(pval_plot_lags)'];
         cc = ccall;
         end
     end
    save(['../cell_packager_data/population_STA_' save_switch '.mat'],'cellids','dprime','pvals','cc','res','not_computed','computed')
end



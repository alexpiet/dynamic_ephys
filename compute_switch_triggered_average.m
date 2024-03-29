function res = compute_switch_triggered_average(data,varargin)
% function res =  compute_switch_triggered_average(data, varargin)
%
% Computes a switch triggered average for cells recording in the dynamic
% clicks task. 
%
% input:
% -----
% data        - a struct prodcuded by calling package_dyn_phys for a given
%               cellid. if input is numeric, code assumes it is a cellid
%               and passes it to package_dyn_phys
%
% output:
% -----
% res a structure containing switch triggered responses and d' for the real
% and, if desired, shuffled data
%
% example usage:
% res = compute_switch_triggered_average(17784, 'n_shuffles', 1000,
%                       'array_data', adata, 'vec_data', vdata)
% computes sta for cell 17784 using the model switches contained in
% adata.model_switch_to_0, also recomputes sta 1000 times using 
% shuffles of the switch times across trials 
%
%
% res = compute_switch_triggered_average(data, 'clear_bad_strengths', 0)
% Computes sta using the data struct. It computes the model switch times,
% but does not remove low salience switches, removing only the first model
% switch (which is really a switch from agnosticism). No shuffles are
% performed.

% optional parameters specified by user
parser = inputParser;
addParamValue(parser, 'n_shuffles', 0) % whether to run a shuffle test
addParamValue(parser, 'which_switch', 'model') % other option is 'generative'
addParamValue(parser, 'align_ind', 1) % 1 means align to stim on and masked after stim off
addParamValue(parser, 'norm_type', 'none') % 'div', 'log_div', 'z' are other options
addParamValue(parser, 'post', 2) % time over which to make this plot
addParamValue(parser, 'model_smooth_wdw', 100);
addParamValue(parser, 'array_data', []);
addParamValue(parser, 'vec_data', []);
addParamValue(parser, 'include_str', 'data.trials.hit == 1');
addParamValue(parser, 'clear_bad_strengths', 1);
addParamValue(parser, 'bad_strength', 0);
addParamValue(parser, 'save_dir', '~/Dropbox/spikes/cell_packager_data');
addParamValue(parser, 'model_dir', '~/Dropbox/spikes/model/');
addParamValue(parser, 'save_file', 1);
addParamValue(parser, 'force', 0); % determines whether to recompute
addParamValue(parser, 'mask_other_switch', 0); % determines whether to recompute
addParamValue(parser, 'fit_line', 1); % determines method for quantifying state strength





parse(parser,varargin{:});
params = parser.Results;

% decide how to interpret first input
if isnumeric(data)
    cellid = data;
else
    cellid = data.cellid;
end

if (~isempty(params.save_dir) && ~exist(params.save_dir, 'dir')) || ...
    (~isempty(params.model_dir) && ~exist(params.model_dir, 'dir'))
    error('your default save or model directory don''t exist')
end

% determine the file path for this STA and load the file if desired
if ~isempty(params.save_dir)
    if params.clear_bad_strengths
    save_path = fullfile(params.save_dir, [params.which_switch '_STA_' num2str(cellid) '_' num2str(params.bad_strength) '.mat']);
    else
    save_path = fullfile(params.save_dir, [params.which_switch '_STA_' num2str(cellid) '.mat']);
    end
    if ~params.force & exist(save_path,'file')
        load(save_path,'res');
        return
    elseif ~exist(params.save_dir,'dir') | isempty(params.save_dir)
        warning('save dir incorrectly specified')
    end
end

disp('computing switch triggered average')
% if data is a cellid, load it
if isnumeric(data)
    data = dyn_cell_packager(data);
end
% load and clean up array_data and vec_data for this session
if isempty(params.array_data) || isempty(params.vec_data)
    [params.array_data, params.vec_data, this_sessid, this_rat] = package_dyn_phys(data.cellid);

    % set up parameters for computing model strengths
    p.remove_initial_choice = 1;
    p.eval_dt = 1e-3;
    p.strength_window =.1;
    p.clear_bad_strengths = params.clear_bad_strengths;
    p.bad_strength = params.bad_strength;
    p.fit_line = params.fit_line;
else 
    p = [];
    params.model_smooth_wdw = [];
end
% throw out bad trials from array_data
params.array_data = cleanup_array_data(params.array_data, params.vec_data);
% add generative state switches to array_data
params.array_data = compute_state_switches(params.array_data);
% decide either to use the model or generative switches
if strcmp(params.which_switch, 'model')
    % if array_data wasn't passed in with model switches, compute them
    % using the saved model mean and the relevant model parameters
    if ~isfield(params.array_data, 'model_switch_to_0') ||  ~isfield(params.array_data, 'model_switch_to_1')
        % load the model mean trajectory
        try
        m = load(fullfile(params.model_dir, ['model_mean_' num2str(data.sessid) '.mat']));
        model_mean = m.model_mean(params.vec_data.good);
        catch
            compute_model_mean(this_rat,this_sessid, params.model_dir)
            m = load(fullfile(params.model_dir, ['model_mean_' num2str(data.sessid) '.mat']));
            model_mean = m.model_mean(params.vec_data.good);
        end
        % smooth the mean model trajectory
        if ~isempty(params.model_smooth_wdw)
            for j = 1:length(model_mean)
                model_mean(j).mean = movmean(model_mean(j).mean, params.model_smooth_wdw);
            end
        end
        % compute the model switch times
        params.array_data = compute_model_state(params.array_data, model_mean);
        params.array_data = quantify_model_state_strength(params.array_data,p);
        params.array_data = smooth_model_state(params.array_data,p);
    end
    switch_to_0 = {params.array_data.model_switch_to_0};
    switch_to_1 = {params.array_data.model_switch_to_1};
    %stim_start = vec_data.stim_start(includes);
elseif strcmp(params.which_switch, 'generative')
    switch_to_0 = {params.array_data.switch_to_0};
    switch_to_1 = {params.array_data.switch_to_1};
    %stim_start = vec_data.stim_start(includes);
elseif strcmp(params.which_switch, 'accumulation')
    params.array_data = compute_accumulation_state_switches(params.array_data);
    switch_to_0 = {params.array_data.accumulation_switch_to_0};
    switch_to_1 = {params.array_data.accumulation_switch_to_1};
else
    error('which_switch improperly specified')
end
% decide which trials to analyze and which to discard
has_switch  = (cellfun(@length, switch_to_0) + cellfun(@length, switch_to_1)) > 0;
includes    = eval(params.include_str) & has_switch';
n_trials    = sum(includes);
switch_to_0 = switch_to_0(includes);
switch_to_1 = switch_to_1(includes);
n_switch_to_0 = cellfun(@length, switch_to_0);
n_switch_to_1 = cellfun(@length, switch_to_1);

% normalize firing rates
switch params.norm_type
    case 'none'
        norm_ys = data.frate{params.align_ind};
    case 'div'
        norm_ys = data.frate{params.align_ind} ./ data.norm_mean;
    case 'log_div'
        norm_ys = log(data.frate{params.align_ind} ./ data.norm_mean);
    case 'z'
        norm_ys = (data.frate{params.align_ind} - data.norm_mean) ./ data.norm_std;
    otherwise
        error('norm_type not recognized')
end

% time axis
t               = data.frate_t{params.align_ind};
[~, pre_bin]    = min(abs(t));
[~, post_bin]   = min(abs(t-params.post));
t               = t(pre_bin:post_bin);
% lags are time differences between switches and spikes
lags    = [-fliplr(t(pre_bin+1:post_bin)) t(pre_bin:post_bin)];
n_lags  = length(lags);

% initialize switch triggered response for matrix for each side
STR_right = nan(sum(n_switch_to_1), n_lags, params.n_shuffles+1);
STR_left = nan(sum(n_switch_to_0), n_lags, params.n_shuffles+1);

% get data from included trials and relevant time bins
norm_ys = norm_ys(includes,pre_bin:post_bin);

% calculate mean firing rate
fr_mean = nanmean(norm_ys);

% compute residual firing rates by subtracting the mean from all trials
fr_residual = norm_ys - repmat(fr_mean,n_trials,1);

% if desired, shuffle residual firing rates across included trials
real_ind = 1:size(norm_ys,1);  
test_ind = repmat(real_ind,params.n_shuffles+1,1);
for ss = 2:params.n_shuffles
    test_ind(ss,:) = real_ind(randperm(length(real_ind)));
end

% loop through trials to build the sta matrix
n_computed_switches_to_0 = 0;
n_computed_switches_to_1 = 0;
for tt=1:n_trials
    % make response vector
    s2_full = fr_residual(test_ind(:,tt),:)';
    
    this_switch_1 = switch_to_1{tt};
    this_switch_0 = switch_to_0{tt};
    this_switch = [this_switch_1 this_switch_0];
    this_state  = [ones(size(this_switch_1)) zeros(size(this_switch_0))];
    [this_switch, sort_dex] = sort(this_switch);
    this_state = this_state(sort_dex);
    
    if params.mask_other_switch
        for m = 1:length(this_switch)
            [t_start, t_end, ind] = get_lag_params(t,this_switch(m),n_lags);
            s2 = s2_full;
            if m > 1
                s2(t<this_switch(m-1),:) = nan;
            end
            if m < length(this_switch)
                s2(t>this_switch(m+1),:) = nan;
            end
            
            if this_state(m) == 0
                n_computed_switches_to_0 = n_computed_switches_to_0+1;
                if sum(ind)>0
                    STR_left(n_computed_switches_to_0,max(1,t_start):t_end,:) = s2(ind,:);
                end
            elseif this_state(m) == 1
                n_computed_switches_to_1 = n_computed_switches_to_1+1;
                if sum(ind)>0
                    STR_right(n_computed_switches_to_1,max(1,t_start):t_end,:) = s2(ind,:);
                end
            end
        end
    else
        
        %loop over switches to state 0 and align this spike train to the right time lags
        if ~isempty(switch_to_0{tt})
            this_switch_0 = switch_to_0{tt};
            % loop through each switch and get click-triggered response
            for m=1:length(this_switch_0)
                
                % find time bin of response vector that most closely matches switch
                [t_start, t_end, ind] = get_lag_params(t,this_switch_0(m),n_lags);
                % add this STR to the matrix
                if sum(ind)>0
                    STR_left(n_computed_switches_to_0,max(1,t_start):t_end,:) = s2(ind,:);
                end
            end
        end
        % repeat for switches to state 1
        if ~isempty(switch_to_1{tt})
            this_switch_1 = switch_to_1{tt};
            for m=1:length(this_switch_1)
                n_computed_switches_to_1 = n_computed_switches_to_1+1;
                [t_start, t_end, ind] = get_lag_params(t,this_switch_1(m),n_lags);
                % add this STR to the matrix
                if sum(ind)>0
                    STR_right(n_computed_switches_to_1,max(1,t_start):t_end,:) = s2(ind,:);
                end
                
                
            end
        end
    end
end

% populate output structure
dprime              = (nanmean(STR_right)-nanmean(STR_left)) ./ ...
    (.5 .* (nanvar(STR_right)+nanvar(STR_left)));

res.STR_right_real  = STR_right(:,:,1);
res.STR_left_real   = STR_left(:,:,1);
res.STR_right_shuff = STR_right(:,:,2:end);
res.STR_left_shuff  = STR_left(:,:,2:end);
res.dprime_real     = squeeze(dprime(1,:,1))';
res.dprime_shuff    = squeeze(dprime(1,:,2:end));
res.good_lags       = ~isnan(sum(res.dprime_shuff,2));
res.pval            = nan(size(res.dprime_real));
res.pval(res.good_lags) = nanmean(res.dprime_real(res.good_lags)'  > res.dprime_shuff(res.good_lags,:)');
res.lags            = lags;
res.params          = params;
res.cellid          = data.cellid;

% save results
if ~isempty(params.save_dir) && params.save_file
    save(save_path,'res');
end



function [t_start t_end ind] = get_lag_params(t,this_switch_t,n_lags)
dt = t(2)-t(1);
n_timebins = length(t);
this_t = t(1):dt:(this_switch_t+dt);

%find time bin of response vector that most closely matches switch
[~, switch_time_ind] = min(abs(this_t - this_switch_t + dt*0.5));
t_start = n_timebins-switch_time_ind+1;
t_end   = n_lags - switch_time_ind + 1;
ind = (t_start:t_end)>0;







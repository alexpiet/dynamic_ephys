function [ref,ts] = compute_ref_by_trial(array_data, vec_data,field);
% could be outdated

ref =[];
ts = [];
for i=1:length(array_data)
    if ~isfield(array_data, field)
        error('reference field doesnt exist')
    end
    this_ref = array_data(i).(field) + vec_data.state_0_exits(i);
    if iscolumn(this_ref);
        this_ref = this_ref';
    end
    ref = [ref this_ref];
    this_spikes = array_data(i).spikes' + vec_data.state_0_exits(i);
    ts = [ts this_spikes];
end

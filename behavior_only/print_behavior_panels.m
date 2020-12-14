p = set_dyn_path;
%%
fw = 2.5;
msz = 12;
fsz = 10.5;
set(0, 'defaultaxesfontsize',fsz);
set(0,'defaultaxeslinewidth',1)
%%
over = 0;
% load data
f = [];
d = [];

example_rat = 'H037';
all_rats = p.ratlist;
which_rats = 'all';
switch which_rats
    case 'example'
        rats = {example_rat};
    case 'all'
        rats = p.ratlist;
end


%%
for rr = 1:length(rats)
    ratname = rats{rr};
    fn = fullfile(p.behav_data_dir, [ratname '.mat']);
    fitfn = fullfile(p.model_fits_dir, ['fit_analytical_' ratname '.mat']);
    f{rr} = fit_rat_analytical(ratname,'results_dir', p.model_fits_dir,...
        'data_dir',p.behav_data_dir,'overwrite',over); %#ok<*SAGROW>
    
    d{rr} = load(fn,'data');
    data = d{rr}.data;
    
    assert(length(unique([data.Hazard]'))<5)
    
    endState = [data.genEndState]';
    switch_count = cellfun(@length, {data.genSwitchTimes})';
    no_switch = (switch_count==0);
    has_switch = switch_count >= 1;
    
    T = [data.T]';
    time_from_last = T;
    
    time_from_last(has_switch) = time_from_last(has_switch) -...
        cellfun(@(x) x(end), {data(has_switch).genSwitchTimes})';
    
    tbins = [0:.15: 1  2]
    
    cm = flipud(bone(length(tbins)));
    
    r = [data.pokedR]';
    h = [data.hit]';
    %% plot log odds psychometric used in panel C
    
    gamma   = [data.gamma]';
    evR     = [data.evidenceRatio]';
    r       = [data.pokedR]';
    s_      = log(evR)./abs(gamma);
    ds      = .5;
    %sedges  = ceil(max(abs(s_))
    edges = [ -3:ds:3 ]
    sides = [data.correctAnswer]';
    medges = [ -3:.5:3 ]
    
    model_r = f{rr}.pr';
    
    model_h = (1 - model_r).*(~sides)+model_r.*sides;
    
    fh = figure(1); clf;
    set(fh,'position',[5 5 fw fw], 'paperposition',[0 0 fw fw], ...
        'papersize',[fw+.5 fw+.5]);
    
    ax = axes();
    plotPsychometric(s_, model_r, 'axHandle',ax,...
        'compute_fit', 0, 'plotfit',0, 'edges',medges,...
        'dataLineStyle','-','ploterrorbar',1,...
        'errorbar','gaussian',...
        'dataShaded',1, 'dataColor', p.model_color);
    
    plotPsychometric(s_, r, 'axHandle',ax,...
        'compute_fit', 0, 'plotfit',1,'edges',edges,...
        'dataLineStyle','.','dataMarkerSize',msz);
    
    ax.XGrid = 'off';
    ax.YGrid = 'off';
    ax.TickDir = 'out';
    ax.XTick = [-3 0 3];
    ax.XLim = [-3.25 3.25];
    ax.YLim = [-.035 1];
    ax.YTick = [0:.1:1];
    ax.YTickLabel = {'0' '' '' '' '' '' '' '' '' '' '1'};
    ax.YTick = [0 .25 .5 .75 1];
    ax.YTickLabel = {'0' '' '' '' '1'};
    %     plot([-.1 -.1], [.48 .495], 'w', 'linewidth', 2.5)
    %     plot([-.1 -.005], [.48 .48], 'w', 'linewidth', 2.5)
    
    ylabel('prob. go right');
    xlabel('log-odds supporting ''go right''');
    %     hl=legend('model','data','location','eastoutside');
    %
    %     box(hl,'off');
    %     set(hl, 'fontsize', fsz);
    %     hl.Position = hl.Position + [.05 -.2 .0 0];
    txt = text( -2.5,.9, 'model','color',p.model_color,'FontSize',fsz)
    txt.FontSize = fsz;
    text(-2.5, .8, 'data','FontSize',fsz)
    pbaspect(ax,[1 1.2 1])
    %set(ax,'fontname','dejavu sans')
    %set(ax,'fontname','dhelvetica neue')
    print(fh, fullfile(p.fig_dir, [ratname '_odds_psycho.svg']),'-dsvg','-painters')
    
    %% plot chrono for panel D
    dt = .2;
    fh = figure(2); clf
    set(fh,'position',[7 5 fw fw], 'paperposition',[0 0 fw fw], ...
        'papersize',[fw+.5 fw+.5]);
    ax = axes;
    
    ind = true(size(has_switch));
    tedges = [0:dt:max(time_from_last(ind))];
    
    stbins = [0  1 2 Inf];
    cm = (bone(length(stbins)))
    
    plotPsychometric(time_from_last, model_h,...
        'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',0,...
        'nbin',20,...
        'dataLineStyle','-','ploterrorbar',1,...
        'dataShaded',1, 'dataColor', p.model_color)
    
    for ii = 2:length(stbins)
        
        ind = switch_count >= stbins(ii-1) & switch_count < stbins(ii);
        [~,res] = plotPsychometric(time_from_last(ind), h(ind),...
            'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',1,...
            'dataLineStyle','o','dataMarkerSize',4.5,'dataFaceColor',cm(ii-1,:))
        
    end
    xlabel('final state duration (s)')
    
    ax.XGrid = 'off';
    ax.YGrid = 'off';
    ax.TickDir = 'out'
    ylim([.48 1])
    xlim([-.1 .1] + tedges([1 end]));
    %plot([-.1 -.1], [.48 .495], 'w', 'linewidth', 2.5)
    %plot([-.1 -.005], [.48 .48], 'w', 'linewidth', 2.5)
    %
    % ax.XRuler.Axle.Visible = 'off'
    % ax.YRuler.Axle.Visible = 'off'
    % ax.YRuler.Axle.Visible = 'off'
    
    set(ax,'ytick',[.5:.1:1])
    ylabel('prob. correct')
    set(ax,'yticklabel',{'50' '' '' '' '' '100'})
    ylabel('prob. correct')
    set(ax,'yticklabel',{'.5' '' '' '' '' '1'})
    
    hl=legend('model','0 switches','1','many','location','eastoutside')
    box(hl,'off')
    
    hl.Position = hl.Position + [.0 -.225 0 0]
    pbaspect(ax,[1 1.2 1])
    
    print(fh, fullfile(p.fig_dir, [ratname '_chrono_nswitches.svg']),'-dsvg',...
        '-painters')
    
    %% excess clicks for panel F
    excess_path = fullfile(p.data_dir, ratname, 'excess1');
    if ~exist(excess_path,'file')
        S = load_data(ratname, p);
        p.include.save = 0;
        S = save_good_data(ratname, S, p);
        clicks = analyze_excess_rates(ratname, S, p);
    end
    load(excess_path,'clicks');
    %%
    figure(4); clf
    
    [fh ax] = plot_excess_rates(clicks,'plot_model', 1, 'fig_num',4,...
        'model_color',p.model_color,'left_color',p.left_color,'right_color',p.right_color);
    
    set(fh,'position',[11 5 fw fw], 'paperposition',[0 0 fw fw], ...
        'papersize',[fw+.5 fw+.5]);
    ylim(ax,[-8.75 8]);
    xlim(ax,[-.525 0.0]);
    ax.XTick = [-.5:.1:0];
    ax.XTickLabel = {'-.5' '' '' '' '' '0'};
    ax.YTick = [-8:2:8];
    ax.YTickLabel = {'-8' '' '' '' '0' '' '' '' '8'};
    
    pbaspect(ax,[1.1 1.2 1])
    txt = text( -.5,-7, 'go left','color',p.left_color,'FontSize',fsz)
    txt.FontSize = fsz;
    text(-.5, -5.5, 'go right','color',p.right_color,'FontSize',fsz)
    
    ax.TickDir = 'out';
    xlabel(ax,'time from end of trial (s)')
    ylabel('stimulus weighting')
    print(fh, fullfile(p.fig_dir, [ratname '_excess']),'-dsvg','-painters')
end


%% panel E population chrono
fh = figure(3); clf
set(fh,'position',[11 5 fw fw], 'paperposition',[0 0 fw fw], ...
    'papersize',[fw+.5 fw+.5]);
ax = axes;
pop_tfl = []; pop_h = [];
for dd = 1:length(d)
    data = d{dd}.data;
    switch_count = cellfun(@length, {data.genSwitchTimes})';
    no_switch = (switch_count==0);
    has_switch = switch_count >= 1;
    T = [data.T]';
    time_from_last = T;
    r = [data.pokedR]';
    h = [data.hit]';
    
    time_from_last(has_switch) = time_from_last(has_switch) -...
        cellfun(@(x) x(end), {data(has_switch).genSwitchTimes})';
    plotPsychometric(time_from_last, h,...
        'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',1,...
        'ploterrorbar',0,'dataLineStyle','-','dataLineWidth',1,...
        'dataColor',[1 1 1].*.5)
    
    pop_tfl{dd} = time_from_last;
    pop_h{dd}   = h;
end

pop_tfl = vertcat(pop_tfl{:});
pop_h = vertcat(pop_h{:});

plotPsychometric(pop_tfl, pop_h,...
    'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',1,...
    'ploterrorbar',0,'dataLineStyle','-','dataLineWidth',2,...
    'dataColor',[1 1 1].*0)
xlabel('final state duration (s)')

ax.XGrid = 'off';
ax.YGrid = 'off';
ax.TickDir = 'out';
ylim([.48 1])
xlim([-.1 .1] + tedges([1 end]));

set(ax,'ytick',[.5:.1:1],'xtick',[0 :.5: 2])
ylabel('prob. correct')
set(ax,'yticklabel',{'50' '' '' '' '' '100'})
ylabel('prob. correct')
set(ax,'yticklabel',{'.5' '' '' '' '' '1'})
pbaspect(ax,[1 1.2 1])


txt = text( 1,.65, 'rats (n=6)','color',[1 1 1].*.5,'FontSize',fsz)
txt.FontSize = fsz;
text(1, .6, 'mean','color','k','FontSize',fsz)
print(fh, fullfile(p.fig_dir, ['population_chrono.svg']),'-dsvg',...
    '-painters')


%% panel G
load(fullfile(p.data_dir,'group_analysis'),'F')
%%
[fh ax] = plot_noise_lambda_tradeoff(F,'ephys')

set(fh,'position',[2 5 fw fw], 'paperposition',[0 0 fw fw], ...
    'papersize',[fw+.5 fw+.5]);
pbaspect(ax,[.9 1.2 1])
ax.TickDir = 'out';
print(fh, fullfile(p.fig_dir, ['lambda_tradeoff.svg']),'-dsvg',...
    '-painters')





%% end state chrono
%%
dt = .2;
fh = figure(3); clf
set(fh,'position',[5 5 fw fw], 'paperposition',[0 0 fw fw], ...
    'papersize',[fw+.5 fw+.5]);
ax = axes;


ind = true(size(has_switch));
tedges = [0:dt:max(time_from_last(ind))];
set(fh,'position',[11 5 3 3],'papersize',[4 4])
plotPsychometric(time_from_last(ind), model_h(ind),...
    'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',0,...
    'nbin',20,...
    'dataLineStyle','-','ploterrorbar',1,...
    'dataShaded',1, 'dataColor', p.model_color)

plotPsychometric(time_from_last(ind), h(ind),...
    'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',1,...
    'dataLineStyle','.')

xlabel('final state duration (s)')

ax.XGrid = 'off';
ax.YGrid = 'off';
ax.TickDir = 'out'
ylim([.48 1])
xlim([-.1 .1] + tedges([1 end]));
plot([-.1 -.1], [.48 .495], 'w', 'linewidth', 2.5)
plot([-.1 -.005], [.48 .48], 'w', 'linewidth', 2.5)
%
% ax.XRuler.Axle.Visible = 'off'
% ax.YRuler.Axle.Visible = 'off'
% ax.YRuler.Axle.Visible = 'off'

set(ax,'ytick',[.5:.1:1])
ylabel('prob. correct')
set(ax,'yticklabel',{'50' '' '' '' '' '100'})
ylabel('prob. correct')
set(ax,'yticklabel',{'.5' '' '' '' '' '1'})
pbaspect(ax,[1 1.2 1])

print(fh, fullfile(p.fig_dir, [ratname '_chrono.svg']),'-dsvg')


%%
dt = .2;
fh = figure(3); clf
ax = axes;
ind = true(size(has_switch));
tedges = [0:dt:max(time_from_last(ind))];
set(fh,'position',[11 5 3 3],'papersize',[4 4])
ctbins = [2 .8 0];
cm = (bone(length(ctbins+1)))

plotPsychometric(time_from_last(ind), model_h(ind),...
    'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',0,...
    'nbin',20,...
    'dataLineStyle','-','ploterrorbar',1,...
    'dataShaded',1, 'dataColor', p.model_color)

for ii = 2:length(ctbins)
    ind = T <= ctbins(ii-1) & T > ctbins(ii);
    [~,res] = plotPsychometric(time_from_last(ind), h(ind),...
        'edges',tedges, 'axHandle',ax,'compute_fit',0,'plotfit',1,...
        'dataLineStyle','o','dataMarkerSize',6,'dataFaceColor',cm(ii-1,:))
end
xlabel('final state duration (s)')

ax.XGrid = 'off';
ax.YGrid = 'off';
ax.TickDir = 'out'
ylim([.48 1])
xlim([-.1 .1] + tedges([1 end]));
xlim([-.1 2.1]);
plot([-.1 -.1], [.48 .495], 'w', 'linewidth', 2.5)
plot([-.1 -.005], [.48 .48], 'w', 'linewidth', 2.5)
%
% ax.XRuler.Axle.Visible = 'off'
% ax.YRuler.Axle.Visible = 'off'
% ax.YRuler.Axle.Visible = 'off'

set(ax,'ytick',[.5:.1:1])
ylabel('prob. correct')
set(ax,'yticklabel',{'50' '' '' '' '' '100'})
ylabel('prob. correct')
set(ax,'yticklabel',{'.5' '' '' '' '' '1'})

hl=legend('model','short trials','long trials','location','eastoutside')
box(hl,'off')
hl.Position = hl.Position + [.0 -.225 0 0]
print(fh, fullfile(p.fig_dir, [ratname '_chrono_short_long.svg']),'-dsvg')

%%
fh = figure(5);clf
set(fh,'position',[11 1 3 3],'papersize',[4 4])

ax = axes
s_ = [data.Delta]';
side_r = sides == 1;
xmax = round(max(abs(s_))/10)*10
dedges = linspace(-xmax,xmax,9)
plotPsychometric(s_, side_r, 'axHandle',ax,...
    'compute_fit', 0, 'plotfit',0,...
    'dataColor', 'r','edges',dedges)
plotPsychometric(s_, r, 'axHandle',ax,...
    'compute_fit', 0, 'plotfit',0,...
    'dataColor', 'k','edges',dedges)
% plotPsychometric(s_(has_switch), side_r(has_switch), 'axHandle',ax,...
%     'compute_fit', 0, 'plotfit',0,...
%     'dataColor', one_switch_color,'edges',dedges)
xlabel('click difference (r-l)')
ylabel('prob. go right')
hl=legend('true side','rat choice','no','location','east')
title(hl,'')
box(hl,'off')
ax.YGrid = 'off';
ax.XGrid = 'off';
hl.Position = hl.Position + [.05 -.225 0 0]
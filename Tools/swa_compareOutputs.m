function [output, unique_indices] = swa_compareOutputs(file1, file2, flag_plot, property_name)
% function which examines the similarities and differences between output
% files of the sleep wave detection process
%
% Usage:
% without plot
% output = swa_compareOutputs(file1, file2, 0, 'wavelengths');
%
% with plot
% output = swa_compareOutputs(file1, file2, 1);

% TODO: indicate the number of waves in each category

% load the files
handles.dataset{1} = load(file1);
handles.dataset{2} = load(file2);

% create figure
% ~~~~~~~~~~~~~

if flag_plot

    % find common waves
    % ~~~~~~~~~~~~~~~~~
    unique_indices = fcn_find_common_waves(handles);
    handles.unique_indices = unique_indices;
    
    % report different settings
    % ~~~~~~~~~~~~~~~~~~~~~~~~~
    handles.different_fields = fcn_find_parameter_differences(handles);
   
    handles = gui_interface(handles);
    fcn_select_options([], [], handles.fig)
    
    output = 1;
        
else
    
    % find common waves
    % ~~~~~~~~~~~~~~~~~
    unique_indices = fcn_find_common_waves(handles);
    
    % get summary measures for each type
    summary_measure{1} = swa_wave_summary(handles.dataset{1}.SW(unique_indices{1}),...
        handles.dataset{1}.Info, property_name, 0);
    summary_measure{2} = swa_wave_summary(handles.dataset{2}.SW(unique_indices{2}),...
        handles.dataset{2}.Info, property_name, 0);
    summary_measure{3} = swa_wave_summary(handles.dataset{1}.SW(~unique_indices{1}),...
        handles.dataset{1}.Info, property_name, 0);
    summary_measure{4} = swa_wave_summary(handles.dataset{2}.SW(~unique_indices{2}),...
        handles.dataset{2}.Info, property_name, 0);
    
    output = cellfun(@(x) median(x(1,:)), summary_measure);
    
end

function handles = gui_interface(handles)

% create the figure
handles.fig = figure(...
    'Name',         'Comparing Results',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0 0.04 .5 0.96]);

% difference table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.05, 0.8, 0.4, 0.15]  ,...
    'columnName',   {'parameter','dataset1','dataset2'},...
    'columnEditable', [false, false, false]);

% automatically adjust the column width using java handle
jscroll = findjobj(handles.table);
jtable  = jscroll.getViewport.getView;
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_ALL_COLUMNS);

% put the data into the table
set(handles.table, 'data', handles.different_fields);

% make the drop-down menus as java objects
[handles.java.options_list(1), handles.options_list(1)] = javacomponent(javax.swing.JComboBox);
set(handles.options_list(1),...
    'parent',   handles.fig,...      
    'units',    'normalized',...
    'position', [0.05 0.74 0.18 0.02],...
    'backgroundColor', [0.9, 0.9, 0.9]);
set(handles.java.options_list(1),...
    'ActionPerformedCallback', {@fcn_select_options, handles.fig});

% get the currently available options
options_list = swa_wave_summary('return options');

% create and set the java models for the options list
model1 = javax.swing.DefaultComboBoxModel(options_list);
handles.java.options_list(1).setModel(model1);

% unique axes
handles.axes_unique(1) = axes(...
    'parent',       handles.fig ,...
    'position',     [0.05 0.4 0.4 0.3] ,...
    'nextPlot',     'add' ,...
    'color',        'w' ,...
    'box',          'off');
handles.axes_unique(2) = axes(...
    'parent',       handles.fig ,...
    'position',     [0.55 0.4 0.4 0.3] ,...
    'nextPlot',     'add' ,...
    'color',        'w' );

% shared axes
handles.axes_shared(1) = axes(...
    'parent',       handles.fig ,...
    'position',     [0.05 0.03 0.4 0.3] ,...
    'nextPlot',     'add' ,...
    'color',        'w' );
handles.axes_shared(2) = axes(...
    'parent',       handles.fig ,...
    'position',     [0.55 0.03 0.4 0.3] ,...
    'nextPlot',     'add' ,...
    'color',        'w' );

% titles
handles.title_unique = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'unique',...
    'Units',    'normalized',...
    'Position', [0.05 0.72 0.9 0.02],...
    'backgroundColor', 'w',...
    'FontName', 'Century Gothic',...
    'FontSize', 14);

handles.title_shared = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'shared',...
    'Units',    'normalized',...
    'Position', [0.05 0.35 0.9 0.02],...
    'backgroundColor', 'w',...
    'FontName', 'Century Gothic',...
    'FontSize', 14);

handles.title_dataset(1) = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'dataset 1',...
    'Units',    'normalized',...
    'Position', [0.05 0.7 0.4 0.02],...
    'backgroundColor', 'w',...
    'FontName', 'Century Gothic',...
    'FontSize', 11);

handles.title_dataset(2) = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'dataset 2',...
    'Units',    'normalized',...
    'Position', [0.55 0.7 0.4 0.02],...
    'backgroundColor', 'w',...
    'FontName', 'Century Gothic',...
    'FontSize', 11);

% set the handles
guidata(handles.fig, handles) 

function fcn_select_options(~, ~, object)
% function to change the summary plots displayed

% get the handles from the figure
handles = guidata(object);

% clear whatever is on the current axes
cla(handles.axes_unique(1), 'reset'); cla(handles.axes_unique(2), 'reset');
cla(handles.axes_shared(1), 'reset'); cla(handles.axes_shared(2), 'reset');

% get the selected option
property_name = handles.java.options_list(1).getSelectedItem;

% draw the selected summary statistic on the axes
% get summary measures for each type
summary_measure{1} = swa_wave_summary(handles.dataset{1}.SW(handles.unique_indices{1}),...
    handles.dataset{1}.Info, property_name, 1, handles.axes_unique(1));
summary_measure{2} = swa_wave_summary(handles.dataset{2}.SW(handles.unique_indices{2}),...
    handles.dataset{2}.Info, property_name, 1, handles.axes_unique(2));

summary_measure{3} = swa_wave_summary(handles.dataset{1}.SW(~handles.unique_indices{1}),...
    handles.dataset{1}.Info, property_name, 1, handles.axes_shared(1));
summary_measure{4} = swa_wave_summary(handles.dataset{2}.SW(~handles.unique_indices{2}),...
    handles.dataset{1}.Info, property_name, 1, handles.axes_shared(2));

function unique_indices = fcn_find_common_waves(handles)

% get the SW structure out of the dataset structure
SW{1} = handles.dataset{1}.SW;
SW{2} = handles.dataset{2}.SW;

% get all the peak indices
peaks{1} = [SW{1}.Ref_PeakInd];
peaks{2} = [SW{2}.Ref_PeakInd];

% define the tolerance in samples
tol = ceil(0.100 * handles.dataset{1}.Info.Recording.sRate);
a_bin = floor(peaks{1} / tol); 
b_bin = floor(peaks{2} / tol); 

% get wave indices
unique_indices{1} = ~ismember(a_bin, b_bin);
unique_indices{2} = ~ismember(b_bin, a_bin);

function different_fields = fcn_find_parameter_differences(handles)

% get all the field names
info_fields = fieldnames(handles.dataset{1}.Info.Parameters);
info_fields2 = fieldnames(handles.dataset{2}.Info.Parameters);

% check for different fields in 1 > 2
if length(info_fields) ~= length(info_fields2)
    % find which ones don't match, report and delete from comparison
    ind = ~ismember(info_fields, info_fields2);
    if sum(ind) > 0
        ind_number = find(ind);
        for n = 1 : sum(ind)
            fprintf(1, '%s not found in one of the parameters \n',...
                info_fields{ind_number(n)});
        end
        info_fields(ind) = [];
    end
end
    
% check for different fields in 2 > 1
if length(info_fields2) ~= length(info_fields)
    % find which ones don't match, report and delete from comparison
    ind = ~ismember(info_fields2, info_fields);
    if sum(ind) > 0
        ind_number = find(ind);
        for n = 1 : sum(ind)
            fprintf(1, '%s not found in one of the parameters \n',...
                info_fields2{ind_number(n)});
        end
        info_fields2(ind) = [];
    end
end

% include the number of subset waves here
different_fields{1, 1} = 'unique';
different_fields{1, 2} = sum(handles.unique_indices{1});
different_fields{1, 3} = sum(handles.unique_indices{2});
different_fields{2, 1} = 'shared';
different_fields{2, 2} = sum(~handles.unique_indices{1});
different_fields{2, 3} = sum(~handles.unique_indices{2});

% loop through each parameter for differences
diff_count = 2;
for n = 1:length(info_fields)
   if ~isequal(handles.dataset{1}.Info.Parameters.(info_fields{n}),...
               handles.dataset{2}.Info.Parameters.(info_fields{n}))
        diff_count = diff_count +1;
        different_fields{diff_count, 1} = info_fields{n};
        temp = handles.dataset{1}.Info.Parameters.(info_fields{n});
        if isa(temp, 'double') & numel(temp) > 1
            different_fields{diff_count, 2} = max(temp);
        else
            different_fields{diff_count, 2} = temp;
        end
        
        temp = handles.dataset{2}.Info.Parameters.(info_fields{n});
        if isa(temp, 'double') & numel(temp) > 1
            different_fields{diff_count, 3} = max(temp);
        else
            different_fields{diff_count, 3} = temp;
        end        
    end
end



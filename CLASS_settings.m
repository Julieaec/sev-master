%> @file CLASS_settings.m
%> @brief CLASS_settings Control user settings and preferences of SEV.
% ======================================================================
%> @brief CLASS_settings used by SEV to initialize, store, and update
%> user preferences in the SEV.
%> The class is designed for storage and manipulation of user settings in
%> the SEV.
%
% ======================================================================
classdef  CLASS_settings < handle
%     (InferiorClasses = {?JavaVisible}) CLASS_settings < handle
    %CLASS_settings < handles
    %  A class for handling global initialization and settings
    %  - a.  Load settings - X
    %  - b.  Save settings - X
    %  - c.  Interface for editing the settings
    
    properties
        %> pathname of SEV working directory - determined at run time.
        rootpathname
        %> @brief name of text file that stores the SEV's settings
        %> (CLASS_UI_marking constructor will set this to <i>_sev.parameters.txt</i> by default)        
        parameters_filename
        %> @brief cell of string names corresponding to the struct properties that
        %> contain settings  <b><i> {'VIEW', 'BATCH_PROCESS', 'PSD',
        %> 'MUSIC'}</b></i>
        fieldNames;
        %> struct of SEV's single study mode (i.e. view) settings.
        VIEW;
        %> struct of SEV's batch mode settings.
        BATCH_PROCESS;
        %> struct of power spectral density settings.
        PSD;
        %> struct of multiple spectrum independent component settings.
        MUSIC;          
        %visibleObj;
    end
    
    methods(Static)
        
        % ======================================================================
        %> @brief Returns a structure of parameters parsed from the text file identified by the
        %> the input filename.  
        %> Parameters in the text file are stored per row using the
        %> following form:
        %> - fieldname1 value1
        %> - fieldname2 value2
        %> - ....
        %>an optional ':' is allowed after the fieldname such as
        %>fieldname: value
        %
        %The parameters is 
        %>
        %> @param filename String identifying the filename to load.
        %> @retval paramStruct Structure that contains the listed fields found in the
        %> file 'filename' along with their corresponding values
        % =================================================================
        function paramStruct = loadParametersFromFile(filename)
            % written by Hyatt Moore
            % edited: 10.3.2012 - removed unused globals; and changed PSD
            % 8/25/2013 - ported into CLASS_settings
            
            fid = fopen(filename,'r');
            paramStruct = CLASS_settings.loadStruct(fid);
            fclose(fid);            
        end
        
        % ======================================================================
        %> @brief Parses the file with file identifier fid to find structure
        %> and substructure value pairs.  If pstruct is passed as an input argument
        %> then the file substructure and value pairings will be put into it as new
        %> or overwriting fields and subfields.  If pstruct is not included then a
        %> new/original structure is created and returned.
        %> fid must be open for this to work.  fid is not closed at the end
        %> of this function.
        %> @param fid file identifier to parse
        %> @param pstruct (optional)
        %> @retval pstruct return value of tokens2struct call.
        % ======================================================================
        function pstruct = loadStruct(fid,pstruct)
        %pstruct = loadStruct(fid,{pstruct})
            
            % Hyatt Moore IV (< June, 2013)
            
            % ferror(fid,'clear');
            % status = fseek(fid,0,'bof'); %move to the beginning of file
            % ferror(fid);
            
            file_open = true;
            
            pat = '^([^\.\s]+)|\.([^\.\s]+)|\s+(.*)+$';

            if(nargin<2)
                pstruct = struct;
            end;
            
            while(file_open)
                curline = fgetl(fid);
                if(~ischar(curline))
                    file_open = false;
                else
                    tok = regexp(curline,pat,'tokens');
                    if(~isempty(tok) && ~strcmpi(tok{1},'-last'))
                        pstruct = CLASS_settings.tokens2struct(pstruct,tok);
                    end
                end;
            end;
        end
        
        
        % ======================================================================
        %> @brief helper function for loadStruct
        %> @param pstruct parent struct by which the tok cell will be converted to
        %> @tok cell array - the last cell is the value to be assigned while the
        %> previous cells are increasing nestings of the structure (i.e. tok{1} is
        %> the highest parent structure, tok{2} is the substructure of tok{1} and so
        %> and on and so forth until tok{end-1}.  tok{end} is the value to be
        %> assigned.
        %> the tok structure is added as a child to the parent pstruct.
        %> @retval pstruct Input pstruct with any additional tok
        %> children added.
        % ======================================================================
        function pstruct = tokens2struct(pstruct,tok)
            if(numel(tok)>1 && isvarname(tok{1}{:}))
                
                fields = '';
                
                for k=1:numel(tok)-1
                    fields = [fields '.' tok{k}{:}];
                end;
                
                %     if(isempty(str2num(tok{end}{:})))
                if(isnan(str2double(tok{end}{:})))
                    evalmsg = ['pstruct' fields '=tok{end}{:};'];
                else
                    evalmsg = ['pstruct' fields '=str2double(tok{end}{:});'];
                end;
                
                eval(evalmsg);
            end;
        end

    end
    
    methods
        
        % --------------------------------------------------------------------
        % ======================================================================
        %> @brief Class constructor
        %>
        %> Stores the root path and parameters file and invokes initialize
        %> method.  Default settings are used if no parameters filename is
        %> provided or found.
        %>
        %> @param string rootpathname Pathname of SEV execution directory (string)
        %> @param string parameters_filename Name of text file to load
        %> settings from.
        %>
        %> @return instance of the classDocumentationExample class.
        % =================================================================
        function obj = CLASS_settings(rootpathname,parameters_filename)
            %initialize settings in SEV....
            if(nargin==0)
                
            else
                obj.rootpathname = rootpathname;
                obj.parameters_filename = parameters_filename;
                obj.initialize();
            end
        end
        

        
        % --------------------------------------------------------------------
        % =================================================================
        %> @brief Constructor helper function.  Initializes class
        %> either from parameters_filename if such a file exists, or
        %> hardcoded default values (i.e. setDefaults).
        %>
        %> @param obj instance of the CLASS_settings class.
        % =================================================================
        function initialize(obj)
            %initialize global variables in SEV....
            obj.fieldNames = {'VIEW','BATCH_PROCESS','PSD','MUSIC'};
            obj.setDefaults();
            
            full_paramsFile = fullfile(obj.rootpathname,obj.parameters_filename);
            
            if(exist(full_paramsFile,'file'))                
                paramStruct = obj.loadParametersFromFile(full_paramsFile);
                if(~isstruct(paramStruct))
                    fprintf('\nWarning: Could not load parameters from file %s.  Will use default settings instead.\n\r',full_paramsFile);
                    
                else
                    fnames = fieldnames(paramStruct);
                    
                    if(isempty(fnames))
                        fprintf('\nWarning: Could not load parameters from file %s.  Will use default settings instead.\n\r',full_paramsFile);
                    else
                    
                        for f=1:numel(obj.fieldNames)
                            cur_field = obj.fieldNames{f};
                            if(~isfield(paramStruct,cur_field) || ~isstruct(paramStruct.(cur_field)))
                                fprintf('\nWarning: Could not load parameters from file %s.  Will use default settings instead.\n\r',full_paramsFile);
                                return;
                            else
                                structFnames = fieldnames(obj.(cur_field));
                                for g= 1:numel(structFnames)
                                    cur_sub_field = structFnames{g};
                                    %check if there is a corruption
                                    if(~isfield(paramStruct.(cur_field),cur_sub_field))
                                        fprintf('\nSettings file corrupted.  Using default SEV settings\n\n');
                                        return;
                                    end                            
                                end
                            end
                        end
                        
                        for f=1:numel(fnames)
                            obj.(fnames{f}) = paramStruct.(fnames{f});
                        end
                    end
                end
            end
        end
        
        % -----------------------------------------------------------------
        % =================================================================
        %> @brief Activates GUI for editing single study mode settings
        %> (<b>VIEW</b>,<b>PSD</b>,<b>MUSIC</b>)
        %>
        %> @param obj instance of CLASS_settings.        
        %> @retval wasModified a boolean value; true if any changes were
        %> made to the settings in the GUI and false otherwise.
        % =================================================================
        % --------------------------------------------------------------------
        function wasModified = update_callback(obj,settingsField)
            wasModified = false;
            switch settingsField
                case 'PSD'
                    newPSD = psd_dlg(obj.PSD);
                    if(newPSD.modified)
                        newPSD = rmfield(newPSD,'modified');
                        obj.PSD = newPSD;
                        wasModified = true;
                    end;                
                case 'MUSIC'
                    wasModified = obj.defaultsEditor('MUSIC');
                case 'CLASSIFIER'
                    plist_editor_dlg();
                case 'BATCH_PROCESS'
                case 'DEFAULTS'
                    wasModified= obj.defaultsEditor();
            end
        end
        
        % -----------------------------------------------------------------
        % =================================================================
        %> @brief Activates GUI for editing single study mode settings
        %> (<b>VIEW</b>,<b>PSD</b>,<b>MUSIC</b>)
        %>
        %> @param obj instance of CLASS_settings class.
        %> @retval wasModified a boolean value; true if any changes were
        %> made to the settings in the GUI and false otherwise.
        % =================================================================
        function wasModified = defaultsEditor(obj,optional_fieldName)
            tmp_obj = obj.copy();
            if(nargin<2)
                lite_fieldNames = {'VIEW','PSD','MUSIC'}; %these are only one structure deep
            else
                lite_fieldNames = optional_fieldName;
                if(~iscell(lite_fieldNames))
                    lite_fieldNames = {lite_fieldNames};
                end
            end
            
            tmp_obj.fieldNames = lite_fieldNames;
            tmp_obj = pair_value_dlg(tmp_obj);
            if(~isempty(tmp_obj))
                for f=1:numel(lite_fieldNames)
                    fname = lite_fieldNames{f};
                    obj.(fname) = tmp_obj.(fname);
                end
                wasModified = true;
                tmp_obj = []; %clear it out.

            else
                wasModified = false;
            end
        end
        
        % -----------------------------------------------------------------
        % =================================================================
        %> @brief saves all of the fields in saveStruct to the file filename
        %> as a .txt file
        %
        %
        %> @param obj instance of CLASS_settings class.
        %> @param saveStruct (optional) structure of parameters and values
        %> to save to the text file identfied by obj property filename or
        %> the input paramater filename.  Enter empty (i.e., []) to save
        %> all available fields
        %> @param filename (optional) name of file to save parameters to.
        % =================================================================
        % -----------------------------------------------------------------
        function saveParametersToFile(obj,dataStruct2Save,filename)
            %written by Hyatt Moore IV sometime during his PhD (2010-2011'ish)
            %
            %last modified
            %   9/28/2012 - added CHANNELS_CONTAINER.saveSettings() call - removed on
            %   9/29/2012
            %   7/10/2012 - added batch_process.images field
            %   5/7/2012 - added batch_process.database field
            %   8/24/2013 - import into settings class; remove globals
            
            if(nargin<3)
                filename = obj.parameters_filename;
                if(nargin<2)
                    dataStruct2Save = [];
                end                
            end
            
            if(isempty(dataStruct2Save))
                fnames = obj.fieldNames;
                for f=1:numel(fnames)
                    dataStruct2Save.(fnames{f}) = obj.(fnames{f});               
                end
            end
            
            fid = fopen(filename,'w');
            if(fid<0)
                [path, fname, ext]  = fileparts(filename);
                fid = fopen(fullfile(pwd,[fname,ext]));
            end
            if(fid>0)
                fprintf(fid,'-Last saved: %s\r\n\r\n',datestr(now)); %want to include the '-' sign to prevent this line from getting loaded in the loadFromFile function (i.e. it breaks the regular expression pattern that is used to load everything else).
                
                saveStruct(fid,dataStruct2Save)
                %could do this the other way also...
                %                     %saves all of the fields in inputStruct to a file
                %                     %filename as a .txt file
                %                     fnames = fieldnames(saveStruct);
                %                     for k=1:numel(fnames)
                %                         fprintf(fid,'%s\t%s\n',fnames{k},num2str(saveStruct.(fnames{k})));
                %                     end;
                fclose(fid);
            end
        end
        
        % --------------------------------------------------------------------
        %> @brief sets default values for the class parameters listed in
        %> the input argument <i>fieldNames</i>.
        %> @param obj instance of CLASS_settings.
        %> @param fieldNames (optional) string identifying which of the object's
        %> parameters to reset.  Multiple field names may be listed using a
        %> cell structure to hold additional strings.  If no argument is provided or fieldNames is empty
        %> then object's <i>fieldNames</i> property is used and all
        %> parameter structs are reset to their default values.
        function setDefaults(obj,fieldNames)
            
            if(nargin<2)
                fieldNames = obj.fieldNames; %reset all then
            end
            
            if(~iscell(fieldNames))
                fieldNames = {fieldNames};
            end
            
            for f = 1:numel(fieldNames)
                switch fieldNames{f}
                    case 'VIEW'
                        obj.VIEW.src_edf_pathname = '.'; %initial directory to look in for EDF files to load
                        obj.VIEW.src_edf_filename = ''; %initial filename to suggest when trying to load an .EDF
                        obj.VIEW.src_event_pathname = '.'; %initial directory to look in for EDF files to load
                        obj.VIEW.batch_folder = '.'; %'/Users/hyatt4/Documents/Sleep Project/EE Training Set/';
                        obj.VIEW.yDir = 'normal';  %or can be 'reverse'
                        obj.VIEW.standard_epoch_sec = 30; %perhaps want to base this off of the hpn file if it exists...
                        obj.VIEW.samplerate = 100;
                        obj.VIEW.screenshot_path = obj.rootpathname; %initial directory to look in for EDF files to load
                        
                        obj.VIEW.channelsettings_file = 'channelsettings.mat'; %used to store the settings for the file
                        obj.VIEW.output_pathname = 'output';
                        obj.VIEW.detection_inf_file = 'detection.inf';
                        obj.VIEW.detection_path = '+detection';
                        obj.VIEW.filter_path = '+filter';
                        obj.VIEW.filter_inf_file = 'filter.inf';
                        obj.VIEW.database_inf_file = 'database.inf';
                        obj.VIEW.parameters_filename = '_sev.parameters.txt';
                    case 'MUSIC'                        
                        obj.MUSIC.window_length_sec = 2;
                        obj.MUSIC.interval_sec = 2;
                        obj.MUSIC.num_sinusoids = 6;
                        obj.MUSIC.freq_min = 0; %display min
                        obj.MUSIC.freq_max = 30; %display max                        
                    case 'PSD'                        
                        obj.PSD.wintype = 'hann';
                        obj.PSD.removemean = 'true';
                        obj.PSD.FFT_window_sec = 2; %length in second over which to calculate the PSD
                        obj.PSD.interval = 2; %how often to take the FFT's
                        obj.PSD.freq_min = 0; %display min
                        obj.PSD.freq_max = 30; %display max                        
                    case 'BATCH_PROCESS'
                        obj.BATCH_PROCESS.edf_folder = '.'; %the edf folder to do a batch job on.
                        obj.BATCH_PROCESS.output_path.parent = 'output';
                        obj.BATCH_PROCESS.output_path.roc = 'ROC';
                        obj.BATCH_PROCESS.output_path.power = 'PSD';
                        obj.BATCH_PROCESS.output_path.events = 'events';
                        obj.BATCH_PROCESS.output_path.artifacts = 'artifacts';
                        obj.BATCH_PROCESS.output_path.images = 'images';
            
                        %power spectrum analysis
                        obj.BATCH_PROCESS.output_files.psd_filename = 'psd.txt';
                        obj.BATCH_PROCESS.output_files.music_filename = 'MUSIC';
                        
                        %artifacts and events
                        obj.BATCH_PROCESS.output_files.events_filename = 'evt.';
                        obj.BATCH_PROCESS.output_files.artifacts_filename = 'art.';
                        obj.BATCH_PROCESS.output_files.save2txt = 1;
                        obj.BATCH_PROCESS.output_files.save2mat = 0;
                        
                        %database supplement
                        obj.BATCH_PROCESS.database.save2DB = 0;
                        obj.BATCH_PROCESS.database.filename = 'database.inf';
                        obj.BATCH_PROCESS.database.choice = 1;
                        obj.BATCH_PROCESS.database.auto_config = 1;
                        obj.BATCH_PROCESS.database.config_start = 1;
                        
                        %summary information
                        obj.BATCH_PROCESS.output_files.cumulative_stats_flag = 0;
                        obj.BATCH_PROCESS.output_files.cumulative_stats_filename = 'SEV.cumulative_stats.txt';
                        
                        obj.BATCH_PROCESS.output_files.individual_stats_flag = 0;
                        obj.BATCH_PROCESS.output_files.individual_stats_filename_suffix = '.stats.txt';
                        
                        obj.BATCH_PROCESS.output_files.log_checkbox = 1;
                        obj.BATCH_PROCESS.output_files.log_filename = '_log.txt';
                        
                        %images
                        obj.BATCH_PROCESS.images.save2img = 1;
                        obj.BATCH_PROCESS.images.format = 'PNG';
                        obj.BATCH_PROCESS.images.limit_count = 100;
                        obj.BATCH_PROCESS.images.limit_flag = 1;
                        obj.BATCH_PROCESS.images.buffer_sec = 0.5;
                        obj.BATCH_PROCESS.images.buffer_flag = 1;
                end
            end
        end
    end
    
    methods (Access = private)
        
        % -----------------------------------------------------------------
        %> @brief create a new CLASS_settings object with the same property
        %> values as this one (i.e. of obj)
        %> @param obj instance of CLASS_settings
        %> @retval copyObj a new instance of CLASS_settings having the same
        %> property values as obj.
        % -----------------------------------------------------------------
        function copyObj = copy(obj)
            copyObj = CLASS_settings();
            
            props = properties(obj);
            if(~iscell(props))
                props = {props};
            end
            for p=1:numel(props)
                pname = props{p};
                copyObj.(pname) = obj.(pname);
            end
        end
 
    end
end

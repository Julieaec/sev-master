function detectStruct=detect_eye_movements(data,optional_params, stageStruct)
%(EOG1,EOG2,Stagesamples,Flagged_samples)
% detect_eye_movements is based on McPartland and Kupfer's
% paper, "Computerized measures of EOG activity during sleep" - 1977/1978
%
% Written by Emil G.S. Munk
% Thanks must be given to Hyatt Errol Moore IV

if(nargin>=2 && ~isempty(optional_params))
    params = optional_params;
else
    
    pfile = strcat(mfilename('fullpath'),'.plist');
    
    if(exist(pfile,'file'))
        %load it
        params = plist.loadXMLPlist(pfile);
    else
        %make it and save it for the future
        params.UTH = 25;
        %within 100 mseconds of each other
        params.sync_range_seconds = 0.1;
        %params.sync_threshold = ceil(params.sync_range_seconds*params.samplerate);
        params.min_duration_sec = 0.1;
        %params.dur_threshold = params.min_duration_sec*params.samplerate;
        
        params.np = 11;
        %params.b = ones(1,params.np)/params.np;
        plist.saveXMLPlist(pfile,params);
    end
end


samplerate = params.samplerate;

%detectStruct.new_data = data;

EOG1 = filter(ones(1,params.np)/params.np,1,data{1});
EOG2 = filter(ones(1,params.np)/params.np,1,data{2});

% Finding threshold crossings
C1 = thresholdcrossings(abs(EOG1),params.UTH);
C2 = thresholdcrossings(abs(EOG2),params.UTH);

% Adding channel information
C1 = [C1 ones(size(C1,1),1)];
C2 = [C2 ones(size(C2,1),1)*2];

% Adding sign information
C1 = [C1 sign(EOG1(C1(:,1)))];
C2 = [C2 sign(EOG2(C2(:,1)))];

% Pairing UTH/LTH crossings from different channels
C = sortrows([C1;C2]);

%% Calculating metrics
% Syncronization time
Sync = C(2:end,1)-C(1:end-1,1);

% Dual channel crossings
Channel = C(2:end,3)-C(1:end-1,3)~=0;

% Different signs
Signs = C(2:end,4)-C(1:end-1,4)~=0;

% Duration
Dur = min([C(1:end-1,2)-C(1:end-1,1),C(2:end,2)-C(1:end-1,1)],[],2);

% Overlapping
Overlap = C(1:end-1,2)-C(2:end,1)>0;

% Checking conditions
REM_indices = all([Sync<ceil(params.sync_range_seconds*...
    samplerate),Channel,Signs,Dur>params.min_duration_sec*...
    samplerate,Overlap],2);

% Creating data structure
REMs = [C(REM_indices,1),C(REM_indices,1)+Dur(REM_indices),...
    Dur(REM_indices),Sync(REM_indices)];

%detectStruct.new_data{1} = data{1}.*2;
%detectStruct.new_data{2} = data{2}.*2;
detectStruct.new_data = data;

detectStruct.new_events = REMs(:,1:2);

detectStruct.paramStruct.dur = REMs(:,3);
detectStruct.paramStruct.sync = REMs(:,4);

%% Removing eye movements in flagged areas or bad stages (scored 7)
% bad_samples = union(find(Flagged_samples==1),find(Stagesamples==7));
% for r = 1:size(REMs,1)
% include_REM(r) = isempty(intersect(REMs(r,1):REMs(r,2),bad_samples));
% end
% REMs = REMs(include_REM,:);
% keyboard
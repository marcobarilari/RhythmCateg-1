function datalog = saveOutput(datalog, cfg, expParam, action)


% make sure logiles directory exists 
if ~exist('logfiles','dir')
    mkdir('logfiles')
end

DateFormat = 'yyyy_mm_dd_HH_MM';

Filename = fullfile(pwd, 'logfiles', ...
    ['sub-' datalog.subjectNumber, ...
    '_run-' datalog.runNumber, ...
    '_' datestr(now, DateFormat)]);



%% MAIN EXPERIMENT
if strcmp(expParam.task,'tapMainExp')

    switch action

        % ==================================================================================
        case 'open'

            %----------------------------------------
            % .tsv file for stimulus
            %----------------------------------------

            % open text file
            datalog.fidStim = fopen([Filename,'_mainStimulus.tsv'], 'w'); %'a'

            % print header
            fprintf(datalog.fidStim,'subjectID\trunNumber\tpatternID\tcategory\tonsetTime\tF0\tgridIOI\n'); 

            %----------------------------------------
            % .tsv file for tapping
            %----------------------------------------

            % open text file
            datalog.fidTap = fopen([Filename,'_mainTapping.tsv'], 'w'); %'a'

            % print header
            fprintf(datalog.fidTap, 'subjectID\trunNumber\tseqi\ttapOnset\n'); 

        % ==================================================================================
        case 'update'

        % ==================================================================================
        case 'savemat'

            % save all config structures and datalog to .mat file
            save(fullfile([Filename,'_mainAll.mat']), 'datalog', 'cfg', 'expParam')

        % ==================================================================================
        case 'close'

            % close txt log files
            if isfield(datalog,'fidStim') || isfield(datalog,'fidTap')
                fclose(datalog.fidStim);
                fclose(datalog.fidTap);
            end

    end

    
    
%% TAP TRAINING
elseif strcmp(expParam.task,'tapTraining')
    
    switch action

        % ==================================================================================
        case 'open'

            % open tsv file
            datalog.fidTapTrainer = fopen([Filename,'_tapTraining.tsv'], 'w'); %'a'

            % print header
            fprintf(datalog.fidTapTrainer, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
            'subjectID',...             % subject id
            'pattern',...               % pattern 
            'seqStartTime',...          % machine time of sequence audio start
            'cuePeriod',...             % cue (i.e. metronome) period (N of grid-points)
            'cueLeveldB',...            % cue (i.e. metronome) level in dB 
            'analysisWin', ...          % index (count) of this analysis window (for this sequence)
            'winStartTime', ...         % analysis window start time wrt sequence start
            'tapOnset');                % tap onset time relative to sequence start time

        % ==================================================================================
        case 'update'

        % ==================================================================================
        case 'savemat'

            % save all config structures and datalog to .mat file
            save(fullfile([Filename,'_tapTraining.mat']), 'datalog', 'cfg', 'expParam')

        % ==================================================================================
        case 'close'

            % close txt log files
            if isfield(datalog,'fidStim') || isfield(datalog,'fidTap')
                fclose(datalog.fidStim);
                fclose(datalog.fidTap);
            end
    end

    
    
end

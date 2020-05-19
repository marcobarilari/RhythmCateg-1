% 
% TO DO: 
%     - PTB latency test? (but audio capture device may be late anyway so no
%       point in doing this...)
%     - test on Windows/Linux


% for complexity check please see following repo: 
% https://github.com/Remi-Gau/matlab_checkcode

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc
PsychPortAudio('Close');


tic
%%
% paths
% make sure we got access to all the required functions and inputs
addpath(genpath(fullfile(pwd, 'lib')))

% % % refactor this part to run training + exp within 1 go?
% parameters
[cfg,expParam] = getParams('tapTraining'); 
% % % 

% datalogging structure
datalog = []; 

% get time point at the beginning of the experiment (machine time)
datalog.experimentStartTime = GetSecs();

% set and load all the subject input to run the experiment
[datalog] = getSubjectID(cfg);


try
    [cfg] = initPTB(cfg);
    
    % Prepare for the output logfiles
    datalog = saveOutput(datalog, cfg, expParam, 'open'); 


    % show instructions and do initial volume setting
    displayInstr(expParam.taskInstruction,cfg,'setVolume');         
    
    % simultenaous feedback 
    fbkOnScreen = false; 
    
    % index (counter) of current pattern that is used in the stimulus
    % sequence
    currPatterni = 1; 

    
    
    %% loop over patterns (atm, n pattern = 2)
    while 1
        
        % change screen to "TAP" instruction 
        displayInstr('TAP',cfg,'instrAndQuitOption');   
        
        % once the pattern is repeated 4 times, the script looks back in
        % this time window, this is an index (counter) of analysis windows
        % for the current sequence
        currWini = 1; 
        
        % dB changes in the loop - tapping cue (decreases over time if the
        % error rate is low(er))
        % which dB sound will be played choose the index in the list
        cueDBleveli = 1; 
        
        %number of grip points between two tapping cue sounds
        %convert the grip interval to target inter-tap-interval in seconds.
        % every 800ms there'll be a cue sound to tap along
        cuePeriod = cfg.cuePeriod(currPatterni)*cfg.gridIOI;
        
        % total duration of the analysis window (4 x pattern) in seconds
        winDur = cfg.nCyclesPerWin * length(cfg.patterns{currPatterni}) * cfg.gridIOI; 
        
        % time from the start of the analysis window (in secs) taken to analyse the tapping
        taketapDur = winDur - 0.200; 
        
        %to be used later on to calculate the min number that participant
        %has to tap - 
        maxPossibleNtaps = floor(taketapDur/cuePeriod);
        
        % minimum required number of taps in an analysis window 
        % (70% of max possible taps in the window)
        minNtaps = floor(maxPossibleNtaps*cfg.minNtapsProp); 
                
        % counters for calculating the tapping accuracy later on
        performStatus = 0; % if good +1, if bad -1
        taps = []; 
        istap = false;

        
        %% allocate datalog variables
         winIdxs            = []; 
         cueDBs             = []; 
         winStartTimes      = []; 
         feedbacks          = {}; 

         
        %% make stimuli
        % get audio for the first step/window (4 x pattern)
        [seq] = makeStimTrain(cfg, currPatterni, cueDBleveli);  

        
        %% fill the buffer 
        % first, fill the buffer with 60s silence
        

        % to get a buffer longer than what you are pushing
        % allocate the buffer
        
        % if case some stays too long in the while loop, we will need this
        % buffer to allocate
        PsychPortAudio('FillBuffer', cfg.pahandle, zeros(2, 60*cfg.fs)); 
        
        
        %% start playback
        % start playback (note: set repetitions=0, otherwise it will not allow you to seamlessly push more data into the buffer once the sound is playing)  
        % starts to play whats in the buffer and play on whatever is in on
        % a seamlessly in the loop
        currSeqStartTime = PsychPortAudio('Start', cfg.pahandle, 0, [], 1); 
        % startTime = PsychPortAudio('Start', pahandle [, repetitions=1] [, when=0] [, waitForStart=0] [, stopTime=inf] [, resume=0]);
        
        % 1 sound input into 1 channels also works
        audio2push = [seq.s;seq.s]; 

        %silence is going, then we will upload to the buffer audio sequence after the
        % 1s of silent has started
        [underflow] = PsychPortAudio('FillBuffer', cfg.pahandle, audio2push, 1, cfg.reqsampleoffset);

        % and update start time (by offset)
        % start time = actual time of audio seq presented
        currSeqStartTime = currSeqStartTime+cfg.requestoffsettime; 
        currWinStartTime = currSeqStartTime; 
        nSamplesAudio2push = 0; 
        idx2push = 1; 

        
        
        
        %% loop over pattern windows (in which we may change dB levels atm)
        while 1
            
            
            
            
            %% tapping while loop
            while GetSecs < (currWinStartTime+taketapDur)

                % collect tapping 
                [~,tapOnset,keyCode] = KbCheck(-1);
                
                % terminate if quit-button pressed
                if find(keyCode)==cfg.keyquit
                    error('Experiment terminated by user...');                     
                end
                
                % if they did not press delete, it looks for any response
                % button and saves the time                 
                if ~istap && any(keyCode)
                    taps = [taps,tapOnset-currSeqStartTime];
                    istap = true;
                    
                    % -------------------- log ----------------------------
                    % now we have some time before they tap again so let's
                    % write to the log file            
                    fprintf(datalog.fidTapTrainer, '%s\t%d\t%f\t%f\t%f\t%d\t%f\t%f\n', ...
                        datalog.subjectNumber,...                 % subject id
                        currPatterni, ...                 % pattern 
                        currSeqStartTime,...                          % machine time of sequence audio start
                        cuePeriod,...             % cue (i.e. metronome) period (N of grid-points)
                        cfg.cueDB(cueDBleveli),... % cue (i.e. metronome) level in dB (SNR)
                        currWini, ...                          % index (count) of this analysis window (for this sequence)
                        currWinStartTime-currSeqStartTime,...     % analysis window start time wrt sequence start
                        taps(end));                             % tap onset time relative to sequence start time
                    % -----------------------------------------------------
                end
                
                % it counts as tap if reponse buttons were released
                % initially
                if istap && ~any(keyCode)
                    istap = false;
                end

                % if there is any audio waiting to be pushed, push it to the buffer!
                if nSamplesAudio2push
                    if idx2push + cfg.audio.pushsize > nSamplesAudio2push
                        pushdata = audio2push(:,idx2push:end);
                        nSamplesAudio2push = 0; 
                    else
                        pushdata = audio2push(:,idx2push:idx2push + cfg.audio.pushsize-1);
                        idx2push = idx2push + cfg.audio.pushsize;
                    end
                    [curunderflow, ~, ~] = PsychPortAudio('FillBuffer', cfg.pahandle, pushdata, 1);
                end

                
                % if there is overdue feedback on the screen, remove it
                if fbkOnScreen
                    if (GetSecs-fbkOnScreenTime)>cfg.fbkOnScreenMaxtime
                        fbkOnScreen = false; 
                        % change screen back to "TAP" instruction 
                        displayInstr('TAP',cfg,'instrAndQuitOption');   
                    end
                end       
                
                
            end      


            %% 
            
            %let's look at the last window to analyse the tapping
            % evaluate tapping and decide on the next step/window parameters
            %look at which window you are in (curr_step_
            % taps you will consider : step_dur
            minTaketapTime = (currWini-1)*winDur; 
            maxTaketapTime = (currWini)*winDur;
            
            % we will only take the taps which are relevant - in our
            % current window
            %test test 
            %curr_taps = [0:0.8:6.2] + randn(1,8)*0.1
            currTaps = taps(taps>minTaketapTime & taps<maxTaketapTime) - minTaketapTime; 
            
            %making tapping vector
            disp(currTaps')
            currTapsN = length(currTaps); 

            % round to the closest beat position
            % there are target positions set by the cue. But they can skip
            % a tap and still be good in synch. round the mto the closest
            % beat positions. that will give you the target position. and
            % you calculate the how far your target + your current taps
            targetTapTimes = round(currTaps/cuePeriod)*cuePeriod; 

            % calculate asynchronies
            tapAsynch = currTaps - targetTapTimes; 
            %first normalise it by the interval. because your variability
            %is proportional to the legnth of the interval (equalise across
            %different time interval/tempi)
            %then std it 
            tapCvAsynch = std(tapAsynch/cuePeriod); 
            
            

            %% update tapping performance
            % (wrt cvASY threshold and n-taps)
            % tap_perform_status = -1, 0, 1, 2, 3, ...(correctness)
            
            if (tapCvAsynch < cfg.tapCvAsynchThr) && currTapsN>=minNtaps
                % good performance, one up!
                currPerform       = 'good'; 
                performStatus = max(0,performStatus); % if negative make 0
                performStatus = performStatus+1; 
            else
                % bad performance, one down...
                currPerform       = 'bad'; 
                performStatus = min(0,performStatus); % if positive make 0
                performStatus = performStatus-1; 
            end

                    
            
            %% update datalog variables

            % index (count) of the current analysis window
            winIdxs           = [winIdxs, currWini]; 
            % cue dB level (SNR)
            cueDBs             = [cueDBs, cfg.cueDB(cueDBleveli)]; 
            % start time of the analysis window (wrt sequence start time)
            winStartTimes      = [winStartTimes, currWinStartTime-currSeqStartTime]; 
            % feedback for the current window (good/bad)
            feedbacks          = [feedbacks, currPerform]; 


            %% update next window parameters
            % staircase here to adapt
            
            % if this window was the last dB level, and the last-dB-level
            % counter is equal to the goal number
            if (cueDBleveli==cfg.nCueDB) && (performStatus==cfg.nWinUp_lastLevel)
                
                % stop the audio
                PsychPortAudio('Stop',cfg.pahandle,1);
                
                % end the loop over pattern windows (we will continue with
                % the following pattern after participant has a break)
                break 
            
                
                
            % if we are not yet in the last level, and we have enough good
            % successive windows, we need to move one db-level up
            elseif (cueDBleveli~=cfg.nCueDB) && (performStatus==cfg.nWinUp) 
                
                % reset the performance counter to start next level from 0
                performStatus = 0; 
                
                % increase the dB level one step up
                cueDBleveli = cueDBleveli+1; 
                
                % Give positive feedback. 
                txt = [sprintf('level %d out of %d.\n\n',cueDBleveli,cfg.nCueDB), ...
                        sprintf('(error = %.3f)\n\n',tapCvAsynch), ...
                       'Well done!']; 
                displayInstr(txt,cfg);
                fbkOnScreenTime = GetSecs; 
                fbkOnScreen = 1; 
                
                
            % disregarding which level you are in, if the last N successive steps    
            % were bad (N == n_steps_down) -> decrease level
            elseif performStatus <= -cfg.nWinDown
                
                % reset the performance counter to start the next (decreased) level from 0
                performStatus = 0; 
                
                % decrease the dB level one step down (don't change if it
                % is already at the lowest possible level)
                cueDBleveli = max(cueDBleveli-1, 1); 
                
                % Give negative feedback. 
                txt = [sprintf('level %d out of %d.\n\n',cueDBleveli,cfg.nCueDB), ...
                        sprintf('(error = %.3f)\n\n',tapCvAsynch), ...
                       'Keep trying :)']; 
                displayInstr(txt,cfg);
                fbkOnScreenTime = GetSecs; 
                fbkOnScreen = 1; 
                
                
            % otherwise just give feedback and continue...
            else
                txt = [sprintf('level %d out of %d.\n\n',cueDBleveli,cfg.nCueDB), ...
                       sprintf('(error = %.3f)\n\n',tapCvAsynch), ...
                       sprintf('\n')]; 
                displayInstr(txt,cfg);
                fbkOnScreenTime = GetSecs; 
                fbkOnScreen = 1; 

            end
            
            
            fprintf('current metronome-SNR level = %d\n',cueDBleveli); 
            % ---- end of next window parameters update ----
            
            
            

            
            %% create audio with the new dB level for the next step/window
            [seq] = makeStimTrain(cfg, currPatterni, cueDBleveli); 
           
            %update the push variable
            audio2push = [seq.s;seq.s];   
            nSamplesAudio2push = size(audio2push,2); 
            idx2push = 1; 

            % update step counter
            currWini = currWini+1; 
            
            % Update current time! 
            % This will be used as the start time of the following window
            currWinStartTime = currWinStartTime + winDur; 
            
        end

        %====================== update datalog =============================

        % save (machine) onset time for the current sequence
        datalog.data(currPatterni).currSeqStartTime = currSeqStartTime; 

        % save current sequence information (without the audio, which can
        % be easily resynthesized)
        datalog.data(currPatterni).seq = seq; 
        datalog.data(currPatterni).seq.s = []; 

        % save all the taps for this sequence
        datalog.data(currPatterni).taps = taps; 

        % save PTB volume
        datalog.data(currPatterni).ptbVolume = PsychPortAudio('Volume',cfg.pahandle); 

        % save other window-level variables
        datalog.data(currPatterni).wini = winIdxs; 
        datalog.data(currPatterni).cueDBs = cueDBs; 
        datalog.data(currPatterni).winStartTimes = winStartTimes; 
        datalog.data(currPatterni).feedbacks = feedbacks; 
        
        %========================= instructions ===============================
        
        if currPatterni==cfg.nPatterns
            % end of last pattern
            txt = expParam.afterSeqInstruction{currPatterni}; 
            displayInstr(txt,cfg,'waitForKeypress');  
            % end of experient
            displayInstr('DONE. \n\n\nTHANK YOU FOR PARTICIPATING :)',cfg);  
            % wait 3 seconds and end the experiment
            WaitSecs(3); 
            break
        else
            % end of one pattern
            txt = expParam.afterSeqInstruction{currPatterni}; 
            displayInstr(txt,cfg,'setVolume');  
        end        
        
        %========================= update counter ===============================

        % we will move on to the next pattern in the following loop iteration 
        currPatterni = currPatterni+1; 

    end
    
    saveOutput(datalog, cfg, expParam, 'savemat'); 
    saveOutput(datalog, cfg, expParam, 'close'); 

    cleanUp(cfg)

    
catch 
    
    saveOutput(datalog, cfg, expParam, 'savemat'); 
    saveOutput(datalog, cfg, expParam, 'close'); 

    cleanUp(cfg)
    
    psychrethrow(psychlasterror);
end
    

   
%take the last time
expTime = toc;

%% print the duration of the exp
%fprintf('\nexp. duration was %f minutes\n\n', expTime/60);


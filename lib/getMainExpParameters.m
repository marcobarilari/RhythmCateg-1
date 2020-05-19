function     [cfg,expParam] = getMainExpParameters(cfg,expParam)
% this function generates audio sequences to be played in the man
% experiment

% % % 
% should be considered exp.parameter structure for experiment/sequence related
% parameters
% > later on for fMRI, I'll separate exp from cfg (all make stim == exp,
% all fmri parameters - cfg)
% % %

% % %
% start the sequence with one B-category segment that will be discarded during analysis
% % %


% wait before running the exp
expParam.onsetDelay = 0;

%wait in between sequences? y/n
expParam.sequenceDelay = 1;

% give a pause of below seconds in between sequences
expParam.pauseSeq = 1; 

% define ideal number of sequences to be made
if cfg.debug
    expParam.numSequences = 6; % multiples of 3
else
    expParam.numSequences = 3;
end
%% contruct individual sound events (that will make up each pattern)

% define envelope shape of the individual sound event
% all parameters are defined relative to the gridIOI (as proportion of gridIOI)
% we don't use minGridIOI to keep everything proportional if the gridIOI is
% allowed to change across cycles
% And ramps are applied to each sound event

% total sound duration proportion to gridIOI _/```\_  
cfg.soundDurProp             = 1; % 100% of gridIOI
% onset ramp duration  _/     
cfg.eventRampon          = 0.05; % 5% of gridIOI 
% offset ramp duration       \_ 
cfg.eventRampoff         = 0.020; % 10% of gridIOI


%% construct pattern (smallest item in sequence)
cfg.nGridPoints = 12; % length(pat_complex(1).pattern)

% the grid interval can vary across steps or segments (gridIOI selected 
% randomly from a set of possible values for each new step or segment) 
cfg.minGridIOI 	= 0.190;  % minimum possible grid IOI 
cfg.maxGridIOI 	= 0.190; % maximum possible grid IOI 
cfg.nGridIOI 	= 1; 	% number of unique IOI values between the limits
cfg.gridIOIs 	= linspace((cfg.minGridIOI),(cfg.maxGridIOI),cfg.nGridIOI); 

cfg.interPatternInterval = cfg.nGridPoints * cfg.maxGridIOI; 

%================================================================
% The gridIOI changes are controlled by the Boolean variables below. 
% change gridIOI for each segment
cfg.changeGridIOISegm       = 0;           
% change gridIOI for each segment-type (every time A changes to B or the other way around)
cfg.changeGridIOICategory   = 0;    
% change gridIOI for each step
cfg.changeGridIOIStep       = 0;     


%% construct segment

% % how many times the pattern will be repeated/cycle through
% % % % it's inserted in makeStimMainExp.m as cfg.nCyclesPerPattern
% % % %
% cfg.nCyclesPerPattern = 1;

% how many pattern cycles are within each step of [ABBB]
% how many pattern in each segment A or B.
cfg.nPatternPerSegment = 4;


% there can be a pause after all segments for category A are played 
% (i.e. between A and B)
cfg.delayAfterA = 0; 
% there can be a pause after all segments for category B are played 
% (i.e. between B and A)
cfg.delayAfterB = 0; 

% if the gridIOI can vary across pattern cycles, we need to set the time 
% interval between two successive segments to a fixed value (this must be 
% greater or equal to the maximum possible segment duration)
cfg.interSegmInterval = cfg.nPatternPerSegment * cfg.interPatternInterval; 

%durSeg = cfg.interSegmInterval;

%% construct step [ABBB]
% how many successive segments are presented for category A
% manw many times segment A will be sequentially repeated
cfg.nSegmentA = 1; 

% how many successive segments are presented for category B
% manw many times segment B will be sequentially repeated
cfg.nSegmentB = 3; 

% number of segments for each step
cfg.nSegmPerStep = cfg.nSegmentB + cfg.nSegmentA; %4; 

%calculation duration (s) of a step 
cfg.interStepInterval = (cfg.interSegmInterval * cfg.nSegmPerStep) + ...
                        (cfg.delayAfterA * cfg.nSegmentA) + ... 
                        (cfg.delayAfterB * cfg.nSegmentB);

%% construct whole sequence
% how many steps are in the whole sequence
% how many repetition of grouped segment [ABBB] in the whole sequence
cfg.nStepsPerSequence = 5;


% calculate trial duration (min)
cfg.SequenceDur = (cfg.interStepInterval * cfg.nStepsPerSequence); 
fprintf('\n\nsequence duration is: %.1f minutes\n',cfg.SequenceDur/60);



%% construct pitch features of the stimulus 
% the pitch (F0) of the tones making up the patterns can vary 
% (it can be selected randomly from a set of possible values)
cfg.minF0 	= 350; % minimum possible F0
cfg.maxF0 	= 900; % maximum possible F0
cfg.nF0 	= 5; % number of unique F0-values between the limits
cfg.F0s 	= logspace(log10(cfg.minF0),log10(cfg.maxF0),cfg.nF0); 

%================================================================
% The pitch changes are controlled by the Boolean variables below. 
% NOTE: the parameters work together hierarchically, i.e. if you set
% cfg.changePitchCycle = TRUE, then it's obvious that pitch will be changed
% also every segment and step...

% change pitch for each new pattern cycle
cfg.changePitchCycle 	= 1;
% change pitch for each segment
cfg.changePitchSegm 	= 0;           
% change pitch for each segment-category (every time A changes to B or the other way around)
cfg.changePitchCategory = 0;    
% change pitch for each step
cfg.changePitchStep 	= 0;     


%% create two sets of patterns

% read from txt files
grahnPatSimple = loadIOIRatiosFromTxt(fullfile('stimuli','Grahn2007_simple.txt')); 
grahnPatComplex = loadIOIRatiosFromTxt(fullfile('stimuli','Grahn2007_complex.txt')); 

% get different metrics of the patterns
cfg.patternSimple = getPatternInfo(grahnPatSimple, 'simple',cfg); 
cfg.patternComplex = getPatternInfo(grahnPatComplex, 'complex', cfg); 


%% generate sequence

% get pattern IDs for all sequences used in the experiment
% this is to make sure each pattern is used equal number of times in the
% whole experiment

cfg.labelCategA = 'simple'; 
cfg.labelCategB = 'complex'; 
% ! important, the order of arguments matters ! -> getAllSeq(categA, categB, ...)
cfg.seqDesignFullExp = getAllSeqDesign(cfg.patternSimple, cfg.patternComplex, cfg, expParam); 


%% extract below numbers for preallocation in logFile


%% generate example audio for volume setting
cfg.volumeSettingSound = repmat(makeStimMainExp(ones(1,16), cfg, cfg.gridIOIs(end), cfg.F0s(end)), 2,1); 



%% Task Instructions

instrFid = fopen(fullfile('lib','instr','instrMainExpIntro1'),'r'); 
expParam.taskInstruction = []; 
while ~feof(instrFid)
    expParam.taskInstruction = [expParam.taskInstruction, fgets(instrFid)]; 
end
fclose(instrFid); 


expParam.trialDurInstruction = [sprintf('Trial duration will be: %.1f minutes\n\n',cfg.SequenceDur/60), ...
                            'Set your volume now. \n\n\nThen start the experiment whenever ready...\n\n']; 
                           


expParam.delayInstruction = ['The %d out of %d is over!\n\n', ...
                            'You can have a break. \n\n',...
                            'Good luck!\n\n']; 


    
end



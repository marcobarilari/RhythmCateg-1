function [cfg,expParameters] = getParams(task)
% Initialize the parameters variables
% Initialize the general configuration variables
% =======
% INPUT: 
% =======
%     task:             string specifying the current task to get parameters for
%                       (tapTraining or tapMainExp)
% =======
% OUTPUT: 
% =======
%     cfg:
%     expParameters:



% parameters
cfg = struct; 

% general configuration
expParameters = struct;

expParameters.task = task; 


%% Debug mode settings
cfg.debug               = 0 ;  % To test the script
cfg.testingTranspScreen = 0 ;  % To test with trasparent full size screen 


%% set the type of your computer
if IsWin
    cfg.device='windows';
elseif ismac
    cfg.device = 'mac';
elseif IsLinux
    cfg.device = 'linux';
end

%% other parameters
% sampling rate
cfg.fs = 44100; 


%% more parameters to get according to thetype of experiment
if strcmp(expParameters.task,'tapTraining')
    % get tapping training parameters
    [cfg,expParameters] = getTrainingParameters(cfg,expParameters);

    
elseif strcmp(expParameters.task,'tapMainExp')
    % get main experiment parameters
    [cfg,expParameters] = getMainExpParameters(cfg,expParameters);
    
end


%% differentiating response button (subject) from keyboard(experimenter)
% cfg.responseBox would be the device used by the participant to give his/her response: 
%   like the button box in the scanner or a separate keyboard for a behavioral experiment
%
% cfg.keyboard is the keyboard on which the experimenter will type or press the keys necessary 
%   to start or abort the experiment.
%   The two can be different or the same.

% Using empty vectors should work for linux when to select the "main"
%   keyboard. You might have to try some other values for MacOS or Windows
% TL: I think -1 should work? 
cfg.keyboard = []; 
cfg.responseBox = []; 


if cfg.debug
    fprintf('\n\n\n\n')
    fprintf('######################################## \n')
    fprintf('##  DEBUG MODE, NOT THE ACTUAL EXP CODE  ## \n')
    fprintf('######################################## \n\n')
end

%% create a function for linux/octave
% 
% status = system(command)


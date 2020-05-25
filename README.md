# This repository contains Matlab code for tapping pilot, including:  

1. Tap Trainer  
2. Main Experiment  

## Requirements:

Make sure that the following softwares are installed and added to the matlab / octave path.

For instructions see the following links:

| Requirements                                             | Used version |
|----------------------------------------------------------|--------------|
| [PsychToolBox](http://psychtoolbox.org/)                 | >=3.0.14     |
| [Matlab](https://www.mathworks.com/products/matlab.html) | >=2017       |
| or [octave](https://www.gnu.org/software/octave/)        | 5.1          |

## To run:  

1. Download the whole repository as zip.
2. Unzip and navigate to the downloaded folder.  
3. Run tapTrainer.m in Matlab to launch the Tap Trainer psychtoolbox session.
4. Run tapMainExperiment.m in Matlab to launch the Main Experiment psychtoolbox session.  

### Tap Trainer session

Two sound layers are presented simultaneously (cycled seamlessly):  
* *Rhythmic pattern* is played with a tone, and doesn't change intensity over the experiment  
* *Meter cue* consists of two pulses, each played with a distinctive timbre. One marks the beat period, the other marks the fastest metric period ("grid").

The task is to tap on SPACEBAR along with the beat pulse. Good tapping performance will result in gradual decrease meter-cue volume. Eventually, the meter-cue will be completely silent and the participant is required to keep synchronized to the beat.

The session goes over multiple rhythmic patterns with increasing difficulty (also different beat periods can be used in the future releases).  

All important parameters can be found in `/lib/getTrainingParameters.m`. The file should be sufficiently commented to make sense.

### Main Experiment session

Long, non-repeating rhythmic sequences are presented. The task is to (1) find a plausible pulse, and (2) synchronize finger tapping to it.  

All important parameters  can be found in `/lib/getMainExpParameters.m`. The file should be sufficiently commented to make sense.  

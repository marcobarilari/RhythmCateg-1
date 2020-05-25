function res = getAllSeqDesign(categA,categB,cfg,expParam)

% this function designs the sequences for the whole experiment in a way
% that the number of times each pattern is included is counterbalanced and
% randomized as much as possible

% of course, the possibility of full counterbalancing depends on the number
% of sequences, steps, segments, and patterns requested in the experiment


% create a separate "reservoir" with available patterns for each segment 
% (e.g. A, B, B, B)
[patterns2chooseA{1:cfg.nSegmentA}] = deal(categA); 
[patterns2chooseB{1:cfg.nSegmentB}] = deal(categB); 

patterns2choose = [patterns2chooseA, patterns2chooseB]; 


% allocate result with dimension: sequence x step x segm x pattern
res = cell(expParam.numSequences, cfg.nStepsPerSequence, cfg.nSegmPerStep, cfg.nPatternPerSegment); 

for seqi=1:expParam.numSequences

    for stepi=1:cfg.nStepsPerSequence 

        for segmi=1:cfg.nSegmPerStep
            
            for pati=1:cfg.nPatternPerSegment

                % check if there are any patterns left in the reservoir for
                % this segment 
                % if no, refill it with the whole pattern set for that category
                if isempty(patterns2choose{segmi})
                    % Determine which segment category this is (A or B)
                    % (the first 'cfg.nSegmentA' segments will be category A, 
                    % the rest will be category B)
                    if ismember(segmi, [1:cfg.nSegmentA])            
                        patterns2choose{segmi} = categA; 
                    else
                        patterns2choose{segmi} = categB; 
                    end
                end
                
                % pick a pattern from the current category
                chosenPatIdx = randsample(length(patterns2choose{segmi}),1); 
                
                % get its ID tag
                chosenPatID = patterns2choose{segmi}(chosenPatIdx).ID; 
                
                % write pattern ID to the result
                % dims: [seq x step x segm x pat]
                res{seqi,stepi,segmi,pati} = chosenPatID; 

                % remove the picked pattern from the available pool
                patterns2choose{segmi}(chosenPatIdx) = []; 
                
            end
        end
    end
end

if all(cellfun(@isempty, patterns2choose))
    disp('hooray, the experiment is fully counterbalanced ;)')
else
    disp('ouch, the experiment is NOT fully counterbalanced :(')
end





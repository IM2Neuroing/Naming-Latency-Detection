%% *Main Script*
%% load audiofilespaths and metadata
datastore = audioDatastore("SampleData/audio/");
save('datastore_sampledata.mat', 'datastore');
thresh_and_vad_paths = datastore.Files;
df_sampledata = readtable("SampleData/metaData.csv");
disp(df_sampledata);

% Define the column name for storing the results of the 'thresholdlatencynew' function
autoLatency = 'autoLatency';

% read in parameters for different initalphonemes
parSet = readtable('parameters_paper.csv');
% Get the unique initial phonemes and its row indices
initialPhonemes = parSet.initialPhonemes;
rowIndices = (1:size(parSet, 1))';
% Create a dictionary using containers.Map
dictpaper = containers.Map(initialPhonemes, rowIndices);
disp(parSet);

%% Iter over all samples
% Iterate over each row of the 'df_sampledata' DataFrame 
% extract the required parameters for the 'thresholdlatencynew' function
% get latency result in ms from the 'thresholdlatencynew' function
for rowIdx = 1:size(df_sampledata, 1)
    % Get the audio file path for the current row
    filenameToMatch = df_sampledata.filenames(rowIdx);
    foundIdx_datastore = find(contains(thresh_and_vad_paths, ...
                                   filenameToMatch), ...
                           1);

    % Load audio recording
    [audio, fs] = audioread(thresh_and_vad_paths{foundIdx_datastore});
    audio = mean(audio, 2);

    % Create a new recording
    rec = audioRecs;
    rec.wave = audio;
    rec.fs = fs;
    rec.estimatedRT = df_sampledata.gmmKaldiTime(rowIdx);

    % Remove the matched path from thresh_and_vad_paths
    thresh_and_vad_paths(foundIdx_datastore) = [];

    % extract the required parameters for this samples initialphoneme
    % get the index of row of parameter dataframe paper and new
    rowIdxPara = dictpaper(df_sampledata.initPhonemWritten{rowIdx});
    
    % get the required parameters for the phoneme 
    thresholdSlope = parSet.thresholdSlope_1(rowIdxPara);
    timeFullGap = parSet.timeFullGap_2(rowIdxPara);
    timeSlopeGapAfterBeginning = parSet.timeSlopeGapAfterBeginning_3(rowIdxPara);
    timeAfterBeginning = parSet.timeAfterBeginning_4(rowIdxPara);
    minWordLength = parSet.minWordLength_5(rowIdxPara);
    overallMedianFactor = parSet.overallMedianFactor_6(rowIdxPara);

    % Run the 'thresholdlatencynew' function
    % result with paper optimized parameters
    result = thresholdlatencynew(rec.wave, ...
                                 rec.fs, ...
                                 rec.estimatedRT, ...
                                 thresholdSlope, ...
                                 timeFullGap, ...
                                 timeSlopeGapAfterBeginning, ...
                                 timeAfterBeginning, ...
                                 minWordLength, ...
                                 overallMedianFactor);


    % Store the result in the DataFrame
    df_sampledata.(autoLatency)(rowIdx) = result;

end

% Calculate the difference between manual and auto
Difference_paper = 'autoLatency(paper)';
df_sampledata.Difference_paper = df_sampledata.(autoLatency) - df_sampledata.manualLatency;

% Calculate the mean and standard deviation of the 'Difference' columns 
meanDifference = mean(df_sampledata.Difference_paper);
stdDifference = std(df_sampledata.Difference_paper);

%% Final Results
% Display the df_sampledata
disp(df_sampledata);

disp(['Mean of Difference (paper): ', num2str(meanDifference)]);
disp(['Standard Deviation of Difference (paper): ', num2str(stdDifference)]);

% Write the 'df_sampledata' table to a CSV file named 'results.csv'
writetable(df_sampledata, 'results.csv');

%% *Supporting Functions* 

% FUNCTION: thresholdlatencynew
% DESCRIPTION: This function calculates the latency (in milliseconds) of a spoken word
%              in an audio stream based on thresholding and slope analysis.
% INPUTS:
%   audio: The input audio stream.
%   fs: The sample rate of the audio.
%   kaldiGmmTime: The time (in milliseconds) at which the word was detected by the Kaldi GMM model.
%   thresholdSlope: Threshold used for slope analysis.
%   timeFullGap: Maximum allowed duration of silence after the word (in seconds).
%   timeSlopeGapAfterBeginning: Maximum allowed duration of silence after the word's slope exceeds the threshold (in seconds).
%   timeAfterBeginning: Duration of time after the word's beginning that is analyzed for slope (in seconds).
%   minWordLength: Minimum duration of the detected word (in seconds).
%   overallMedianFactor: A scaling factor used to calculate the overall median of the audio envelope.
function latencyMs = thresholdlatencynew(audio, ...
                                         fs, ...
                                         kaldiGmmTime, ...
                                         thresholdSlope, ...
                                         timeFullGap, ...
                                         timeSlopeGapAfterBeginning, ...
                                         timeAfterBeginning, ...
                                         minWordLength, ...
                                         overallMedianFactor)

    % Generate the upper envelope of the audio stream
    [audioEnv,~] = envelope(audio);
    
    % Filtering the audio envelope using wavelet denoising
    audioEnv = wdenoise(audioEnv, ...
                        10, ...
                        'Wavelet', ...
                        'coif5', ...
                        'DenoisingMethod', ...
                        'UniversalThreshold', ...
                        'ThresholdRule', ...
                        'Soft', ...
                        'NoiseEstimate', ...
                        'LevelDependent');
    
    % Calculate the moving maximum of the denoised audio envelope
    movmaxAudio = movmax(audioEnv, 5);
    maxVol2 = max(movmaxAudio);
    movmadSmoothedAudio = movmaxAudio - min(movmaxAudio);
    movmaxAudioNorm = movmaxAudio .* (1 / maxVol2);
    
    % Calculate a smoothed version of the audio envelope
    smoothedMax = movmean(audioEnv, 1000);
    smoothedMax = (smoothedMax - min(smoothedMax)) .* (1 / max(smoothedMax));
    overallMedian = median(smoothedMax) * overallMedianFactor;
    
    % Calculate the moving slope of the audio envelope
    movSlopeWindow = 5;
    movSlope1 = movmaxAudioNorm;
    movSlope = movSlope1;
    for movId = 1:length(smoothedMax)-1
        if ((movId - movSlopeWindow) >= 1 && ...
                (movId + movSlopeWindow) <= length(movSlope1))
            
            movSlope(movId) = ...
                (movSlope1(movId + movSlopeWindow) - movSlope1(movId - movSlopeWindow))...
                / (movSlopeWindow * 2);
        else
            movSlope(movId) = 0;
        end
    end
    movSlope = (movSlope - min(movSlope)) .* (1 / max(movSlope));
    movSlope = movSlope + min(movSlope);
    movSlope = movSlope - mean(movSlope);
    movSlope = movSlope * 2;
    movSlope = abs(movSlope);
    
    % Initialization for latency calculation
    audioToDetLat = movmaxAudioNorm;
    audioToDetWordBreak = movSlope;
    latency = 0.0;
    
    % Set threshold for detecting word boundaries
    threshold = overallMedian;
    
    % Define a time window around the detected time by Kaldi
    timeBeforeKaldiDetectedTime = 0.10; % 100 ms before Kaldi's detected time
    timeAfterKaldiDetectedTime = 1.0;   % 1 second after Kaldi's detected time
    
    % Set start and endpoint for analyzing the audio envelope
    startingPoint = round((kaldiGmmTime / 1000 * fs) - (fs * timeBeforeKaldiDetectedTime));
    endpoint = round((kaldiGmmTime / 1000 * fs) + (fs * timeAfterKaldiDetectedTime));
    if endpoint > length(audioToDetLat)
        endpoint = length(audioToDetLat);
    end

    % Start thresholding algorithm to detect latency
    foundLatency = false;
    while foundLatency == false && startingPoint <= endpoint

        startingPoint2 = startingPoint;

        % Check if the current point exceeds the threshold
        if audioToDetLat(startingPoint2) > threshold

            currentPoint = startingPoint2;
            wordIsOverFullGap = 0;
            slopeGap = 0;
            nrOverSlopeThresh = 0;

            % Analyze the slope and silence duration after the word
            while (wordIsOverFullGap < timeFullGap) && (slopeGap < timeSlopeGapAfterBeginning) && (currentPoint < length(audioToDetLat))
                
                % Check if the slope exceeds the threshold and if it's within the time limit
                if ((currentPoint - startingPoint2) > timeAfterBeginning) && (audioToDetWordBreak(currentPoint) > thresholdSlope) && ((currentPoint - startingPoint2) < (timeSlopeGapAfterBeginning + timeAfterBeginning))
                    slopeGap = 0;
                else
                    slopeGap = slopeGap + 1;
                end

                % Check if the envelope exceeds certain thresholds to detect word breaks
                if audioToDetLat(currentPoint) > threshold * 1.5 || (audioToDetWordBreak(currentPoint) > thresholdSlope && audioToDetLat(currentPoint) > threshold)
                    wordIsOverFullGap = 0;
                else
                    wordIsOverFullGap = wordIsOverFullGap + 1;
                end

                currentPoint = currentPoint + 1;
            end

            % Check if the detected word is longer than the minimum word length
            if currentPoint - startingPoint2 > minWordLength
                latency = (double(startingPoint2) / fs);
                foundLatency = true;
            end
            startingPoint2 = currentPoint;
        end
        startingPoint = startingPoint + 1;
    end
    
    % Convert the latency to milliseconds
    latencyMs = latency * 1000;
end
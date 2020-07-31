clear; clc; setup; config; load('data/tap.mat');

% * Generate channels
[directChannel] = frequency_response(directTapGain, directTapDelay, directDistance, nReflectors, subbandFrequency, fadingMode, 'direct');
[incidentChannel] = frequency_response(incidentTapGain, incidentTapDelay, incidentDistance, nReflectors, subbandFrequency, fadingMode, 'incident');
[reflectiveChannel] = frequency_response(reflectiveTapGain, reflectiveTapDelay, reflectiveDistance, nReflectors, subbandFrequency, fadingMode, 'reflective');

% * Set rate constraints
% [capacity, irs, infoWaveform, powerWaveform, infoRatio, powerRatio] = wit(directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, tolerance);
[capacity] = wit(directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, tolerance);
rateConstraint = linspace(0, (1 - tolerance) * capacity, nSamples);
% rateConstraint = linspace((1 - tolerance) * capacity, 0, nSamples);
% [compositeChannel] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);
% [infoWaveform, powerWaveform, infoRatio, powerRatio, rate, current] = waveform_gp(beta2, beta4, compositeChannel, infoWaveform, powerWaveform, infoRatio, powerRatio, txPower, noisePower, capacity * 0.99, tolerance);

% * Initialize algorithm
[maxCurrent, irs, infoWaveform, powerWaveform, infoRatio, powerRatio] = wpt(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, tolerance);
% [maxCurrent] = wpt(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, tolerance);
[compositeChannel] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);
% [infoWaveform, powerWaveform, infoRatio, powerRatio, rate, current] = waveform_gp(beta2, beta4, compositeChannel, infoWaveform, powerWaveform, infoRatio, powerRatio, txPower, noisePower, 0, tolerance);

% * Use previous solution to initialize each sample
solution = cell(nSamples, 1);
sample = zeros(2, nSamples);
for iSample = 1 : nSamples
    isConverged = false;
    current_ = 0;
    [infoWaveform, powerWaveform, infoRatio, powerRatio] = initialize_waveform(compositeChannel, txPower);
    [infoWaveform, powerWaveform, infoRatio, powerRatio, rate, current] = waveform_gp(beta2, beta4, compositeChannel, infoWaveform, powerWaveform, infoRatio, powerRatio, txPower, noisePower, rateConstraint(iSample), tolerance);
    while ~isConverged
        [irs] = irs_sdr(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, irs, infoWaveform, powerWaveform, infoRatio, powerRatio, noisePower, rateConstraint(iSample), nCandidates, tolerance);
        [compositeChannel] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);
        [infoWaveform, powerWaveform, infoRatio, powerRatio, rate, current] = waveform_gp(beta2, beta4, compositeChannel, infoWaveform, powerWaveform, infoRatio, powerRatio, txPower, noisePower, rateConstraint(iSample), tolerance);
%         [rate, current] = re_sample(beta2, beta4, compositeChannel, infoWaveform, powerWaveform, infoRatio, powerRatio, noisePower);
        isConverged = abs(current - current_) / current <= tolerance;
        current_ = current;
    end
    solution{iSample}.powerRatio = powerRatio;
    solution{iSample}.infoWaveform = infoWaveform;
    solution{iSample}.powerWaveform = powerWaveform;
    sample(:, iSample) = [rate; current];
end

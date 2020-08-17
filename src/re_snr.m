clear; clc; setup; config_snr;

%% ! R-E region for different large-scale SNR
reSample = cell(nChannels, nCases);
reSolution = cell(nChannels, nCases);

parfor iChannel = 1 : nChannels
    % * Generate tap gains and delays
    [directTapGain, directTapDelay] = tap_tgn(corTx, corRx, 'nlos');
    [incidentTapGain, incidentTapDelay] = tap_tgn(corTx, corIrs, 'nlos');
    [reflectiveTapGain, reflectiveTapDelay] = tap_tgn(corIrs, corRx, 'nlos');

    % * Construct channels
    [directChannel] = frequency_response(directTapGain, directTapDelay, directDistance, rxGain, subbandFrequency, fadingMode);
    [incidentChannel] = frequency_response(incidentTapGain, incidentTapDelay, incidentDistance, rxGain, subbandFrequency, fadingMode);
    [reflectiveChannel] = frequency_response(reflectiveTapGain, reflectiveTapDelay, reflectiveDistance, rxGain, subbandFrequency, fadingMode);

    % * Calculate sum pathloss
    [sumPathloss] = sum_pathloss(directDistance, incidentDistance, reflectiveDistance);

    for iSnr = 1 : nCases
        % * Calculate noise power based on SNR
        noisePower = txPower * sumPathloss * rxGain / Variable.snr(iSnr);

        % * Alternating optimization
        [reSample{iChannel, iSnr}, reSolution{iChannel, iSnr}] = re_sample(beta2, beta4, directChannel, incidentChannel, reflectiveChannel, txPower, noisePower, nCandidates, nSamples, tolerance);
    end
end

% * Average over channel realizations
reSampleAvg = cell(1, nCases);
for iSnr = 1 : nCases
    reSampleAvg{iSnr} = mean(cat(3, reSample{:, iSnr}), 3);
end
save('data/re_snr.mat');

% %% * R-E plots
% figure('name', 'R-E region vs large-scale SNR');
% legendString = cell(1, nCases);
% for iSnr = 1 : nCases
%     plot(reSampleAvg{iSnr}(1, :) / nSubbands, 1e6 * reSampleAvg{iSnr}(2, :));
%     legendString{iSnr} = sprintf('SNR = %d dB', pow2db(Variable.snr(iSnr)));
%     hold on;
% end
% hold off;
% grid minor;
% legend(legendString);
% xlabel('Per-subband rate [bps/Hz]');
% ylabel('Average output DC current [\muA]');
% ylim([0 inf]);
% savefig('plots/re_snr.fig');
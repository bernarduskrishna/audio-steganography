close all;
clear all;
format long;

% Reading msg to readMsg
fname = 'message_to_be_encoded.txt';
fid = fopen(fname, 'r');
readMsg = fgetl(fid);
fclose(fid);

% Reading audio data
[data, fs] = audioread('source_music.wav');

% Converting readMsg to ascii
ascii_msg = double(readMsg);
% Addition of "start" and "stop" signal (ascii 128)
ascii_msg = [128 ascii_msg 128];

% Apply lowpass filter
lowpassed = lowpass(data, 6000, fs);

% Array length is 1272651
% Divide roughly evenly among 500 characters with a pause in between
% Put each char as a frequency in each contiguous 1200 elements

% Freq range to put message: 10k - 20k
% Range = 10k
% Ascii range = (ONLY 32 TO 127 (128 with start/stop signal)) = 97
% Use the following mapping
%{
ascii    freq
  32     10000
  33     10100
  ...    ...
  127    19500
  128    19600
%}

% Convert to freq
freq_message = arrayfun(@(x) ascii_to_freq(x), ascii_msg);

% Insert into lowpassed array
for i = 1 : length(freq_message)
    wave = freq_to_wave(freq_message(i));
    lowpassed((i - 1) * 1200 * 2 + 1 : (i - 1) * 1200 * 2 + 1200) = ...
        lowpassed((i - 1) * 1200 * 2 + 1 : (i - 1) * 1200 * 2 + 1200) ...
            + wave;
end

audiowrite('A0196717N_BernardusKrishna_musicWithMessage.wav', lowpassed, fs);

function res = freq_to_wave(f)
    fs = 44100;
    t = 0 : 1 / fs : 1200 / fs; % Actual time
    T = 1 / f; % Actual period
    T_d = T / (1 / fs); % Discrete period
    n_waves = 1200 / fs / T;
    wave = 0.005 * (sin(2 * pi * f * t));
    counter = 0;
    threshold = T;
    for i = 1 : length(t)
        if t(i) > threshold
            counter = counter + 1;
            threshold = threshold + T;
        end
        if counter < n_waves / 2
            wave(i) = counter / (n_waves / 2) * wave(i);
        else
            wave(i) = (n_waves - counter) / (n_waves / 2) * wave(i);
        end
    end
    res = wave(1 : length(t) - 1);
end

function res = ascii_to_freq(c)
    swapped_1 = [32, 44, 46];
    swapped_2 = [62, 60, 59];
    if ismember(c, swapped_1)
        i = find(swapped_1 == c);
        c = swapped_2(i);
    elseif ismember(c, swapped_2)
        i = find(swapped_2 == c);
        c = swapped_1(i);
    end
    res = 10000 + (c - 32) * 100;
end
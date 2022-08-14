clear all;

fs = 44100;
nBits = 16;
NumChannels = 1;
recorder = audiorecorder(fs,nBits,NumChannels);
disp('start recording');
recordblocking(recorder, 30);
disp('end recording');
y = getaudiodata(recorder);

y = highpass(y, 11000, fs);

% Finding the start signal
counter = 0;
amps = [];
i = 1;

while counter < 35
    extracted_data = y(i : i + 512);
    fft_extracted_data = fft(extracted_data, 2^nextpow2(length(extracted_data)));
    freq_resolution = fs / (2^nextpow2(length(extracted_data)));
    [M, I] = max(abs(fft_extracted_data(230 : 470)));
    n = freq_to_ascii((I + 230 - 2) * freq_resolution);
    if n == 128 && M > 0.003
        counter = counter + 1;
    else
        counter = 0;
    end
    i = i + 1;
end

y = y(i + 1500 + 1200:end);

% Actual decoding
ori_text = "";

prev_fft = [];

for i = 1:500
    % Just take the middle 1025 data (to account for error when finding the
    % start)
    extracted_data = y((i - 1) * 1200 * 2 + 1 + 87: (i - 1) * 1200 * 2 + 1200 - 88);
    fft_extracted_data = fft(extracted_data, 2^nextpow2(length(extracted_data)));
    freq_resolution = fs / (2^nextpow2(length(extracted_data)));
    lower_bound = round(10000 / freq_resolution);
    abs_fft_extracted_data = abs(fft_extracted_data);
    abs_fft_extracted_data = abs_fft_extracted_data(lower_bound - 2 : 2 * lower_bound);

    [M, I] = max(abs_fft_extracted_data);

    if ~isempty(prev_fft)
        while abs_fft_extracted_data(I) < 0.8 * prev_fft(I)
            abs_fft_extracted_data(I - 1) = abs_fft_extracted_data(I - 1) / 2;
            abs_fft_extracted_data(I) = abs_fft_extracted_data(I) / 2;
            abs_fft_extracted_data(I + 1) = abs_fft_extracted_data(I + 1) / 2;
            [M, I] = max(abs_fft_extracted_data);
        end
    end
    
    actual_index = I + lower_bound - 4;
    actual_freq = actual_index * freq_resolution;
    ascii_no = freq_to_ascii(actual_freq);
    if ascii_no > 127
        break;
    end
    ascii_char = char(ascii_no);
    ori_text = append(ori_text, ascii_char);
    prev_fft = abs_fft_extracted_data;
end

ori_text

fname = 'message_to_be_encoded.txt';
fid = fopen(fname, 'r');
readMsg = fgetl(fid);
fclose(fid);
ori_text = convertStringsToChars(ori_text);
correct = 0;
wrong = 0;
for i = 1 : strlength(readMsg)
    if readMsg(i) == ori_text(i)
        correct = correct + 1;
    else
        wrong = wrong + 1;
    end
end

disp("accuracy:");
disp(correct / (correct + wrong) * 100);

fname = 'A0196717N_BernardusKrishna_decodedMessage.txt';
fid = fopen(fname,'w');
msg = ori_text;
fprintf(fid,'%s', msg);
fclose(fid);

function res = freq_to_ascii(freq)
    temp = min([128, max([32, round((freq - 10000) / 100 + 32)])]);
    swapped_1 = [32, 44, 46];
    swapped_2 = [62, 60, 59];
    if ismember(temp, swapped_1)
        i = find(swapped_1 == temp);
        res = swapped_2(i);
    elseif ismember(temp, swapped_2)
        i = find(swapped_2 == temp);
        res = swapped_1(i);
    else
        res = temp;
    end
end
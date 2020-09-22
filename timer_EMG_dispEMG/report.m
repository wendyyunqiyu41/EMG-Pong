figure
load 50HzLP.mat
[h,w]=freqz(Num,1);
plot(w/pi*1000,20*log10(abs(h)))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('Frequency Responce of 30Hz Lowpass Filter')
set(gca,'fontsize', 10.5);

figure
load 100_500HzBP.mat
[h,w]=freqz(Num,1,5000);
plot(w/pi*1000,20*log10(abs(h)))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('Frequency Responce of 100-500Hz Bandpass Filter')
set(gca,'fontsize', 10.5);


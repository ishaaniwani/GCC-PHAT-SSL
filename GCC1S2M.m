% This is a basic program the localizes 1 audio signal with 2 microphones
% using the GCC-PHAT algorithm. 

L = 50; 

N = 4;
rxULA = phased.ULA('Element',phased.OmnidirectionalMicrophoneElement,...
    'NumElements',N);

rxpos1 = [0;0;0];
rxvel1 = [0;0;0];
rxax1 = azelaxes(90,0);

rxpos2 = [L;0;0];
rxvel2 = [0;0;0];
rxax2 = rxax1;

user_x = input('How far to the left or right do you want your signal source to be ( -50 to 50 ) ');
user_y = input('How far away do you want your signal source to be? (-100 to 100)');

srcpos = [user_x;user_y;0];
srcvel = [0;0;0];
srcax = azelaxes(-90,0);
srcULA = phased.OmnidirectionalMicrophoneElement;

fc = 300e3;             % 300 kHz
c = 1500;               % 1500 m/s
dmax = 150;             % 150 m
pri = (2*dmax)/c;
prf = 1/pri;
bw = 100.0e3;           % 100 kHz
fs = 2*bw;
waveform = phased.LinearFMWaveform('SampleRate',fs,'SweepBandwidth',bw,...
    'PRF',prf,'PulseWidth',pri/10);

signal = waveform();

nfft = 128;

radiator = phased.WidebandRadiator('Sensor',srcULA,...
    'PropagationSpeed',c,'SampleRate',fs,...
    'CarrierFrequency',fc,'NumSubbands',nfft);
collector1 = phased.WidebandCollector('Sensor',rxULA,...
    'PropagationSpeed',c,'SampleRate',fs,...
    'CarrierFrequency',fc,'NumSubbands',nfft);
collector2 = phased.WidebandCollector('Sensor',rxULA,...
    'PropagationSpeed',c,'SampleRate',fs,...
    'CarrierFrequency',fc,'NumSubbands',nfft);

channel1 = phased.WidebandFreeSpace('PropagationSpeed',c,...
    'SampleRate',fs,'OperatingFrequency',fc,'NumSubbands',nfft);
channel2 = phased.WidebandFreeSpace('PropagationSpeed',c,...
    'SampleRate',fs,'OperatingFrequency',fc,'NumSubbands',nfft);

[~,ang1t] = rangeangle(rxpos1,srcpos,srcax);
[~,ang2t] = rangeangle(rxpos2,srcpos,srcax);

sigt = radiator(signal,[ang1t ang2t]);

sigp1 = channel1(sigt(:,1),srcpos,rxpos1,srcvel,rxvel1); 
sigp2 = channel2(sigt(:,2),srcpos,rxpos2,srcvel,rxvel2);

[~,ang1r] = rangeangle(srcpos,rxpos1,rxax1);
[~,ang2r] = rangeangle(srcpos,rxpos2,rxax2);

sigr1 = collector1(sigp1,ang1r);
sigr2 = collector2(sigp2,ang2r);

doa1 = phased.GCCEstimator('SensorArray',rxULA,'SampleRate',fs,...
    'PropagationSpeed',c);
doa2 = phased.GCCEstimator('SensorArray',rxULA,'SampleRate',fs,...
    'PropagationSpeed',c);

angest1 = doa1(sigr1);
angest2 = doa2(sigr2);

yest = L/(abs(tand(angest1)) + abs(tand(angest2)));
xest = yest*abs(tand(angest1));
zest = 0;

srcpos_act = [ user_x; user_y; 0 ] 
srcpos_est = [ xest; yest; zest ]

% Load a song
[d,sr] = audioread('Clair.wav');
%Can cut off
d = d(1:end,1);
%Indicates the length of the song in seconds
TotalTime = length(d) ./ sr ;
% Calculate the beat times
b = beat2(d,sr);

%The change in time is found by taking the inverse of the sample rate
dt = 1/sr;
%Length of a beat should be uniform but the avg is taken just in case
secondsInBeat = (b(size(b,2))-b(1))/size(b,2);
%gives a variable to represent the total beats in the song
totalBeats = size(b,2);
%initialize the size of the window (# of signals in beat)
windowSize = round(size(d,1)/totalBeats);

%stores the frequencies of each window initialized as blank for now
frequencyVector = zeros(totalBeats,2);
%converts each frequency in frequencyVector to notes in numbers
notes = zeros(totalBeats,2);
%converts each frequency in frequencyVector to notes in letters
%since there are up to 2 characters such as 'C#', 4 columns are required to
%accomodate the characters
letters = zeros(totalBeats,4);

for i = 1 : windowSize : length(d)-windowSize-1
%stores all the signals of a beat to fourier transform
oneBeat = d(i:i+windowSize);
%fast fourier transform oneBeat to frequency domain (abs so we can find peak)
oneBeatFreq = abs(fft(oneBeat,windowSize));

%finds the largest magnitude value in the entire beat
strongestNote = max(oneBeatFreq);
%finds the second strongest note to use as a threshold and to detect
%accompaniments
secondStrongestNote = max(oneBeatFreq(oneBeatFreq~=max(oneBeatFreq)));
%finds the indices of only the strongest peak(s)
[peaks,index] = findpeaks(oneBeatFreq,'MinPeakHeight',secondStrongestNote-1);
%i/windowSize+1 returns the number of iterations the for loop has gone
%through. The goal is to fill the entire frequencyVector vector with the
%strongest frequency in each beat. There are two columns to fill to allow
%for the implementation of multi melody songs
frequencyVector(round(i/windowSize)+1,1)=(index(1)-1)*sr/windowSize;
frequencyVector(round(i/windowSize)+1,2)=(index(2)-1)*sr/windowSize;
%converts each corresponding frequency to a key on the piano with the end
%goal of generating a 2 column matrix
notes(round(i/windowSize)+1,1) = FrequencyToKeyConvert(frequencyVector(round(i/windowSize)+1,1));
notes(round(i/windowSize)+1,2) = FrequencyToKeyConvert(frequencyVector(round(i/windowSize)+1,2));
%any invalid notes are converted back to 0 to represent silence with an if
%statement for each column
if(notes(round(i/windowSize)+1,1)>88 || notes(round(i/windowSize)+1,1) < 1)
    frequencyVector(round(i/windowSize)+1,1) = 0;
    notes(round(i/windowSize)+1,1) = 0;
end
if(notes(round(i/windowSize)+1,2)>88 || notes(round(i/windowSize)+1,2) < 1)
    frequencyVector(round(i/windowSize)+1,2) = 0;
    notes(round(i/windowSize)+1,2) = 0;
end
%Harsh sounds such as major and minor 2nds are cut out and silenced
if(abs(notes(round(i/windowSize)+1,1)-notes(round(i/windowSize)+1,2))<=2)
    frequencyVector(round(i/windowSize)+1,2) = 0;
    notes(round(i/windowSize)+1,2) = 0;
end
%generates the same array as notes but in letter form
%when printed out, letters will look like an array of numbers so it must be
%cast as a char when called
if notes(round(i/windowSize)+1,1) ~= 0
    chars = NumberToLetterConvert(notes(round(i/windowSize)+1,1));
    letters(round(i/windowSize)+1,1) = chars(1);
    letters(round(i/windowSize)+1,2) = chars(2);
end
if notes(round(i/windowSize)+1,2) ~= 0
    chars = NumberToLetterConvert(notes(round(i/windowSize)+1,2));
    letters(round(i/windowSize)+1,3) = chars(1);
    letters(round(i/windowSize)+1,4) = chars(2);
end
end

%sets up a time range to map the sinusoid
t=[0:dt:secondsInBeat];
%converts all of the frequencies into angular frequency
w = 2*pi*frequencyVector;
%plots the discrete sinusoid
y = cos(w(:,1)*t)+cos(w(:,2)*t); 
%converts the frequency into a sinuoidal function
combined = reshape(y',totalBeats*length(t),1);
%plays the song for analyzation purposes
soundsc(combined,sr);
%outputs a synthesized version of the wav for hand in purposes
audiowrite('ClairSynth.wav',combined,sr);
% ReSpeaker Mic Array v3.0
% Frequency-domain beamformer: geometry, propagation, phase and beampatterns
% Run this script in GNU Octave. All six figures are exported to ./figures/.

clear;
clc;
close all;

% Gnuplot renders correctly on the Ubuntu system used for this project.
graphics_toolkit('gnuplot');

% Distance between adjacent microphones (metres)
d = 0.0457;
a = d / 2;

% Microphone coordinates [x, y]; geometrical labels, not audio-channel IDs
mic_pos = [
     a,  a;
    -a,  a;
    -a, -a;
     a, -a
];

disp('Microphone coordinates (metres):');
disp(mic_pos);

%% Figure 1: Microphone positions
figure(1);
clf;
plot(mic_pos(:,1), mic_pos(:,2), 'ro', 'MarkerSize', 10);
grid on;
axis square;
axis([-0.035 0.035 -0.035 0.035]);
xlabel('X position (m)');
ylabel('Y position (m)');
title('ReSpeaker Mic Array v3.0');

%% Propagation delays
c = 343;  % Speed of sound (m/s)

% Arrival times for sound coming from +X (0 degrees)
tau_0 = -mic_pos(:,1) / c;
disp('Microphone arrival times for 0 degrees (microseconds):');
disp(tau_0 * 1e6);

% Arrival times for sound coming from 45 degrees
theta = 45;
u = [cosd(theta); sind(theta)];
tau = -(mic_pos * u) / c;
disp('Arrival times for 45 degrees (microseconds):');
disp(tau * 1e6);

%% Figure 2: Arrival times for all directions
angles_coarse = 0:5:360;
directions_coarse = [cosd(angles_coarse); sind(angles_coarse)];
tau_all = -(mic_pos * directions_coarse) / c;
tau_all_us = tau_all * 1e6;

figure(2);
clf;
plot(angles_coarse, tau_all_us', 'LineWidth', 2);
grid on;
axis normal;
axis([0 360 -105 105]);
set(gca, 'xtick', 0:45:360);
xlabel('Sound arrival direction (degrees)');
ylabel('Relative arrival time (microseconds)');
title('Sound Arrival Times vs Direction');
legend('MIC1', 'MIC2', 'MIC3', 'MIC4', 'location', 'northeastoutside');

%% Phase shifts for sound from 45 degrees
f = 2000;
phase_deg = -360 * f * tau;
disp('Phase shifts at 2000 Hz (degrees):');
disp(phase_deg);

%% Figure 3: Phase versus frequency
frequencies = 0:100:4000;
phase_all = -360 * (tau * frequencies);

figure(3);
clf;
plot(frequencies, phase_all', 'LineWidth', 2);
grid on;
axis normal;
xlim([0 4000]);
xlabel('Frequency (Hz)');
ylabel('Phase shift (degrees)');
title('Microphone Phase Shifts vs Frequency');
legend('MIC1', 'MIC2', 'MIC3', 'MIC4', 'location', 'northeastoutside');

%% Calculate theoretical frequency-domain responses at 2000 Hz
angles = 0:1:360;
directions = [cosd(angles); sind(angles)];
tau_sources = -(mic_pos * directions) / c;
X = exp(-1i * 2 * pi * f * tau_sources);
steer_angles = [0 90];

%% Figure 4: Beamformer directional response in dB
figure(4);
clf;
hold on;

for theta0 = steer_angles
    u0 = [cosd(theta0); sind(theta0)];
    tau0 = -(mic_pos * u0) / c;
    weights = exp(1i * 2 * pi * f * tau0) / 4;
    Y = weights.' * X;
    gain_db = 20 * log10(max(abs(Y), 1e-4));
    plot(angles, gain_db, 'LineWidth', 2);
endfor

hold off;
grid on;
xlim([0 360]);
ylim([-60 1]);
set(gca, 'xtick', 0:45:360);
xlabel('Sound source direction (degrees)');
ylabel('Beamformer gain (dB)');
title('Beamformer Directional Response at 2000 Hz');
legend('Steered to 0 degrees', 'Steered to 90 degrees', ...
       'location', 'northeastoutside');

%% Figure 5: Polar beamformer response at 2000 Hz
figure(5);
clf;
angles_rad = angles * pi / 180;

for theta0 = steer_angles
    u0 = [cosd(theta0); sind(theta0)];
    tau0 = -(mic_pos * u0) / c;
    weights = exp(1i * 2 * pi * f * tau0) / 4;
    Y = weights.' * X;
    gain = abs(Y);
    polar(angles_rad, gain);
    hold on;
endfor

hold off;
title('Beamformer Polar Response at 2000 Hz');
legend('Steered to 0 degrees', 'Steered to 90 degrees', ...
       'location', 'northeastoutside');

%% Figure 6: Beamformer directional response versus frequency
% The beamformer is steered toward 0 degrees.
test_freqs = [500 1000 2000 4000];
theta0 = 0;
u0 = [cosd(theta0); sind(theta0)];
tau0 = -(mic_pos * u0) / c;

figure(6);
clf;
hold on;

for ftest = test_freqs
    Xtest = exp(-1i * 2 * pi * ftest * tau_sources);
    weights = exp(1i * 2 * pi * ftest * tau0) / 4;
    Ytest = weights.' * Xtest;
    gain_db = 20 * log10(max(abs(Ytest), 1e-4));
    plot(angles, gain_db, 'LineWidth', 2);
endfor

hold off;
grid on;
axis([0 360 -60 1]);
set(gca, 'xtick', 0:45:360);
xlabel('Sound source direction (degrees)');
ylabel('Beamformer gain (dB)');
title('Beamformer Directional Response vs Frequency');
legend('500 Hz', '1000 Hz', '2000 Hz', '4000 Hz', ...
       'location', 'northeastoutside');

%% Export ALL figures as publication-quality PNG images (300 DPI)
% Save next to this .m file, regardless of Octave's current directory.
script_path = mfilename('fullpath');
if isempty(script_path)
    base_dir = pwd;
else
    base_dir = fileparts(script_path);
endif
output_dir = fullfile(base_dir, 'figures');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
endif

figure_names = {
    '01_microphone_geometry';
    '02_arrival_times_vs_direction';
    '03_phase_shifts_vs_frequency';
    '04_beamformer_directional_response_2kHz';
    '05_beamformer_polar_response_2kHz';
    '06_beamformer_response_vs_frequency'
};

for fig_idx = 1:numel(figure_names)
    h = figure(fig_idx);
    set(h, 'color', [1 1 1]);
    set(h, 'position', [100 100 1100 780]);
    set(h, 'paperpositionmode', 'auto');
    drawnow();

    filename = fullfile(output_dir, [figure_names{fig_idx} '.png']);
    print(h, filename, '-dpng', '-r300');
    fprintf('Exported: %s\n', filename);
endfor

fprintf('\nExported all six figures to: %s\n', output_dir);

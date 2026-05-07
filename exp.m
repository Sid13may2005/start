% Example 1: Alternative Analysis without Control System Toolbox
% Forward path G(s) = 1 / (s^2 + s + 4)
% Closed-loop T(s) = G(s) / (1 + G(s)) = 1 / (s^2 + s + 5)

% --- System Parameters ---
% General form: T(s) = (omega_n^2) / (s^2 + 2*zeta*omega_n*s + omega_n^2)
% For T(s) = 1 / (s^2 + s + 5):
wn_sq = 5;                  % Omega_n squared
wn = sqrt(wn_sq);           % Natural frequency
zeta = 1 / (2 * wn);        % Damping ratio (since 2*zeta*wn = 1)
wd = wn * sqrt(1 - zeta^2); % Damped natural frequency

% --- Time Vector ---
t = 0:0.01:10;

% --- Analytical Step Response Formula for Underdamped System ---
% y(t) = FinalValue * (1 - (exp(-zeta*wn*t)/sqrt(1-zeta^2)) * sin(wd*t + phi))
phi = acos(zeta);
steady_state_val = 1/5;     % Final value of 1/(s^2+s+5) is 1/5
y = steady_state_val * (1 - (exp(-zeta*wn*t)/sqrt(1-zeta^2)) .* sin(wd*t + phi));

% --- Calculations ---
% 1. Steady State Error (ess)
% Input is unit step (1), output settles at 1/5
ess = 1 - steady_state_val;

% 2. Peak Time (tp)
tp = pi / wd;

% 3. Maximum Peak Value (Mp_val)
max_peak_val = steady_state_val * (1 + exp(-(zeta * pi) / sqrt(1 - zeta^2)));

% 4. Peak Overshoot Percentage (PO)
PO = exp(-(zeta * pi) / sqrt(1 - zeta^2)) * 100;

% 5. Rise Time (tr)
tr = (pi - phi) / wd;

% 6. Settling Time (ts) - 2% Criterion
ts = 4 / (zeta * wn);

% 7. Delay Time (td) - Time to reach 50% of final value
td = (1 + 0.7 * zeta) / wn;

% --- Display Results ---
fprintf('--- Results for Example 1 (Alternative Method) ---\n');
fprintf('Steady-State Error: %.4f\n', ess);
fprintf('Rise Time: %.4f s\n', tr);
fprintf('Settling Time (2%%): %.4f s\n', ts);
fprintf('Peak Overshoot: %.2f%%\n', PO);
fprintf('Maximum Peak Value: %.4f\n', max_peak_val);
fprintf('Delay Time (approx): %.4f s\n', td);

% --- Plotting ---
plot(t, y, 'LineWidth', 2);
grid on;
xlabel('Time (sec)');
ylabel('Amplitude');
title('Step Response (Alternative Manual Method)');
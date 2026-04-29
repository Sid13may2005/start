% --- Control System Toolbox Version ---
wn = 5;       % Natural frequency
zeta = 0;     % Zero damping for undamped response

% Transfer Function: G(s) = wn^2 / (s^2 + 2*zeta*wn*s + wn^2)
num = [wn^2];
den = [1 2*zeta*wn wn^2]; 

% This is where your error is happening in image_e81dd0.png
sys = tf(num, den); 

% Step response
t = 0:0.01:10;
[y, t_out] = step(sys, t);

plot(t_out, y, 'LineWidth', 2);
title('Undamped Response (\zeta = 0)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;
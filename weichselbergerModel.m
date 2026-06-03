function weichselbergerModel()
    % =====================================================================
    % TEST SCRIPT (Executes when you click 'Run')
    % =====================================================================
    clc; clear; close all;
    fprintf('Running Weichselberger MIMO Channel Model Simulation...\n\n');

    % 1. Define Matrix Dimensions (e.g., 4 Transmit and 2 Receive Antennas)% Weichselberger coupling matrix –how to visualize the effects of different coupling matrix ; 
clear; clc;

% Assume 4 transmit eigenmodes and 4 receive eigenmodes

Nt = 4; Nr = 4;

% Example coupling matrix (energy concentration)
Omega_tilde = zeros(Nr, Nt);
Omega_tilde(1,1) = 0.9;   % strong coupling: Tx mode1 → Rx mode1
Omega_tilde(2,2) = 0.8;   % Tx mode2 → Rx mode2
Omega_tilde(3,4) = 0.7;   % cross coupling: Tx mode4 → Rx mode3
Omega_tilde(4,3) = 0.6;   % cross coupling: Tx mode3 → Rx mode4

% Normalise to have average power = Nt*Nr (optional)
Omega_tilde = Omega_tilde / norm(Omega_tilde, 'fro') * sqrt(Nt*Nr);

% Visualise the coupling matrix
figure;
imagesc(Omega_tilde);
colorbar;
title('Coupling Matrix \Omega_{tilde}');
xlabel('Transmit eigenmode index');
ylabel('Receive eigenmode index');
axis square
    % 3. Call the local mathematical function
    H = generateWeichselberger(Nt, Nr, Omega_tilde);

    % 4. Display the Generated Physical Channel Matrix
    disp('Generated Physical Channel Matrix H (Nr x Nt):');
    disp(H);
    
    disp('Channel Magnitude Profile abs(H):');
    disp(abs(H));
end

% =========================================================================
% WEICHSELBERGER MODEL MATHEMATICAL COMPUTATION
% =========================================================================
function H = generateWeichselberger(Nt, Nr, Omega_tilde, Ut, Ur)
    % 1. Check if eigenbases are provided, otherwise generate default ones
    if nargin < 4
        rho_t = 0.3; 
        rho_r = 0.4; 

        % Vectorized Generation of Tx correlation matrix
        [X_t, Y_t] = meshgrid(1:Nt, 1:Nt);
        R_t = rho_t .^ abs(X_t - Y_t);
        [Ut, ~] = eig(R_t); 

        % Vectorized Generation of Rx correlation matrix
        [X_r, Y_r] = meshgrid(1:Nr, 1:Nr);
        R_r = rho_r .^ abs(X_r - Y_r);
        [Ur, ~] = eig(R_r); 
    end

    % 2. Ensure the coupling matrix dimensions match the antenna array setup
    if any(size(Omega_tilde) ~= [Nr, Nt])
        error('Coupling matrix Omega_tilde must be of size Nr x Nt.');
    end

    % 3. Generate the random i.i.d. complex Gaussian matrix G
    G = (randn(Nr, Nt) + 1i * randn(Nr, Nt)) / sqrt(2); 

    % 4. Apply the coupling matrix element-wise
    H_tilde = Omega_tilde .* G;

    % 5. Transform into the physical antenna domain using spatial eigenbases
    H = Ur * H_tilde * Ut';
end
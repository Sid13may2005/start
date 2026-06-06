%% UNIFIED MIMO CHANNEL ANALYSIS: mmWAVE GEOMETRIC VS. WEICHSELBERGER COUPLING
clear; close all; clc;

% Set random seed for statistical repeatability
rng(42);

%% 1. GLOBAL PARAMETERS & SYSTEM CONFIGURATION
Nt = 8;                 % Number of transmit antennas (Unified to 8)
Nr = 4;                 % Number of receive antennas (Unified to 4)
sampling_ratio = 0.65;  % Matrix under-sampling ratio (65% observed elements)
snr_dB = 20;            % Operating SNR for capacity analysis
snr = 10^(snr_dB/10);

total_elements = Nr * Nt;
num_observations = round(sampling_ratio * total_elements);

% Define execution profiles
case_names = {'mmWave-Geo', 'Weich-Case1', 'Weich-Case2', 'Weich-Case3', 'Weich-Case4'};
num_cases = length(case_names);

% Data allocation structures for the Final Unified Report
true_rank_all      = zeros(num_cases, 1);
effective_rank_all = zeros(num_cases, 1);
coherence_all      = zeros(num_cases, 1);
nmse_linear_all    = zeros(num_cases, 1);
nmse_dB_all        = zeros(num_cases, 1);
capacity_all       = zeros(num_cases, 1);

% Allocate memory to store absolute values for visual matrix plots
H_true_store = zeros(Nr, Nt, num_cases);
H_obs_store  = zeros(Nr, Nt, num_cases);
H_rec_store  = zeros(Nr, Nt, num_cases);

%% 2. MODEL 1 GENERATION: GEOMETRIC mmWAVE CHANNEL PROFILE
% Physical properties setup
Ncl = 3;        % Number of clusters
Nray = 5;       % Number of rays per cluster
angspread = 10; % Angular spread (degrees)
fc = 28e9;      % Carrier frequency (28 GHz)
d = 0.5;        % Antenna spacing in wavelengths

% FIX: Removed the trailing '1' to match the 7-argument function signature
[H_mmwave, ~, ~] = generate_correlated_mmwave_channel(Nt, Nr, Ncl, Nray, angspread, fc, d);
H_true_store(:,:,1) = H_mmwave;

%% 3. MODEL 2 GENERATION: WEICHSELBERGER ENVIRONMENTAL CONTEXTS
% Generate Exponential Correlation Profiles
rho_t = 0.7; rho_r = 0.6;
R_t = zeros(Nt); for i=1:Nt, for j=1:Nt, R_t(i,j) = rho_t^(abs(i-j)); end; end
R_r = zeros(Nr); for i=1:Nr, for j=1:Nr, R_r(i,j) = rho_r^(abs(i-j)); end; end
R_t = R_t + eye(Nt)*1e-10; R_r = R_r + eye(Nr)*1e-10; % Numerical stabilization

% Extract spatial eigenbases
[Ut, Lambda_t] = eig(R_t); [Ur, Lambda_r] = eig(R_r);
[~, idx_t] = sort(diag(Lambda_t), 'descend'); Ut = Ut(:, idx_t);
[~, idx_r] = sort(diag(Lambda_r), 'descend'); Ur = Ur(:, idx_r);

% Generate unified i.i.d fast fading core realization matrix
G_fading = (randn(Nr, Nt) + 1i*randn(Nr, Nt)) / sqrt(2);

for w_idx = 1:4
    Omega_tilde = zeros(Nr, Nt);
    switch w_idx
        case 1 % Case 1: High Diagonal Coupling
            for i = 1:Nr, for j = 1:Nt
                if i == j, Omega_tilde(i, j) = 1.0; else, Omega_tilde(i, j) = 0.05; end
            end; end
        case 2 % Case 2: Low Diagonal Coupling
            for i = 1:Nr, for j = 1:Nt
                if i == j, Omega_tilde(i, j) = 0.1; else, Omega_tilde(i, j) = 0.05; end
            end; end
        case 3 % Case 3: High Cross-Coupling
            for i = 1:Nr, for j = 1:Nt
                if i == (Nr - j + 1), Omega_tilde(i, j) = 1.0; else, Omega_tilde(i, j) = 0.05; end
            end; end
        case 4 % Case 4: Low Cross-Coupling
            for i = 1:Nr, for j = 1:Nt
                if i ~= j && abs(i-j) <= 2, Omega_tilde(i, j) = 0.15; else, Omega_tilde(i, j) = 0.01; end
            end; end
    end
    % Normalize macro-coupling energy configuration
    Omega_tilde = Omega_tilde / norm(Omega_tilde, 'fro') * sqrt(Nt*Nr);
    
    % Synthesize the true channel instance matrix
    H_true_store(:,:,w_idx+1) = Ur * (Omega_tilde .* G_fading) * Ut';
end

%% 4. MASTER ANALYSIS PIPELINE: COMPUTE METRICS & MATRIX COMPLETION via SVT
% Create a uniform random observation selection mask
mask = zeros(Nr, Nt);
sampled_indices = randperm(total_elements, num_observations);
mask(sampled_indices) = 1;

for idx = 1:num_cases
    H_target = H_true_store(:,:,idx);
    
    % --- Part A: Analytical Structural Performance Metrics ---
    [U_coh, S_coh, V_coh] = svd(H_target, 'econ');
    true_rank_all(idx) = rank(H_target);
    
    % Spatial Coherence Factor Estimation
    mu_U = (Nr / true_rank_all(idx)) * max(sum(abs(U_coh).^2, 2));
    mu_V = (Nt / true_rank_all(idx)) * max(sum(abs(V_coh).^2, 2));
    coherence_all(idx) = max(mu_U, mu_V);
    
    % Entropy-Based Effective Rank Metric
    s_vals = diag(S_coh);
    s_vals = s_vals(s_vals > 1e-10);
    p_dist = s_vals / sum(s_vals);
    effective_rank_all(idx) = exp(-sum(p_dist .* log(p_dist + 1e-12)));
    
    % Capacity Calculation (Bits/s/Hz)
    capacity_all(idx) = real(log2(det(eye(Nr) + (snr/Nt) * H_target * H_target')));
    
    % --- Part B: Matrix Sub-Sampling & Optimization ---
    H_observed = H_target .* mask;
    H_obs_store(:,:,idx) = H_observed;
    
    % Run Singular Value Thresholding Optimization
    H_rec = zeros(Nr, Nt);
    tau = 3.5; delta = 1.2; max_iter = 500; epsilon = 1e-5;
    
    for iter = 1:max_iter
        [U, S, V] = svd(H_rec, 'econ');
        S_th = max(S - tau, 0);
        X = U * S_th * V';
        H_rec = H_rec + delta * (H_observed - (X .* mask));
        if norm(H_observed - (H_rec .* mask), 'fro') / norm(H_observed, 'fro') < epsilon
            break;
        end
    end
    H_rec_store(:,:,idx) = X;
    
    % Compute Recovery Performance Error Metrics
    nmse_linear_all(idx) = norm(H_target - X, 'fro')^2 / norm(H_target, 'fro')^2;
    nmse_dB_all(idx) = 10 * log10(nmse_linear_all(idx));
end

%% 5. COMMAND WINDOW UNIFIED PERFORMANCE REPORT 
fprintf('\n=========================================================================================\n');
fprintf('                     UNIFIED MIMO CHANNEL ANALYSIS PERFORMANCE REPORT                    \n');
fprintf('=========================================================================================\n');
fprintf('%-12s | %-10s | %-16s | %-12s | %-12s | %-12s\n', ...
        'Profile', 'True Rank', 'Effective Rank', 'Coherence', 'NMSE (dB)', 'Cap (b/s/Hz)');
fprintf('-----------------------------------------------------------------------------------------\n');
for idx = 1:num_cases
    fprintf('%-12s | %-10d | %-16.4f | %-12.4f | %-12.4f | %-12.4f\n', ...
            case_names{idx}, ...
            true_rank_all(idx), ...
            effective_rank_all(idx), ...
            coherence_all(idx), ...
            nmse_dB_all(idx), ...
            capacity_all(idx));
end
fprintf('=========================================================================================\n');
fprintf('System Setup: Array Layout = %dx%d | Sub-Sampling Mask Ratio = %.1f%%\n', ...
        Nr, Nt, sampling_ratio*100);
fprintf('=========================================================================================\n');

%% 6. UNIFIED VISUALIZATION
figure('Name', 'MIMO Matrix Profiling Comparison', 'Position', [100, 100, 1000, 500]);

% Row 1: mmWave Geometric Fading Layout
subplot(2,3,1); imagesc(abs(H_true_store(:,:,1))); colorbar; title('mmWave: Original H'); ylabel('Rx Antennas');
subplot(2,3,2); imagesc(abs(H_obs_store(:,:,1))); colorbar; title(sprintf('Observed (p=%.2f)', sampling_ratio));
subplot(2,3,3); imagesc(abs(H_rec_store(:,:,1))); colorbar; title('SVT Reconstructed');

% Row 2: Weichselberger Case 1 Environment
subplot(2,3,4); imagesc(abs(H_true_store(:,:,2))); colorbar; title('Weich-C1: Original H'); ylabel('Rx Antennas'); xlabel('Tx Antennas');
subplot(2,3,5); imagesc(abs(H_obs_store(:,:,2))); colorbar; title(sprintf('Observed (p=%.2f)', sampling_ratio)); xlabel('Tx Antennas');
subplot(2,3,6); imagesc(abs(H_rec_store(:,:,2))); colorbar; title('SVT Reconstructed'); xlabel('Tx Antennas');

%% ========================================================================
%% NESTED HELPER CORE COMPONENT FUNCTIONS
%% ========================================================================
function [H, At, Ar] = generate_correlated_mmwave_channel(Nt, Nr, Ncl, Nray, angspread, fc, d)
    lambda = 3e8/fc;
    AoD_phi = rand(Ncl, 1) * 180 - 90;  
    AoA_phi = rand(Ncl, 1) * 180 - 90;  
    
    AoD_rays = zeros(Ncl, Nray); AoA_rays = zeros(Ncl, Nray);
    for i = 1:Ncl
        AoD_rays(i,:) = AoD_phi(i) + angspread*randn(1, Nray);
        AoA_rays(i,:) = AoA_phi(i) + angspread*randn(1, Nray);
    end
    At = zeros(Nt, Ncl*Nray); Ar = zeros(Nr, Ncl*Nray);
    for j = 1:Ncl
        for l = 1:Nray
            phi_d = AoD_rays(j,l) * pi/180; n_t = 0:Nt-1;
            At(:,(j-1)*Nray+l) = exp(1j * 2 * pi * d * n_t.' * sin(phi_d) / lambda) / sqrt(Nt);
            phi_a = AoA_rays(j,l) * pi/180; n_r = 0:Nr-1;
            Ar(:,(j-1)*Nray+l) = exp(1j * 2 * pi * d * n_r.' * sin(phi_a) / lambda) / sqrt(Nr);
        end
    end
    alpha = (randn(Ncl*Nray,1) + 1j*randn(Ncl*Nray,1))/sqrt(2); 
    H = sqrt(Nt*Nr/(Ncl*Nray)) * Ar * diag(alpha) * At';
    
    % Exponential correlation injection mapping
    R_t_loc = zeros(Nt); for i=1:Nt, for j=1:Nt, R_t_loc(i,j) = 0.7^(abs(i-j)); end; end
    R_r_loc = zeros(Nr); for i=1:Nr, for j=1:Nr, R_r_loc(i,j) = 0.7^(abs(i-j)); end; end
    H = (R_r_loc^(0.5)) * H * (R_t_loc^(0.5));
end
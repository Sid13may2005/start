function exponential()
    %% ========================================================================
    %% CORE SIMULATION: mmWAVE MIMO CHANNEL COMPLETION USING SVT
    %% ========================================================================
    clear; clc; close all;

    % 1. Physical System Configuration (User Parameters)
    Nt = 8;         % Number of transmit antennas
    Nr = 4;         % Number of receive antennas
    Ncl = 3;        % Number of clusters
    Nray = 5;       % Number of rays per cluster
    angspread = 10; % Angular spread (degrees)
    fc = 28e9;      % Carrier frequency (28 GHz)
    d = 0.5;        % Antenna spacing (in wavelengths)

    fprintf('1. Generating %d x %d Correlated mmWave Channel...\n', Nr, Nt);
    % Generate the true, fully-sampled correlated channel matrix H
    [H_true, At, Ar] = generate_correlated_mmwave_channel(Nt, Nr, Ncl, Nray, angspread, fc, d, 1);


    % 2. Explicit Coherence Factor Calculation (\mu)
    [U_coh, S_coh, V_coh] = svd(H_true, 'econ');
    matrix_rank = rank(H_true);

    % Use abs() to ensure correct magnitude squaring of complex singular vectors
    mu_U = (Nr / matrix_rank) * max(sum(abs(U_coh).^2, 2));
    mu_V = (Nt / matrix_rank) * max(sum(abs(V_coh).^2, 2));

    % Total spatial coherence factor of the channel matrix
    mu_channel = max(mu_U, mu_V);


    % 3. Observation / Under-Sampling Setup
    p = 0.65; % Sampling Ratio (65%)
    Total_Elements = Nr * Nt;
    Num_Observations = round(p * Total_Elements);

    % Generate a random binary selection mask (M)
    M = zeros(Nr, Nt);
    idx = randperm(Total_Elements, Num_Observations);
    M(idx) = 1;

    % Construct the sub-sampled matrix available to the receiver
    Y = M .* H_true; 


    % 4. Singular Value Thresholding (SVT) Algorithm Implementation
    fprintf('2. Running Singular Value Thresholding (SVT) Recovery...\n');
    max_iter = 600;       % Maximum optimization iterations
    tau = 3.0;            % Singular value soft-thresholding parameter
    delta = 1.2;          % Gradient step size (0 < delta < 2)
    epsilon = 1e-5;       % Convergence tolerance limit

    % Iteration Initializations
    X = zeros(Nr, Nt);    % Primal matrix estimate
    Z = Y;                % Dual variable initialized with sparse observations

    for iter = 1:max_iter
        % Step A: Singular Value Decomposition of the updated dual matrix
        [U, S, V] = svd(Z, 'econ');
        
        % Step B: Singular Value Shrinkage (Soft-Thresholding)
        S_thr = max(S - tau, 0);
        
        % Step C: Reconstruct the current low-rank estimate
        X_new = U * S_thr * V';
        
        % Step D: Convergence criterion check
        if norm(M .* (X_new - X), 'fro') / norm(X_new, 'fro') < epsilon
            X = X_new;
            break;
        end
        X = X_new;
        
        % Step E: Dual variable gradient ascent step
        Z = Z + delta * (Y - M .* X);
    end
    H_recovered = X;


    % 5. Performance Evaluation via NMSE
    nmse_num = norm(H_true - H_recovered, 'fro')^2;
    nmse_den = norm(H_true, 'fro')^2;
    NMSE = nmse_num / nmse_den;


    % ========================================================================
    %% DISPLAY RESULTS & METRICS
    %% ========================================================================
    disp(' ');
    disp('====================================================================');
    disp('                  SIMULATION ANALYSIS REPORT                        ');
    disp('====================================================================');
    fprintf('MIMO Array Dimensions         : %d x %d (Total elements: %d)\n', Nr, Nt, Total_Elements);
    fprintf('Channel Matrix True Rank     : %d\n', matrix_rank);
    fprintf('Calculated Coherence Factor  : %.4f (Theoretical Max: %.4f)\n', mu_channel, max(Nr, Nt)/matrix_rank);
    fprintf('Number of Observations (m)   : %d elements\n', Num_Observations);
    fprintf('Matrix Sampling Ratio (p)    : %.1f%%\n', p * 100);
    disp('--------------------------------------------------------------------');
    fprintf('Reconstruction NMSE (Linear) : %e\n', NMSE);
    fprintf('Reconstruction NMSE (dB)     : %.4f dB\n', 10 * log10(NMSE));
    disp('====================================================================');

    % Plotting visual validation matrices
    figure('Name', 'Channel Completion via SVT', 'Position', [100, 100, 950, 380]);
    subplot(1,3,1); imagesc(abs(H_true)); colorbar; title('Original True H'); xlabel('Tx'); ylabel('Rx');
    subplot(1,3,2); imagesc(abs(Y)); colorbar; title(sprintf('Observed Y (%.0f%% Samples)', p*100)); xlabel('Tx'); ylabel('Rx');
    subplot(1,3,3); imagesc(abs(H_recovered)); colorbar; title('SVT Reconstructed H'); xlabel('Tx'); ylabel('Rx');
end


%% ========================================================================
%% CORE CHANNEL GENERATION HELPER FUNCTIONS
%% ========================================================================

function [H, At, Ar] = generate_correlated_mmwave_channel(Nt, Nr, Ncl, Nray, angspread, fc, d, correlation_flag)
    c = 3e8;
    lambda = c/fc;

    % Generate random macro cluster center angles (in degrees)
    AoD_phi = rand(Ncl, 1) * 180 - 90;  
    AoA_phi = rand(Ncl, 1) * 180 - 90;  

    % Generate scattered sub-rays within each cluster
    AoD_rays = zeros(Ncl, Nray);
    AoA_rays = zeros(Ncl, Nray);
    for i = 1:Ncl
        AoD_rays(i,:) = AoD_phi(i) + angspread*randn(1, Nray);
        AoA_rays(i,:) = AoA_phi(i) + angspread*randn(1, Nray);
    end

    At = zeros(Nt, Ncl*Nray);
    Ar = zeros(Nr, Ncl*Nray);

    % Compute Uniform Linear Array (ULA) steering response vectors
    for j = 1:Ncl
        for l = 1:Nray
            At(:,(j-1)*Nray+l) = array_response(AoD_rays(j,l), Nt, d, lambda);
            Ar(:,(j-1)*Nray+l) = array_response(AoA_rays(j,l), Nr, d, lambda);
        end
    end

    % Generate complex random path gains (\alpha)
    alpha = (randn(Ncl*Nray,1) + 1j*randn(Ncl*Nray,1))/sqrt(2); 

    % Base Geometric Multipath Matrix
    H = sqrt(Nt*Nr/(Ncl*Nray)) * Ar * diag(alpha) * At';

    % Apply Spatial Correlation Injection
    if correlation_flag
        Rt = generate_correlation_matrix(Nt, 0.7); 
        Rr = generate_correlation_matrix(Nr, 0.7); 
        H = Rr^(1/2) * H * Rt^(1/2);
    end
end

function a = array_response(phi, N, d, lambda)
    phi = phi * pi/180;
    n = 0:N-1;
    a = exp(1j * 2 * pi * d * n.' * sin(phi) / lambda);
    a = a / sqrt(N); 
end

function R = generate_correlation_matrix(N, rho)
    R = zeros(N,N);
    for i = 1:N
        for j = 1:N
            R(i,j) = rho^abs(i-j);
        end
    end
end
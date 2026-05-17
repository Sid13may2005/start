% Generate a low‑rank matrix
m = 50; n = 40; r = 5;
U = randn(m, r); V = randn(n, r);
M_true = U * V';

% Observe 40% of entries
obs_ratio = 0.4;
omega = randperm(m*n, round(obs_ratio * m * n));
M_obs = nan(m, n);
M_obs(omega) = M_true(omega);

% Parameters
tau = 5 * sqrt(m * n);
delta = 1.2 / obs_ratio;
max_iter = 200;
tol = 1e-6;

% Run completion
[X_rec, err_hist] = simple_svt(M_obs, omega, tau, delta, max_iter, tol);

% Evaluate
rel_error = norm(X_rec - M_true, 'fro') / norm(M_true, 'fro');
fprintf('Relative error: %.4f\n', rel_error);

% Plot convergence
semilogy(err_hist); grid on;
xlabel('Iteration'); ylabel('Relative Change');
title('SVT Convergence');
%The algorithm works for both real and complex matrices (MATLAB's svd handles complex values natively).

%The default choice tau = 5 * sqrt(m*n) is a common heuristic; it may need tuning for specific noise levels.

%The step size delta is often chosen as 1.2 / (sampling_ratio) to ensure convergence.

%For large matrices, the SVD inside the loop becomes the computational bottleneck; consider using svds for a truncated SVD 
%if the rank is known to be small.


function [X_rec, err_hist] = simple_svt(M_obs, omega, tau, delta, max_iter, tol)
% SIMPLE_SVT Matrix completion via Singular Value Thresholding (SVT).
%
%   [X_rec, err_hist] = simple_svt(M_obs, omega, tau, delta, max_iter, tol)
%
% Inputs:
%   M_obs   : matrix with observed entries (unobserved entries should be NaN)
%   omega   : linear indices of observed entries (e.g., from randperm)
%   tau     : threshold parameter (typically 5*sqrt(m*n) for m×n matrix)
%   delta   : step size (typically 1.2 / sampling_ratio)
%   max_iter: maximum number of iterations
%   tol     : convergence tolerance (relative change in Frobenius norm)
%
% Outputs:
%   X_rec   : completed matrix
%   err_hist: vector of relative errors per iteration

    % Get matrix dimensions
    [m, n] = size(M_obs);
    
    % Create mask for observed entries
    mask = false(m, n);
    mask(omega) = true;
    
    % Replace NaN with zeros for convenience
    M_obs_zero = M_obs;
    M_obs_zero(~mask) = 0;
    
    % Initialize
    X = zeros(m, n, 'like', M_obs);
    Y = zeros(m, n, 'like', M_obs);
    err_hist = zeros(max_iter, 1);
    
    for k = 1:max_iter
        % Singular value thresholding
        [U, S, V] = svd(Y, 'econ');
        S_thresh = max(S - tau, 0);
        X_new = U * S_thresh * V';
        
        % Enforce data consistency on observed entries
        X_new(mask) = M_obs_zero(mask);
        
        % Update Y
        Y = Y + delta * (M_obs_zero - X_new .* mask);
        
        % Compute relative change
        err = norm(X_new - X, 'fro') / (norm(X, 'fro') + eps);
        err_hist(k) = err;
        
        if err < tol
            break;
        end
        X = X_new;
    end
    
    X_rec = X_new;
    err_hist = err_hist(1:k);
end

%% Matrix Completion Demo for Beginners
clear; clc; close all;

%% 1. Create a Sample Low-Rank Matrix
fprintf('=== Matrix Completion Demo ===\n\n');

% Create a simple low-rank matrix (rank = 2)
m = 20; n = 15;
U = randn(m, 2);
V = randn(n, 2);
true_matrix = U * V';  % This creates a rank-2 matrix

fprintf('True matrix size: %d x %d\n', m, n);
fprintf('True matrix rank: %d\n', rank(true_matrix));

%% 2. Create Mask with Missing Entries
fprintf('\n2. Creating incomplete matrix...\n');

% Percentage of observed entries
observation_ratio = 0.3;  % 30% of entries are observed

% Create random mask
mask = rand(m, n) < observation_ratio;
observed_matrix = true_matrix .* mask;

fprintf('Observation ratio: %.1f%%\n', observation_ratio * 100);
fprintf('Number of observed entries: %d\n', sum(mask(:)));

%% 3. Visualize the Matrices
figure('Position', [100, 100, 1200, 400]);

subplot(1,3,1);
imagesc(true_matrix);
title('True Matrix');
colorbar;
axis square;

subplot(1,3,2);
imagesc(mask);
title('Observation Mask (White = Observed)');
colormap(gray);
axis square;

subplot(1,3,3);
imagesc(observed_matrix);
title('Observed Matrix (with missing values)');
colorbar;
axis square;

%% 4. Simple Matrix Completion using SVD
fprintf('\n3. Performing matrix completion...\n');

% Fill missing values with column means as initial guess
initial_guess = observed_matrix;
missing_indices = find(~mask);

% Simple initialization: use column means for missing values
for j = 1:n
    col_data = observed_matrix(:, j);
    observed_values = col_data(mask(:, j));
    if ~isempty(observed_values)
        initial_guess(~mask(:, j), j) = mean(observed_values);
    else
        initial_guess(~mask(:, j), j) = 0;
    end
end

% Perform SVD and keep top k components
k = 2;  % We know the true rank is 2
[U_est, S_est, V_est] = svd(initial_guess, 'econ');
completed_matrix = U_est(:, 1:k) * S_est(1:k, 1:k) * V_est(:, 1:k)';

%% 5. Evaluate Results
fprintf('\n4. Evaluating results...\n');

% Calculate reconstruction error only on observed entries
observed_error = norm((completed_matrix - true_matrix) .* mask, 'fro') / norm(true_matrix .* mask, 'fro');
full_error = norm(completed_matrix - true_matrix, 'fro') / norm(true_matrix, 'fro');

fprintf('Relative error on observed entries: %.4f\n', observed_error);
fprintf('Relative error on full matrix: %.4f\n', full_error);

%% 6. Visualize Results
figure('Position', [100, 100, 1200, 400]);

subplot(1,3,1);
imagesc(true_matrix);
title('True Matrix');
colorbar;
axis square;

subplot(1,3,2);
imagesc(observed_matrix);
title('Observed Matrix');
colorbar;
axis square;

subplot(1,3,3);
imagesc(completed_matrix);
title('Completed Matrix');
colorbar;
axis square;

%% 7. Compare Values for a Few Entries
fprintf('\n5. Sample value comparison:\n');
fprintf('Row\tCol\tTrue\tObserved\tCompleted\n');
fprintf('---\t---\t----\t--------\t---------\n');

% Display sample comparisons
for i = 1:min(5, m)
    for j = 1:min(3, n)
        fprintf('%d\t%d\t%.2f\t', i, j, true_matrix(i,j));
        if mask(i,j)
            fprintf('%.2f\t', observed_matrix(i,j));
        else
            fprintf('NaN\t');
        end
        fprintf('%.2f\n', completed_matrix(i,j));
    end
end


% mmWave channels are naturally low-rank
Nt = 64; Nr = 16; N_clusters = 3;

% Generate mmWave channel (low-rank by nature)
H_true = zeros(Nr, Nt);
for c = 1:N_clusters
    ar = exp(1i*pi*(0:Nr-1)'*rand())/sqrt(Nr);
    at = exp(1i*pi*(0:Nt-1)*rand())/sqrt(Nt);
    H_true = H_true + (randn()+1i*randn())*ar*at;
end

rank_H = rank(H_true);
fprintf('True channel rank: %d (out of %d)\n', rank_H, min(Nr,Nt));
fprintf('Compression potential: %.1f%%\n', (1-rank_H/min(Nr,Nt))*100);
OBSERVATION MODEL
% Incomplete observations (due to limited pilot transmission)
function Y = get_partial_observations(H, sampling_rate)
    [Nr, Nt] = size(H);
    Omega = rand(Nr, Nt) < sampling_rate;  % Sampling mask
    Y = Omega .* H + sqrt(0.01)*(randn(Nr,Nt)+1i*randn(Nr,Nt));
    % Y contains noisy partial observations
end



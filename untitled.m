%% Matrix Completion with Incoherence Control
clear; clc; close all;

%% 1. Methods to Generate Incoherent Low-Rank Matrices
fprintf('=== Incoherence Control in Matrix Completion ===\n\n');

% Parameters
m = 100; n = 80; rank = 4;
observation_ratio = 0.4;

fprintf('Matrix size: %d x %d, Rank: %d\n', m, n, rank);
fprintf('Observation ratio: %.1f%%\n', observation_ratio * 100);

%% Method 1: Generate Incoherent Matrix (Recommended)
fprintf('\n1. Generating incoherent low-rank matrix...\n');

% Generate random orthogonal matrices (incoherent by construction)
U = randn(m, rank);
[U, ~] = qr(U, 0);  % Orthogonalize
U = U(:, 1:rank);

V = randn(n, rank);
[V, ~] = qr(V, 0);
V = V(:, 1:rank);

% Create singular values (well-conditioned)
sigma = linspace(1, 0.5, rank)';
true_matrix = U * diag(sigma) * V';

% Measure coherence
coherence_U = max(sum(U.^2, 2)) * m / rank;
coherence_V = max(sum(V.^2, 2)) * n / rank;
coherence = max(coherence_U, coherence_V);

fprintf('Coherence parameter μ: %.2f (ideal: < 5-10)\n', coherence);

%% Method 2: Generate Coherent Matrix (for comparison)
fprintf('\n2. Generating coherent matrix for comparison...\n');

% Create coherent matrix (singular vectors aligned with basis)
U_coherent = zeros(m, rank);
U_coherent(1:rank, 1:rank) = eye(rank);
U_coherent = orth(U_coherent);  % Still very coherent

V_coherent = zeros(n, rank);
V_coherent(1:rank, 1:rank) = eye(rank);
V_coherent = orth(V_coherent);

coherent_matrix = U_coherent * diag(sigma) * V_coherent';

% Measure coherence
coherence_U_coherent = max(sum(U_coherent.^2, 2)) * m / rank;
coherence_V_coherent = max(sum(V_coherent.^2, 2)) * n / rank;
coherence_coherent = max(coherence_U_coherent, coherence_V_coherent);

fprintf('Coherent matrix μ: %.2f (problematic!)\n', coherence_coherent);

%% 3. Visualize Coherence Patterns
figure('Position', [100, 100, 1200, 500]);

subplot(1,2,1);
imagesc(U * U');
title('Incoherent: UU^T (Spread out)');
colorbar;
axis square;

subplot(1,2,2);
imagesc(U_coherent * U_coherent');
title('Coherent: UU^T (Concentrated)');
colorbar;
axis square;

%% 4. Create Observation Masks
rng(42); % For reproducibility

% Uniform random sampling (works well for incoherent matrices)
mask_incoherent = rand(m, n) < observation_ratio;
observed_incoherent = true_matrix .* mask_incoherent;

mask_coherent = rand(m, n) < observation_ratio;
observed_coherent = coherent_matrix .* mask_coherent;

%% 5. Matrix Completion Function with Incoherence Regularization
function X = matrix_completion_with_incoherence(Y, mask, rank, lambda, mu, max_iter)
    % Y: observed matrix, mask: observation pattern
    % lambda: nuclear norm parameter, mu: incoherence parameter
    
    [m, n] = size(Y);
    X = Y;
    X(~mask) = mean(Y(mask));  % Initialize with mean
    
    for iter = 1:max_iter
        % Nuclear norm minimization
        [U, S, V] = svd(X, 'econ');
        S_soft = sign(S) .* max(abs(S) - lambda, 0);
        X_nuclear = U * S_soft * V';
        
        % Incoherence regularization
        X = (1 - mu) * X_nuclear + mu * project_to_incoherent(X_nuclear, rank);
        
        % Project observed entries
        X(mask) = Y(mask);
        
        % Check convergence
        if iter > 1 && norm(X - X_prev, 'fro')/norm(X_prev, 'fro') < 1e-6
            break;
        end
        X_prev = X;
    end
end

function X_proj = project_to_incoherent(X, rank)
    % Project matrix to be more incoherent
    [U, S, V] = svd(X, 'econ');
    
    % Make singular vectors more spread out
    U = make_incoherent(U(:, 1:rank), size(U,1));
    V = make_incoherent(V(:, 1:rank), size(V,1));
    
    X_proj = U * S(1:rank, 1:rank) * V';
end

function U_incoherent = make_incoherent(U, n)
    % Make matrix columns more incoherent
    U_incoherent = U;
    for col = 1:size(U,2)
        % Add small random noise to spread out energy
        noise = 0.1 * randn(size(U,1), 1);
        U_incoherent(:, col) = U(:, col) + noise;
        U_incoherent(:, col) = U_incoherent(:, col) / norm(U_incoherent(:, col));
    end
    % Re-orthogonalize
    [U_incoherent, ~] = qr(U_incoherent, 0);
end

%% 6. Compare Completion Performance
fprintf('\n3. Comparing completion performance...\n');

% Complete both matrices
lambda = 0.1; mu = 0.05; max_iter = 100;

completed_incoherent = matrix_completion_with_incoherence(...
    observed_incoherent, mask_incoherent, rank, lambda, mu, max_iter);

completed_coherent = matrix_completion_with_incoherence(...
    observed_coherent, mask_coherent, rank, lambda, mu, max_iter);

% Calculate errors
error_incoherent = norm(completed_incoherent - true_matrix, 'fro') / norm(true_matrix, 'fro');
error_coherent = norm(completed_coherent - coherent_matrix, 'fro') / norm(coherent_matrix, 'fro');

fprintf('Recovery error - Incoherent matrix: %.4f\n', error_incoherent);
fprintf('Recovery error - Coherent matrix:   %.4f\n', error_coherent);

%% 7. Practical Techniques to Ensure Incoherence
fprintf('\n4. Practical techniques to ensure incoherence:\n');

% Technique 1: Pre-whitening/Pre-conditioning
fprintf('a) Data pre-whitening\n');

% Technique 2: Random rotation
fprintf('b) Random rotation of data\n');
R = randn(n, n); R = orth(R);
rotated_matrix = true_matrix * R;
% Complete in rotated space, then rotate back

% Technique 3: Add small random noise
fprintf('c) Add small random noise\n');
noise_level = 0.01;
regularized_matrix = true_matrix + noise_level * randn(m, n);

%% 8. Coherence Measurement Function
function [coherence, coherence_U, coherence_V] = measure_coherence(X, rank)
    % Measure coherence of a matrix
    [U, S, V] = svd(X, 'econ');
    U = U(:, 1:rank);
    V = V(:, 1:rank);
    
    [m, n] = size(X);
    coherence_U = max(sum(U.^2, 2)) * m / rank;
    coherence_V = max(sum(V.^2, 2)) * n / rank;
    coherence = max(coherence_U, coherence_V);
end

% Measure coherence of our matrices
[coherence_true, ~, ~] = measure_coherence(true_matrix, rank);
[coherence_coherent, ~, ~] = measure_coherence(coherent_matrix, rank);

fprintf('\nCoherence measurements:\n');
fprintf('Incoherent matrix: μ = %.2f\n', coherence_true);
fprintf('Coherent matrix:   μ = %.2f\n', coherence_coherent);

%% 9. Visualize Recovery Quality
figure('Position', [100, 100, 1200, 800]);

% Incoherent matrix results
subplot(2,3,1);
imagesc(true_matrix);
title('True Incoherent Matrix');
colorbar;

subplot(2,3,2);
imagesc(observed_incoherent);
title('Observed (40%)');
colorbar;

subplot(2,3,3);
imagesc(completed_incoherent);
title(sprintf('Recovered (Error: %.3f)', error_incoherent));
colorbar;

% Coherent matrix results
subplot(2,3,4);
imagesc(coherent_matrix);
title('True Coherent Matrix');
colorbar;

subplot(2,3,5);
imagesc(observed_coherent);
title('Observed (40%)');
colorbar;

subplot(2,3,6);
imagesc(completed_coherent);
title(sprintf('Recovered (Error: %.3f)', error_coherent));
colorbar;

%% 10. Theoretical Recovery Guarantees
fprintf('\n5. Theoretical recovery guarantees:\n');

% Required observations for exact recovery (theoretical)
mu = coherence_true;
required_obs_theoretical = mu * rank * (m + n) * log(m+n)^2;
actual_obs = sum(mask_incoherent(:));

fprintf('Theoretical required observations: %.0f\n', required_obs_theoretical);
fprintf('Actual observations:              %d\n', actual_obs);
fprintf('Sufficient for recovery:          %s\n', ...
    string(actual_obs > required_obs_theoretical));

% Practical success probability
success_prob = min(1, actual_obs / required_obs_theoretical);
fprintf('Estimated success probability:    %.2f\n', success_prob);
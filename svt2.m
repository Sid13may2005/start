% Generate a low-rank matrix
m = 100; n = 100; true_rank = 5;
U = randn(m, true_rank);
V = randn(n, true_rank);
M_true = U * V'; % True low-rank matrix

% Create observation mask (50% observed)
mask = rand(m,n) > 0.5;
D = M_true .* mask; % Observed entries

% Run SVT algorithm
[X, err_history, rank_history] = svt_matrix_completion(D, mask, ...
    'tau', 100, ...      % Threshold parameter
    'delta', 1.2, ...    % Step size
    'max_iter', 200, ... % Max iterations
    'tol', 1e-5);        % Tolerance

% Calculate reconstruction error
reconstruction_error = norm(X - M_true, 'fro') / norm(M_true, 'fro');
fprintf('Final reconstruction error: %.4f\n', reconstruction_error);

% Visualize results
figure;
subplot(1,3,1); imagesc(M_true); title('True Matrix'); colorbar;
subplot(1,3,2); imagesc(D); title('Observed Entries'); colorbar;
subplot(1,3,3); imagesc(X); title('Recovered Matrix'); colorbar;
%Displaying svt-1.m.Previous

function [X, err_history, rank_history] = svt_matrix_completion(D, mask, varargin)
% SVT_MATRIX_COMPLETION Matrix completion via Singular Value Thresholding
%
% Inputs:
%   D: Observed matrix (NaN or 0 for missing entries)
%   mask: Binary mask (1 for observed, 0 for missing)
% Optional parameters (name-value pairs):
%   'tau': Threshold parameter (default: 5*N)
%   'delta': Step size (default: 1.2)
%   'max_iter': Maximum iterations (default: 500)
%   'tol': Convergence tolerance (default: 1e-4)
%   'rank_estimate': Initial rank estimate (default: min(size(D)))
%
% Outputs:
%   X: Completed matrix
%   err_history: Relative error history
%   rank_history: Rank history

% Process parameters
p = inputParser;
addParameter(p, 'tau', [], @isnumeric);
addParameter(p, 'delta', 1.2, @isnumeric);
addParameter(p, 'max_iter', 500, @isnumeric);
addParameter(p, 'tol', 1e-4, @isnumeric);
addParameter(p, 'rank_estimate', [], @isnumeric);
parse(p, varargin{:});

params = p.Results;

% Initialize
[m, n] = size(D);
if isempty(params.tau)
    params.tau = 5*max(m,n); % Default threshold
end
if isempty(params.rank_estimate)
    params.rank_estimate = min(m,n);
end

% Prepare observed data
D_obs = D;
D_obs(~mask) = 0; % Set missing entries to 0
norm_D_obs = norm(D_obs, 'fro');

% Initialize variables
Y = zeros(m, n);
X = zeros(m, n);
err_history = zeros(params.max_iter, 1);
rank_history = zeros(params.max_iter, 1);

% Main SVT loop
for k = 1:params.max_iter
    % Singular value thresholding
    [U, S, V] = svd(Y, 'econ');
    S_thresh = max(S - params.tau, 0);
    r = sum(diag(S_thresh) > 0); % Current rank
    X = U * S_thresh * V';
    
    % Update Y
    Y = Y + params.delta * (D_obs - X.*mask);
    
    % Track progress
    err = norm((X - D_obs).*mask, 'fro') / norm_D_obs;
    err_history(k) = err;
    rank_history(k) = r;
    
    % Display progress
    if mod(k, 50) == 0
        fprintf('Iter %4d: Rel Err = %.4e, Rank = %d\n', k, err, r);
    end
    
    % Check convergence
    if err < params.tol
        fprintf('Converged at iteration %d\n', k);
        break;
    end
end

% Truncate history arrays
err_history = err_history(1:k);
rank_history = rank_history(1:k);

% Plot results
figure;
subplot(2,1,1);
plot(err_history, 'LineWidth', 2);
title('Relative Error vs Iteration');
xlabel('Iteration'); ylabel('Relative Error');
grid on;

subplot(2,1,2);
plot(rank_history, 'LineWidth', 2);
title('Matrix Rank vs Iteration');
xlabel('Iteration'); ylabel('Rank');
grid on;
end
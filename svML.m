%% SV MODEL ANALYSIS: DOMINATING FACTORS FOR MATRIX COMPLETION
clc;
clear;
close all;

%% ============================================================
% 1. System Parameters
%% ============================================================
Nt = 16; 
Nr = 8;
Num_sim = 5; % Number of channel realizations per configuration
target_nmse_db = -15;

% Parameter Grid for SV Model
C_values = [1, 2, 3, 5, 8];
spread_deg_values = [2, 5, 10, 20, 30];

%% ============================================================
% 2. Storage Initialization
%% ============================================================
% We will store every configuration's average metrics to analyze later
all_C = [];
all_spread = [];
all_erank = [];
all_mu = [];
all_pilot_ratio = [];
all_nmse = [];

fprintf('Starting SV Model Simulation & Data Collection...\n');
fprintf('------------------------------------------------------\n');
fprintf(' Clus | Spread | Eff.Rank | Coherence | Pilot Ratio \n');
fprintf('------------------------------------------------------\n');

%% ============================================================
% 3. Main Data Generation Loop
%% ============================================================
for C = C_values
    for spread_deg = spread_deg_values
        spread_rad = deg2rad(spread_deg);
        
        temp_erank = zeros(Num_sim, 1);
        temp_mu = zeros(Num_sim, 1);
        temp_ratio = zeros(Num_sim, 1);
        temp_nmse = zeros(Num_sim, 1);
        
        for sim = 1:Num_sim
            %% A. Generate SV Channel
            H = generate_sv_channel(Nt, Nr, C, spread_rad);
            
            %% B. Extract Effective Rank
            [U, S, V] = svd(H, 'econ');
            sigma = diag(S);
            p = sigma.^2 / (sum(sigma.^2) + eps);
            erank = exp(-sum(p .* log(p + eps)));
            temp_erank(sim) = erank;
            
            %% C. Extract Coherence (using definition from modelfitting.m)
            r_est = min(size(U,2), size(V,2));
            if r_est > 0
                U_sub = U(:,1:r_est); V_sub = V(:,1:r_est);
                mu0_U = max(sum(abs(U_sub).^2,2)) * Nt / r_est;
                mu0_V = max(sum(abs(V_sub).^2,2)) * Nr / r_est;
                UV = U_sub * V_sub';
                mu1 = max(abs(UV(:))) * sqrt(Nt*Nr / r_est);
                temp_mu(sim) = max([mu0_U, mu0_V, mu1]);
            else
                temp_mu(sim) = 1;
            end
            
            %% D. SVT Binary Search for Required Pilot Ratio
            low_ratio = 0.05; 
            high_ratio = 0.8;
            max_search_iter = 10; 
            num_trials = 5;
            best_nmse = 1;
            
            for search_iter = 1:max_search_iter
                test_ratio = (low_ratio + high_ratio)/2;
                successes = 0;
                nmse_list = zeros(num_trials, 1);
                
                for trial = 1:num_trials
                    mask = rand(size(H)) < test_ratio;
                    D = H .* mask;
                    
                    tau = 5 * max(Nr, Nt); 
                    delta = 1.2;
                    [Xhat, ~, ~] = svt_matrix_completion(D, mask, tau, delta, 200, 1e-4);
                    
                    nmse = norm(H-Xhat,'fro')^2 / (norm(H,'fro')^2 + eps);
                    nmse_list(trial) = nmse;
                    
                    if 10*log10(nmse) <= target_nmse_db
                        successes = successes + 1;
                    end
                end
                
                if (successes/num_trials) >= 0.6 % 60% success threshold for stability
                    high_ratio = test_ratio;
                    best_nmse = mean(nmse_list);
                else
                    low_ratio = test_ratio;
                end
                
                if abs(high_ratio - low_ratio) < 0.02
                    break; 
                end
            end
            
            temp_ratio(sim) = high_ratio;
            temp_nmse(sim) = best_nmse;
        end
        
        % Average and Store
        avg_C = C;
        avg_spread = spread_deg;
        avg_erank = mean(temp_erank);
        avg_mu = mean(temp_mu);
        avg_ratio = mean(temp_ratio);
        avg_nmse_db = 10*log10(mean(temp_nmse) + eps);
        
        all_C = [all_C; avg_C];
        all_spread = [all_spread; avg_spread];
        all_erank = [all_erank; avg_erank];
        all_mu = [all_mu; avg_mu];
        all_pilot_ratio = [all_pilot_ratio; avg_ratio];
        all_nmse = [all_nmse; avg_nmse_db];
        
        fprintf('  %2d  |  %4.1f  |  %7.4f  |  %7.4f  |  %7.4f \n', ...
            avg_C, avg_spread, avg_erank, avg_mu, avg_ratio);
    end
end
fprintf('------------------------------------------------------\n');

%% ============================================================
% 4. Dominating Factor Analysis (Standardized Regression)
%% ============================================================
% To find what factor dominates the Required Pilot Ratio, we convert all 
% variables to Z-scores (mean = 0, std = 1). This allows us to compare 
% physical parameters (Spread) directly with mathematical ones (Rank).

Z_C = (all_C - mean(all_C)) / std(all_C);
Z_spread = (all_spread - mean(all_spread)) / std(all_spread);
Z_erank = (all_erank - mean(all_erank)) / std(all_erank);
Z_mu = (all_mu - mean(all_mu)) / std(all_mu);
Z_pilot = (all_pilot_ratio - mean(all_pilot_ratio)) / std(all_pilot_ratio);

% Design Matrix (No intercept needed since data is zero-mean)
X_factors = [Z_C, Z_spread, Z_erank, Z_mu];
factor_names = {'Clusters', 'Angular Spread', 'Effective Rank', 'Coherence'};

% Ordinary Least Squares for Factor Importance
weights = X_factors \ Z_pilot; 
importance = abs(weights); % Magnitude dictates dominance

[sorted_importance, sort_idx] = sort(importance, 'descend');
sorted_names = factor_names(sort_idx);

fprintf('\n=== DOMINATING FACTORS FOR REQUIRED PILOT RATIO ===\n');
for i = 1:length(weights)
    fprintf('%d. %-15s : Weight = %6.4f (Importance = %.4f)\n', ...
        i, sorted_names{i}, weights(sort_idx(i)), sorted_importance(i));
end

%% ============================================================
% 5. Visualizations
%% ============================================================
figure('Name', 'Dominating Factors Analysis', 'Position', [100 100 1000 400], 'Color', 'w');

% Plot 1: Feature Importance Bar Chart
subplot(1,2,1);
bar_handle = bar(sorted_importance, 'FaceColor', [0 0.447 0.741]);
set(gca, 'XTickLabel', sorted_names, 'XTickLabelRotation', 45);
ylabel('Absolute Standardized Weight');
title('Dominating Factors on Pilot Ratio');
grid on;

% Plot 2: Scatter plot of the Most Dominant Factor vs Pilot Ratio
subplot(1,2,2);
if sort_idx(1) == 1, dom_data = all_C;
elseif sort_idx(1) == 2, dom_data = all_spread;
elseif sort_idx(1) == 3, dom_data = all_erank;
else, dom_data = all_mu;
end

scatter(dom_data, all_pilot_ratio, 60, all_pilot_ratio, 'filled');
colormap('parula');
cb = colorbar;
cb.Label.String = 'Required Pilot Ratio';
xlabel(sorted_names{1});
ylabel('Required Pilot Ratio');
title(sprintf('Top Factor: %s vs. Pilot Ratio', sorted_names{1}));
grid on;

%% ============================================================
% Functions
%% ============================================================

function H = generate_sv_channel(Nt, Nr, C, spread_rad)
    H = zeros(Nr, Nt);
    theta_center_tx = pi * (rand(C,1) - 0.5);
    theta_center_rx = pi * (rand(C,1) - 0.5);
    P_c = exp(-(0:C-1)' / 2); 
    P_c = P_c / sum(P_c);
    num_rays = 5;
    for c = 1:C
        for r = 1:num_rays
            delta_tx = spread_rad * (rand - 0.5);
            delta_rx = spread_rad * (rand - 0.5);
            theta_tx = theta_center_tx(c) + delta_tx;
            theta_rx = theta_center_rx(c) + delta_rx;
            a_tx = exp(1j * pi * (0:Nt-1)' * sin(theta_tx)) / sqrt(Nt);
            a_rx = exp(1j * pi * (0:Nr-1)' * sin(theta_rx)) / sqrt(Nr);
            alpha = (randn + 1j*randn) / sqrt(2);
            H = H + sqrt(P_c(c) / num_rays) * alpha * a_rx * a_tx';
        end
    end
end

function [X, err_history, rank_history] = svt_matrix_completion(D, mask, tau, delta, max_iter, tol)
    [m, n] = size(D);
    D_obs = D;
    D_obs(~mask) = 0;
    norm_D_obs = norm(D_obs, 'fro');

    Y = zeros(m, n);
    X = zeros(m, n);
    err_history = zeros(max_iter, 1);
    rank_history = zeros(max_iter, 1);

    for k = 1:max_iter
        [U, S, V] = svd(Y, 'econ');
        S_thresh = max(S - tau, 0);
        r = sum(diag(S_thresh) > 0);
        X = U * S_thresh * V';
        
        Y = Y + delta * (D_obs - X.*mask);
        err = norm((X - D_obs).*mask, 'fro') / (norm_D_obs + eps);
        err_history(k) = err;
        rank_history(k) = r;
        
        if err < tol
            break;
        end
    end
    err_history = err_history(1:k);
    rank_history = rank_history(1:k);
end
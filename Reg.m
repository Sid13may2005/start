%% ONE-RING, SV, AND WEICHSELBERGER ANALYSIS VIA CLASSIC SVT (WITH REGRESSION)
clc;
clear;
close all;

%% ============================================================
% Global Parameters
%% ============================================================
Nr = 16;
Nt = 8;
Num_sim = 50; % Set to 50 for robust distribution plotting
target_nmse_db = -15;
minDim = min(Nr, Nt);

%% ============================================================
% Model Parameters
%% ============================================================
angular_spreads = [0.5 2 5 10 20];
d = 0.5;
mean_angle = 30;

sv_clusters = [1 2 3 5 8];
Nray = 3;
fc = 28e9;
d_sv = 0.5;

weich_cases = 1:4;

%% ============================================================
% Global Spectrum & Regression Storage
%% ============================================================
% We capture the last configurations to build fair global distribution plots
sv_onering_matrix = zeros(minDim, Num_sim);
sv_weich_matrix = zeros(minDim, Num_sim);
sv_sv_matrix = zeros(minDim, Num_sim);

rank_onering_vector = zeros(Num_sim, 1);
rank_weich_vector = zeros(Num_sim, 1);
rank_sv_vector = zeros(Num_sim, 1);

% Storage for Regression (all trials across all parameters)
reg_rank_onering = []; reg_ratio_onering = [];
reg_rank_sv      = []; reg_ratio_sv      = [];
reg_rank_weich   = []; reg_ratio_weich   = [];

%% ============================================================
% Table Metric Storage Preallocation
%% ============================================================
avg_rank = zeros(length(angular_spreads),1);
avg_coherence = zeros(length(angular_spreads),1);
avg_required_ratio = zeros(length(angular_spreads),1);
avg_required_obs = zeros(length(angular_spreads),1);
avg_nmse = zeros(length(angular_spreads),1);

avg_rank_sv = zeros(length(sv_clusters),1);
avg_coherence_sv = zeros(length(sv_clusters),1);
avg_required_ratio_sv = zeros(length(sv_clusters),1);
avg_required_obs_sv = zeros(length(sv_clusters),1);
avg_nmse_sv = zeros(length(sv_clusters),1);

avg_rank_weich = zeros(length(weich_cases),1);
avg_coherence_weich = zeros(length(weich_cases),1);
avg_required_ratio_weich = zeros(length(weich_cases),1);
avg_required_obs_weich = zeros(length(weich_cases),1);
avg_nmse_weich = zeros(length(weich_cases),1);

%% ============================================================
% Main Loop - One Ring Model
%% ============================================================
fprintf('Simulating One-Ring Model...\n');
for j = 1:length(angular_spreads)
    current_spread = angular_spreads(j);
    rank_all = zeros(Num_sim,1);
    coherence_all = zeros(Num_sim,1);
    required_ratio_all = zeros(Num_sim,1);
    required_obs_all = zeros(Num_sim,1);
    nmse_all = zeros(Num_sim,1);
    
    for i = 1:Num_sim
        Rr = generate_onering_correlation(Nr,d,mean_angle,current_spread);
        Rt = generate_onering_correlation(Nt,d,mean_angle,current_spread);
        Hw = (randn(Nr,Nt) + 1j*randn(Nr,Nt))/sqrt(2);
        H_one_ring = sqrtm(Rr) * Hw * sqrtm(Rt);
        
        s = svd(H_one_ring);
        p = s/(sum(s)+eps);
        rank_all(i) = exp(-sum(p.*log(p+eps)));
        [~,~,coherence_all(i)] = sv_coherence_both(H_one_ring);
        
        if j == 2 % Save specific spread snapshot for global ECDF comparison
            sv_onering_matrix(:, i) = s / max(s);
            rank_onering_vector(i) = rank_all(i);
        end
        
        low_ratio = 0.05; high_ratio = 1;
        max_search_iter = 12; num_trials = 10;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio = (low_ratio + high_ratio)/2;
            successes = 0;
            for trial = 1:num_trials
                mask = rand(size(H_one_ring)) < test_ratio;
                D = H_one_ring .* mask;
                
                tau = 5 * max(Nr, Nt); delta = 1.2;
                [Xhat,~,~] = svt_matrix_completion(D, mask, 'tau', tau, 'delta', delta);
                
                nmse = norm(H_one_ring-Xhat,'fro')^2 / (norm(H_one_ring,'fro')^2 + eps);
                trial_nmse_list(trial) = nmse;
                if 10*log10(nmse) <= target_nmse_db
                    successes = successes + 1;
                end
            end
            if (successes/num_trials) >= 0.7
                high_ratio = test_ratio;
            else
                low_ratio = test_ratio;
            end
            if abs(high_ratio-low_ratio) < 0.01, break; end
        end
        required_ratio_all(i) = high_ratio;
        required_obs_all(i) = ceil(high_ratio * Nr * Nt);
        nmse_all(i) = mean(trial_nmse_list);
    end
    avg_rank(j) = mean(rank_all);
    avg_coherence(j) = mean(coherence_all);
    avg_required_ratio(j) = mean(required_ratio_all);
    avg_required_obs(j) = round(mean(required_obs_all));
    avg_nmse(j) = 10*log10(mean(nmse_all) + eps);
    
    % Store for regression
    reg_rank_onering = [reg_rank_onering; rank_all];
    reg_ratio_onering = [reg_ratio_onering; required_ratio_all];
end

%% ============================================================
% Main Loop - SV Model
%% ============================================================
fprintf('Simulating SV Model...\n');
for j = 1:length(sv_clusters)
    Ncl = sv_clusters(j);
    rank_all_sv = zeros(Num_sim,1);
    coherence_all_sv = zeros(Num_sim,1);
    required_ratio_all_sv = zeros(Num_sim,1);
    required_obs_all_sv = zeros(Num_sim,1);
    nmse_all_sv = zeros(Num_sim,1);
    
    for sim = 1:Num_sim
        [H,At,Ar] = generate_correlated_mmwave_channel(Nt,Nr,Ncl,Nray,10,fc,d_sv,1);
        
        s = svd(H,'econ');
        p = s/(sum(s)+eps);
        rank_all_sv(sim) = exp(-sum(p.*log(p+eps)));
        [~,~,coherence_all_sv(sim)] = sv_coherence_both(H);
        
        if j == 3
            sv_sv_matrix(:, sim) = s / max(s);
            rank_sv_vector(sim) = rank_all_sv(sim);
        end
        
        low_ratio = 0.05; high_ratio = 1;
        max_search_iter = 12; num_trials = 10;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio = (low_ratio+high_ratio)/2;
            successes = 0;
            for trial = 1:num_trials
                mask = rand(size(H)) < test_ratio;
                D = H.*mask;
                
                tau = 5 * max(Nr, Nt); delta = 1.2;
                [Xhat,~,~] = svt_matrix_completion(D, mask, 'tau', tau, 'delta', delta);
                
                nmse = norm(H-Xhat,'fro')^2 / (norm(H,'fro')^2 + eps);
                trial_nmse_list(trial) = nmse;
                if 10*log10(nmse) <= target_nmse_db
                    successes = successes+1;
                end
            end
            if (successes/num_trials) >= 0.7
                high_ratio = test_ratio;
            else
                low_ratio = test_ratio;
            end
            if abs(high_ratio-low_ratio)<0.01, break; end
        end
        required_ratio_all_sv(sim) = high_ratio;
        required_obs_all_sv(sim) = ceil(high_ratio*Nr*Nt);
        nmse_all_sv(sim) = mean(trial_nmse_list);
    end
    avg_rank_sv(j) = mean(rank_all_sv);
    avg_coherence_sv(j) = mean(coherence_all_sv);
    avg_required_ratio_sv(j) = mean(required_ratio_all_sv);
    avg_required_obs_sv(j) = round(mean(required_obs_all_sv));
    avg_nmse_sv(j) = 10*log10(mean(nmse_all_sv)+eps);
    
    % Store for regression
    reg_rank_sv = [reg_rank_sv; rank_all_sv];
    reg_ratio_sv = [reg_ratio_sv; required_ratio_all_sv];
end

%% ============================================================
% Main Loop - Weichselberger Model
%% ============================================================
fprintf('Simulating Weichselberger Model...\n');
for j = 1:length(weich_cases)
    rank_all_weich = zeros(Num_sim,1);
    coherence_all_weich = zeros(Num_sim,1);
    required_ratio_all_weich = zeros(Num_sim,1);
    required_obs_all_weich = zeros(Num_sim,1);
    nmse_all_weich = zeros(Num_sim,1);
    
    for sim = 1:Num_sim
        R = 4; 
        Ut = orth(randn(Nt,Nt) + 1i*randn(Nt,Nt));
        Ur = orth(randn(Nr,Nr) + 1i*randn(Nr,Nr));
        Omega = zeros(Nr, Nt);
        Omega(1:R, 1:R) = abs(randn(R,R));
        Omega = Omega / norm(Omega, 'fro') * sqrt(Nt*Nr);
        G = (randn(Nr,Nt) + 1j*randn(Nr,Nt))/sqrt(2);
        H_weich = Ur *(Omega .* G) * Ut';
        
        s = svd(H_weich,'econ');
        p = s/(sum(s)+eps);
        rank_all_weich(sim) = exp(-sum(p.*log(p+eps)));
        [~,~,coherence_all_weich(sim)] = sv_coherence_both(H_weich);
        
        if j == 1
            sv_weich_matrix(:, sim) = s / max(s);
            rank_weich_vector(sim) = rank_all_weich(sim);
        end
        
        low_ratio = 0.05; high_ratio = 1;
        max_search_iter = 12; num_trials = 10;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio=(low_ratio + high_ratio)/2;
            successes = 0;
            for trial = 1:num_trials
                mask = rand(size(H_weich)) < test_ratio;
                D = H_weich .* mask;
                
                tau = 5 * max(Nr, Nt); delta = 1.2;
                [Xhat,~,~] = svt_matrix_completion(D, mask, 'tau', tau, 'delta', delta);
                
                nmse = norm(H_weich-Xhat,'fro')^2 /(norm(H_weich,'fro')^2 + eps);
                trial_nmse_list(trial) = nmse;
                if 10*log10(nmse) <= target_nmse_db
                    successes = successes + 1;
                end
            end
            if (successes/num_trials) >= 0.7
                high_ratio = test_ratio;
            else
                low_ratio = test_ratio;
            end
            if abs(high_ratio-low_ratio) < 0.01, break; end
        end
        required_ratio_all_weich(sim) = high_ratio;
        required_obs_all_weich(sim) = ceil(high_ratio*Nr*Nt);
        nmse_all_weich(sim) = mean(trial_nmse_list);
    end
    avg_rank_weich(j) = mean(rank_all_weich);
    avg_coherence_weich(j) = mean(coherence_all_weich);
    avg_required_ratio_weich(j) = mean(required_ratio_all_weich);
    avg_required_obs_weich(j) = round(mean(required_obs_all_weich));
    avg_nmse_weich(j) = 10*log10(mean(nmse_all_weich)+eps);
    
    % Store for regression
    reg_rank_weich = [reg_rank_weich; rank_all_weich];
    reg_ratio_weich = [reg_ratio_weich; required_ratio_all_weich];
end

%% ============================================================
% REGRESSION ANALYSIS: Modelfitting Curve (Rank vs Required Pilot Ratio)
%% ============================================================
% Helper function for Quadratic Regression (y = beta0 + beta1*x + beta2*x^2)
calc_regression = @(x, y) deal([ones(size(x)), x, x.^2] \ y, ...
    1 - sum((y - ([ones(size(x)), x, x.^2] * ([ones(size(x)), x, x.^2] \ y))).^2) / sum((y - mean(y)).^2));

% Calculate for all 3 models
[beta_or, R2_or]       = calc_regression(reg_rank_onering, reg_ratio_onering);
[beta_sv, R2_sv]       = calc_regression(reg_rank_sv, reg_ratio_sv);
[beta_weich, R2_weich] = calc_regression(reg_rank_weich, reg_ratio_weich);

% Command Window Output
fprintf('\n==============================================================\n');
fprintf('     REGRESSION RESULTS (Required Pilot Ratio vs Eff. Rank)     \n');
fprintf('==============================================================\n');
fprintf('--- One-Ring Model ---\n');
fprintf('R²      = %.2f%%\n', R2_or * 100);
fprintf('Coeffs  : Int=%.4f, Linear=%.4f, Quad=%.4f\n\n', beta_or(1), beta_or(2), beta_or(3));

fprintf('--- Saleh-Valenzuela (SV) Model ---\n');
fprintf('R²      = %.2f%%\n', R2_sv * 100);
fprintf('Coeffs  : Int=%.4f, Linear=%.4f, Quad=%.4f\n\n', beta_sv(1), beta_sv(2), beta_sv(3));

fprintf('--- Weichselberger Model ---\n');
fprintf('R²      = %.2f%%\n', R2_weich * 100);
fprintf('Coeffs  : Int=%.4f, Linear=%.4f, Quad=%.4f\n', beta_weich(1), beta_weich(2), beta_weich(3));

%% ============================================================
% DIAGRAM 5: REGRESSION FITS (Modelfitting Style)
%% ============================================================
figure('Name', 'Regression Fit', 'Position', [100, 100, 1400, 450], 'Color', 'w');

% --- Helper for plotting curves ---
plot_fit = @(x, beta, color_code) plot(linspace(min(x), max(x), 100), ...
    [ones(100,1), linspace(min(x), max(x), 100)', linspace(min(x), max(x), 100)'.^2] * beta, ...
    'Color', color_code, 'LineWidth', 2.5);

% Subplot 1: One-Ring
subplot(1, 2, 1); hold on;
scatter(reg_rank_onering, reg_ratio_onering, 25, [0 0.447 0.741], 'filled', 'MarkerFaceAlpha', 0.5);
plot_fit(reg_rank_onering, beta_or, 'k');
xlabel('Effective Rank'); ylabel('Required Pilot Ratio');
title(sprintf('One-Ring Model (R² = %.2f%%)', R2_or * 100));
grid on; set(gca, 'FontName', 'Times', 'FontSize', 11);

% Subplot 2: SV
subplot(1, 2, 2); hold on;
scatter(reg_rank_sv, reg_ratio_sv, 25, [0.85 0.325 0.098], 'filled', 'MarkerFaceAlpha', 0.5);
plot_fit(reg_rank_sv, beta_sv, 'k');
xlabel('Effective Rank'); ylabel('Required Pilot Ratio');
title(sprintf('SV Model (R² = %.2f%%)', R2_sv * 100));
grid on; set(gca, 'FontName', 'Times', 'FontSize', 11);

% Subplot 3: Weichselberger
%%subplot(1, 3, 3); hold on;
%%scatter(reg_rank_weich, reg_ratio_weich, 25, [0.301 0.745 0.933], 'filled', 'MarkerFaceAlpha', 0.5);
%%plot_fit(reg_rank_weich, beta_weich, 'k');
%%xlabel('Effective Rank'); ylabel('Required Pilot Ratio');
%%title(sprintf('Weichselberger (R² = %.2f%%)', R2_weich * 100));
%%grid on; set(gca, 'FontName', 'Times', 'FontSize', 11);

%%exportgraphics(gcf, 'regression_pilot_vs_rank.pdf', 'ContentType', 'vector');

%% ============================================================
% Classic SVT Function Base Block (Helpers omitted for brevity, ensure they are attached)
%% ============================================================
function [X, err_history, rank_history] = svt_matrix_completion(D, mask, varargin)
    p = inputParser;
    addParameter(p, 'tau', [], @isnumeric);
    addParameter(p, 'delta', 1.2, @isnumeric);
    addParameter(p, 'max_iter', 200, @isnumeric);
    addParameter(p, 'tol', 1e-4, @isnumeric);
    parse(p, varargin{:});
    params = p.Results;

    [m, n] = size(D);
    if isempty(params.tau)
        params.tau = 5 * max(m, n);
    end

    D_obs = D;
    D_obs(~mask) = 0;
    norm_D_obs = norm(D_obs, 'fro');

    Y = zeros(m, n);
    X = zeros(m, n);
    err_history = zeros(params.max_iter, 1);
    rank_history = zeros(params.max_iter, 1);

    for k = 1:params.max_iter
        [U, S, V] = svd(Y, 'econ');
        S_thresh = max(S - params.tau, 0);
        r = sum(diag(S_thresh) > 0);
        X = U * S_thresh * V';
        
        Y = Y + params.delta * (D_obs - X.*mask);
        err = norm((X - D_obs).*mask, 'fro') / (norm_D_obs + eps);
        err_history(k) = err;
        rank_history(k) = r;
        
        if err < params.tol
            break;
        end
    end
    err_history = err_history(1:k);
    rank_history = rank_history(1:k);
end

% Note: Make sure to include the channel generator functions:
% `generate_onering_correlation`, `generate_correlated_mmwave_channel`, and `sv_coherence_both` 
% at the bottom of your script or in your path just like you had them before!
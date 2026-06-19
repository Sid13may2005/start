%% ONE-RING, SV, AND WEICHSELBERGER ANALYSIS VIA CLASSIC SVT
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
angular_spreads = [0.5 2 5 10 20 40 60];
d = 0.5;
mean_angle = 30;

sv_clusters = [1 2 3 5 8 10];
Nray = 3;
fc = 28e9;
d_sv = 0.5;

weich_cases = 1:4;
weich_case_names = {'1: Kronecker Equivalent', '2: Keyhole (Rank-1)', '3: Diagonal (LOS)', '4: Empirical Exp. Leakage'};

%% ============================================================
% Global Spectrum Storage (For ECDF Plots across all simulations)
%% ============================================================
% We capture the last configurations to build fair global distribution plots
sv_onering_matrix = zeros(minDim, Num_sim);
sv_weich_matrix = zeros(minDim, Num_sim);
sv_sv_matrix = zeros(minDim, Num_sim);

rank_onering_vector = zeros(Num_sim, 1);
rank_weich_vector = zeros(Num_sim, 1);
rank_sv_vector = zeros(Num_sim, 1);

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
        
        low_ratio = 0.05; high_ratio = 0.80;
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
end

%% ============================================================
% Main Loop - SV Model
%% ============================================================
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
        
        low_ratio = 0.05; high_ratio = 0.80;
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
end

%% ============================================================
% Main Loop - Weichselberger Model
%% ============================================================
for j = 1:length(weich_cases)
    current_case_id = weich_cases(j);
    rank_all_weich = zeros(Num_sim,1);
    coherence_all_weich = zeros(Num_sim,1);
    required_ratio_all_weich = zeros(Num_sim,1);
    required_obs_all_weich = zeros(Num_sim,1);
    nmse_all_weich = zeros(Num_sim,1);
    
    for sim = 1:Num_sim
        % Dynamic Weichselberger generation based on the 4 literature cases
        H_weich = generate_weichselberger_channel(Nr, Nt, current_case_id);
        
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
end

%% ============================================================
% Display Structured Tables
%% ============================================================
Results_onering = table(angular_spreads(:), avg_rank(:), avg_coherence(:), avg_required_ratio(:), avg_required_obs(:), avg_nmse(:), ...
    'VariableNames', {'AngularSpread_deg', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

Results_SV = table(sv_clusters(:), avg_rank_sv(:), avg_coherence_sv(:), avg_required_ratio_sv(:), avg_required_obs_sv(:), avg_nmse_sv(:), ...
    'VariableNames', {'NumClusters', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

% Updated Weichselberger Table mapping case IDs to descriptive literature names
Results_Weich = table(weich_case_names', avg_rank_weich(:), avg_coherence_weich(:), avg_required_ratio_weich(:), avg_required_obs_weich(:), avg_nmse_weich(:), ...
    'VariableNames', {'Literature_Scenario', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

fprintf('\n==============================================================\n');
fprintf('     COMPARATIVE RECOVERY ANALYSIS VIA CLASSIC SVT METHOD      \n');
fprintf('==============================================================\n');
disp('--- One-Ring Model ---'); disp(Results_onering);
disp('--- Saleh-Valenzuela (SV) Model ---'); disp(Results_SV);
disp('--- Weichselberger Model ---'); disp(Results_Weich);

%% ============================================================
% DIAGRAM 1: AVERAGE SINGULAR VALUE SPECTRUM (SVS)
%% ============================================================
x_idx = 1:minDim;
figure('Name', 'Singular Value Spectrum', 'Color', 'w'); hold on;
plot(x_idx, mean(sv_onering_matrix, 2), '--', 'LineWidth', 2.5, 'Color', [0 0.447 0.741]);
plot(x_idx, mean(sv_weich_matrix, 2), '-.', 'LineWidth', 2.5, 'Color', [0.301 0.745 0.933]);
plot(x_idx, mean(sv_sv_matrix, 2), '-', 'LineWidth', 2.5, 'Color', [0.85 0.325 0.098]);
grid on;
xlabel('Singular Value Index'); ylabel('Normalized Singular Value');
title('Average Singular Value Spectrum (SVS)');
legend({'Bessel Correlated (One-Ring)', 'Weichselberger Model', 'Saleh-Valenzuela (SV)'}, 'Location', 'northeast');
set(gca, 'FontName', 'Times', 'FontSize', 12, 'LineWidth', 1.2);
exportgraphics(gcf, 'singular_value_spectrum.pdf', 'ContentType', 'vector');

%% ============================================================
% DIAGRAM 2: ECDF OF ENTROPY-BASED EFFECTIVE RANK
%% ============================================================
figure('Name', 'ECDF Effective Rank', 'Color', 'w'); hold on;
[f1, x1] = ecdf(rank_onering_vector);
[f2, x2] = ecdf(rank_weich_vector);
[f3, x3] = ecdf(rank_sv_vector);
plot(x1, f1, '--', 'LineWidth', 2.5, 'Color', [0 0.447 0.741]);
plot(x2, f2, '-.', 'LineWidth', 2.5, 'Color', [0.301 0.745 0.933]);
plot(x3, f3, '-', 'LineWidth', 2.5, 'Color', [0.85 0.325 0.098]);
grid on;
xlabel('Effective Rank'); ylabel('F(x)');
title('ECDF of Entropy-Based Effective Rank');
legend({'Bessel Correlated (One-Ring)', 'Weichselberger Model', 'Saleh-Valenzuela (SV)'}, 'Location', 'southeast');
set(gca, 'FontName', 'Times', 'FontSize', 12, 'LineWidth', 1.2);
exportgraphics(gcf, 'ecdf_effective_rank.pdf', 'ContentType', 'vector');

%% ============================================================
% DIAGRAM 3: ECDF OF NORMALIZED SINGULAR VALUES
%% ============================================================
figure('Name', 'ECDF Singular Values', 'Color', 'w'); hold on;
[f1, x1] = ecdf(sv_onering_matrix(:));
[f2, x2] = ecdf(sv_weich_matrix(:));
[f3, x3] = ecdf(sv_sv_matrix(:));
plot(x1, f1, '--', 'LineWidth', 2.5, 'Color', [0 0.447 0.741]);
plot(x2, f2, '-.', 'LineWidth', 2.5, 'Color', [0.301 0.745 0.933]);
plot(x3, f3, '-', 'LineWidth', 2.5, 'Color', [0.85 0.325 0.098]);
grid on;
xlabel('Normalized Singular Value (\sigma / \sigma_{max})'); ylabel('F(x)');
title('ECDF of Normalized Singular Values');
legend({'Bessel Correlated (One-Ring)', 'Weichselberger Model', 'Saleh-Valenzuela (SV)'}, 'Location', 'southeast');
set(gca, 'FontName', 'Times', 'FontSize', 12, 'LineWidth', 1.2);
exportgraphics(gcf, 'ecdf_singular_values.pdf', 'ContentType', 'vector');

%% ============================================================
% Helper Function: Dynamic Weichselberger Generator
%% ============================================================
function H_wob = generate_weichselberger_channel(Nr, Nt, case_id)
    % Generate orthogonal spatial eigenbases for Rx and Tx
    Ur = orth(randn(Nr, Nr) + 1j*randn(Nr, Nr));
    Ut = orth(randn(Nt, Nt) + 1j*randn(Nt, Nt));
    Omega = zeros(Nr, Nt);
    
    switch case_id
        case 1 % Case 1: Kronecker Equivalent (Separable)
            pr = abs(randn(Nr, 1)); % Average power at Rx antennas
            pt = abs(randn(Nt, 1)); % Average power at Tx antennas
            Omega = pr * pt';       % Rank-1 outer product coupling
            
        case 2 % Case 2: Keyhole / Pinhole Channel (Severe Rank-1)
            Omega(1, 1) = 1;        % All energy bottlenecks through a single mode
            
        case 3 % Case 3: Diagonal Coupling (Strong LOS / Waveguide)
            minD = min(Nr, Nt);
            decay = exp(-0.5 * (0:minD-1)); 
            Omega(1:minD, 1:minD) = diag(decay); % Perfect matching between modes
            
        case 4 % Case 4: Empirical Exponential Leakage (Measured Indoor)
            [X, Y] = meshgrid(1:Nt, 1:Nr);
            Omega = exp(-0.5 * abs(X - Y));      % Energy leaks to off-diagonal
    end
    
    % Power normalize the coupling matrix
    Omega = Omega / norm(Omega, 'fro') * sqrt(Nt * Nr);
    
    % Assemble complex Gaussian fading matrix and couple
    G = (randn(Nr, Nt) + 1j*randn(Nr, Nt)) / sqrt(2);
    H_wob = Ur * (Omega .* G) * Ut';
end

%% ============================================================
% Matrix Completion Function via Classic SVT (tau, delta basis)
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
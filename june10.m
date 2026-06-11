%% MIMO CHANNEL MODELS: EFFECTIVE RANK, COHERENCE AND NMSE EVALUATION
clc;
clear;
close all;

%% ============================================================
% Global Parameters
%% ============================================================
Nr = 16;
Nt = 8;
Num_sim = 10;
target_nmse_db = -15;

%% ============================================================
% One-Ring Parameters
%% ============================================================
angular_spreads = [0.5 2 5 10 20 40 60];
d = 0.5;
mean_angle = 30;

%% ============================================================
% SV PARAMETERS
%% ============================================================
sv_clusters = [1 2 3 5 8 10];
Nray = 3;
fc = 28e9;
d_sv = 0.5;

%% ============================================================
% EXPONENTIAL MODEL PARAMETERS
%% ============================================================
rho_values = [0.1 0.3 0.5 0.7 0.9 0.99];
L = 3;
sigma_phi = 7;
d_exp = 0.5;

%% ============================================================
% WEICHSELBERGER PARAMETERS
%% ============================================================
weich_cases = 1:4;
avg_rank_weich = zeros(4,1);
avg_coherence_weich = zeros(4,1);
avg_required_ratio_weich = zeros(4,1);
avg_required_obs_weich = zeros(4,1);
avg_nmse_weich = zeros(4,1);

%% ============================================================
% Storage Arrays
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

avg_rank_exponential = zeros(length(rho_values),1);
avg_coherence_exponential = zeros(length(rho_values),1);
avg_required_ratio_exponential = zeros(length(rho_values),1);
avg_required_obs_exponential = zeros(length(rho_values),1);
avg_nmse_exponential = zeros(length(rho_values),1);

%% ============================================================
% Main Loop - One Ring Model
%% ============================================================
fprintf('Running One-Ring Model Simulation...\n');
for j = 1:length(angular_spreads)
    current_spread = angular_spreads(j);
    rank_all = zeros(Num_sim,1);
    coherence_all = zeros(Num_sim,1);
    required_ratio_all = zeros(Num_sim,1);
    required_obs_all = zeros(Num_sim,1);
    nmse_all = zeros(Num_sim,1); 
    
    for i = 1:Num_sim
        % Generate One-Ring Channel
        Rr = generate_onering_correlation(Nr, d, mean_angle, current_spread);
        Rt = generate_onering_correlation(Nt, d, mean_angle, current_spread);
        Hw = (randn(Nr,Nt) + 1j*randn(Nr,Nt))/sqrt(2);
        H_one_ring = sqrtm(Rr) * Hw * sqrtm(Rt);
        
        % Effective Rank
        s = svd(H_one_ring);
        p = s/(sum(s)+eps);
        rank_all(i) = exp(-sum(p.*log(p+eps)));
        
        % Coherence
        [~,~,coherence_all(i)] = sv_coherence_both(H_one_ring);
        
        % Binary Search for Minimum Pilot Ratio
        low_ratio = 0.05;
        high_ratio = 0.80; 
        max_search_iter = 12;
        num_trials = 20;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio = (low_ratio + high_ratio)/2;
            successes = 0;
            
            for trial = 1:num_trials
                mask = rand(size(H_one_ring)) < test_ratio;
                D = H_one_ring .* mask;
                [Xhat,~,~] = svt_matrix_completion(D,mask);
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
            if abs(high_ratio-low_ratio) < 0.01
                break;
            end
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
% Main Loop - Saleh-Valenzuela (SV) Model
%% ============================================================
fprintf('Running SV Model Simulation...\n');
for j = 1:length(sv_clusters)
    Ncl = sv_clusters(j);
    rank_all_sv = zeros(Num_sim,1);
    coherence_all_sv = zeros(Num_sim,1);
    required_ratio_all_sv = zeros(Num_sim,1);
    required_obs_all_sv = zeros(Num_sim,1);
    nmse_all_sv = zeros(Num_sim,1);
    
    for sim = 1:Num_sim
        [H,~,~] = generate_correlated_mmwave_channel(Nt,Nr,Ncl,Nray,10,fc,d_sv,1);
        
        s = svd(H,'econ');
        p = s/(sum(s)+eps);
        rank_all_sv(sim) = exp(-sum(p.*log(p+eps)));
        
        [~,~,coherence_all_sv(sim)] = sv_coherence_both(H);
        
        low_ratio = 0.05;
        high_ratio = 0.80;
        max_search_iter = 12;
        num_trials = 20;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio = (low_ratio+high_ratio)/2;
            successes = 0;
            for trial = 1:num_trials
                mask = rand(size(H)) < test_ratio;
                D = H.*mask;
                [Xhat,~,~] = svt_matrix_completion(D,mask);
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
            if abs(high_ratio-low_ratio)<0.01
                break;
            end
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
% Main Loop - Exponential Correlated Model
%% ============================================================
fprintf('Running Exponential Model Simulation...\n');
for j = 1:length(rho_values)
    rho_t = rho_values(j);
    rho_r = rho_values(j);
    rank_all_exp = zeros(Num_sim,1);
    coherence_all_exp = zeros(Num_sim,1);
    required_ratio_all_exp = zeros(Num_sim,1);
    required_obs_all_exp = zeros(Num_sim,1);
    nmse_all_exp = zeros(Num_sim,1);
    
    for sim = 1:Num_sim
        [H_exp,~,~] = generate_low_rank_mmwave_channel(Nr,Nt,L,sigma_phi,fc,d_exp,rho_t,rho_r);
        
        s = svd(H_exp,'econ');
        p = s/(sum(s)+eps);
        rank_all_exp(sim) = exp(-sum(p.*log(p+eps)));
        
        [~,~,coherence_all_exp(sim)] = sv_coherence_both(H_exp);
        
        low_ratio = 0.05;
        high_ratio = 0.80;
        max_search_iter = 12;
        num_trials = 20;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio = (low_ratio + high_ratio)/2;
            successes = 0;
            for trial = 1:num_trials
                mask = rand(size(H_exp)) < test_ratio;
                D = H_exp .* mask;
                [Xhat,~,~] = svt_matrix_completion(D,mask);
                nmse = norm(H_exp-Xhat,'fro')^2 / (norm(H_exp,'fro')^2 + eps);
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
            if abs(high_ratio-low_ratio) < 0.01
                break;
            end
        end
        required_ratio_all_exp(sim) = high_ratio;
        required_obs_all_exp(sim) = ceil(high_ratio*Nr*Nt);
        nmse_all_exp(sim) = mean(trial_nmse_list); 
    end
    avg_rank_exponential(j) = mean(rank_all_exp);
    avg_coherence_exponential(j) = mean(coherence_all_exp);
    avg_required_ratio_exponential(j) = mean(required_ratio_all_exp);
    avg_required_obs_exponential(j) = round(mean(required_obs_all_exp));
    avg_nmse_exponential(j) = 10*log10(mean(nmse_all_exp)+eps);
end

%% ============================================================
% Main Loop - Weichselberger Model (FIXED & CHANNELS ENFORCED LOW-RANK)
%% ============================================================
fprintf('Running Weichselberger Model Simulation...\n');
for j = 1:length(weich_cases)
    current_case = weich_cases(j);
    rank_all_weich = zeros(Num_sim,1);
    coherence_all_weich = zeros(Num_sim,1);
    required_ratio_all_weich = zeros(Num_sim,1);
    required_obs_all_weich = zeros(Num_sim,1);
    nmse_all_weich = zeros(Num_sim,1);
    
    for sim = 1:Num_sim
        rho_t_w = 0.7;
        rho_r_w = 0.6;
        R_t = zeros(Nt);
        for m = 1:Nt
            for n = 1:Nt
                R_t(m,n) = rho_t_w^(abs(m-n));
            end
        end
        R_r = zeros(Nr);
        for m = 1:Nr
            for n = 1:Nr
                R_r(m,n) = rho_r_w^(abs(m-n));
            end
        end
        
        [Ut,Lt] = eig(R_t);
        [Ur,Lr] = eig(R_r);
        [~,idx_t] = sort(diag(Lt),'descend');
        [~,idx_r] = sort(diag(Lr),'descend');
        Ut = Ut(:,idx_t);
        Ur = Ur(:,idx_r);
        
        switch current_case
            case 1
                % =====================================
                % Case 1: Exponential Diagonal Decay
                % (Sparsity is preserved, but energy leaks smoothly)
                % =====================================
                for r = 1:Nr
                    for t = 1:Nt
                        Omega_tilde(r,t) = 0.9^(abs(r-t)); 
                    end
                end
                
            case 2
                % =====================================
                % Case 2: Block/Clustered Energy
                % (Simulates energy concentrated in specific angular sub-spaces)
                % =====================================
                for r = 1:Nr
                    for t = 1:Nt
                        if r <= 4 && t <= 4
                            Omega_tilde(r,t) = 0.8;
                        elseif r > 12 && t > 4
                            Omega_tilde(r,t) = 0.6;
                        else
                            Omega_tilde(r,t) = 0.05;
                        end
                    end
                end
                
            case 3
                % =====================================
                % Case 3: Exponential Cross-Diagonal Decay
                % (Smooth version of your anti-diagonal case)
                % =====================================
                for r = 1:Nr
                    for t = 1:Nt
                        dist_to_antidiag = abs(r - (Nt - t + 1));
                        Omega_tilde(r,t) = 0.9^dist_to_antidiag;
                    end
                end
                
            case 4
                % =====================================
                % Case 4: Banded Diagonal Coupling
                % (Energy distributed in a wider, thick diagonal band)
                % =====================================
                for r = 1:Nr
                    for t = 1:Nt
                        if abs(r-t) <= 2
                            Omega_tilde(r,t) = 0.5;
                        else
                            Omega_tilde(r,t) = 0.05;
                        end
                    end
                end
        end
        
        Omega_tilde = Omega_tilde / norm(Omega_tilde,'fro') * sqrt(Nr*Nt);
        G = (randn(Nr,Nt) + 1j*randn(Nr,Nt))/sqrt(2);
        H_weich = Ur * (Omega_tilde .* G) * Ut';
        
        s = svd(H_weich,'econ');
        p = s/(sum(s)+eps);
        rank_all_weich(sim) = exp(-sum(p.*log(p+eps)));
        
        [~,~,coherence_all_weich(sim)] = sv_coherence_both(H_weich);
        
        % FIXED: Bound high_ratio to 0.80 to match structural bounds
        low_ratio = 0.05;
        high_ratio = 0.80; 
        max_search_iter = 12;
        num_trials = 20;
        trial_nmse_list = zeros(num_trials, 1);
        
        for search_iter = 1:max_search_iter
            test_ratio = (low_ratio + high_ratio)/2;
            successes = 0;
            for trial = 1:num_trials
                mask = rand(size(H_weich)) < test_ratio;
                D = H_weich .* mask;
                [Xhat,~,~] = svt_matrix_completion(D,mask);
                nmse = norm(H_weich-Xhat,'fro')^2 / (norm(H_weich,'fro')^2 + eps);
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
            if abs(high_ratio-low_ratio) < 0.01
                break;
            end
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
% Display Final Data Tables
%% ============================================================
Results_onering = table(angular_spreads(:), avg_rank(:), avg_coherence(:), avg_required_ratio(:), avg_required_obs(:), avg_nmse(:), ...
    'VariableNames', {'AngularSpread_deg', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

Results_SV = table(sv_clusters(:), avg_rank_sv(:), avg_coherence_sv(:), avg_required_ratio_sv(:), avg_required_obs_sv(:), avg_nmse_sv(:), ...
    'VariableNames', {'NumClusters', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

Results_Exp = table(rho_values(:), avg_rank_exponential(:), avg_coherence_exponential(:), avg_required_ratio_exponential(:), avg_required_obs_exponential(:), avg_nmse_exponential(:), ...
    'VariableNames', {'Rho', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

Results_Weich = table(weich_cases(:), avg_rank_weich(:), avg_coherence_weich(:), avg_required_ratio_weich(:), avg_required_obs_weich(:), avg_nmse_weich(:), ...
    'VariableNames', {'Scenario', 'EffectiveRank', 'Coherence', 'RequiredPilotRatio', 'RequiredObservations', 'Achieved_NMSE_dB'});

fprintf('\n=== SIMULATION RESULTS ===\n\n');
disp('--- One-Ring Model ---'); disp(Results_onering);
disp('--- Saleh-Valenzuela (SV) Model ---'); disp(Results_SV);
disp('--- Exponential Model ---'); disp(Results_Exp);
disp('--- Weichselberger Model ---'); disp(Results_Weich);

%% ============================================================
% Matrix Completion Function via SVT
%% ============================================================
function [X, err_history, rank_history] = svt_matrix_completion(D, mask, varargin)
    p = inputParser;
    addParameter(p, 'tau', [], @isnumeric);
    addParameter(p, 'delta', 1.2, @isnumeric);
    addParameter(p, 'max_iter', 200, @isnumeric);
    addParameter(p, 'tol', 1e-4, @isnumeric);
    addParameter(p, 'rank_estimate', [], @isnumeric);
    parse(p, varargin{:});
    params = p.Results;

    [m, n] = size(D);
    if isempty(params.tau)
        params.tau = 5*max(m,n);
    end
    if isempty(params.rank_estimate)
        params.rank_estimate = min(m,n);
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
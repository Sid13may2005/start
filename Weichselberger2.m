%
% Generate eigenbases (example: random unitary matrices)
Ur = orth(randn(Nr,Nr) + 1i*randn(Nr,Nr));
Ut = orth(randn(Nt,Nt) + 1i*randn(Nt,Nt));

% Case A: diagonal coupling (only same-mode coupling)
Omega_diag = eye(Nr,Nt);
H_diag = Ur * (Omega_diag .* (randn(Nr,Nt)+1i*randn(Nr,Nt))/sqrt(2)) * Ut';
% Case B: off-diagonal coupling (cross coupling)
Omega_cross = fliplr(eye(Nr,Nt));
H_cross = Ur * (Omega_cross .* (randn(Nr,Nt)+1i*randn(Nr,Nt))/sqrt(2)) * Ut';

% Check spatial correlation matrices
R_t_diag = H_diag' * H_diag;
R_t_cross = H_cross' * H_cross;
figure;
subplot(1,2,1); imagesc(abs(R_t_diag)); title('TX correlation – diagonal coupling');
subplot(1,2,2); imagesc(abs(R_t_cross)); title('TX correlation – cross coupling');
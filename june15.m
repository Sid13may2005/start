% Dimensions
Nt = 8; Nr = 6;
R = 4;                    % desired rank

% Generate random eigenbases (full rank)
Ut = orth(randn(Nt,Nt) + 1i*randn(Nt,Nt));
Ur = orth(randn(Nr,Nr) + 1i*randn(Nr,Nr));

% Build coupling matrix with exactly R active rows/columns
Omega = zeros(Nr, Nt);
% Choose any R x R positive matrix (e.g., random)
Omega(1:R, 1:R) = abs(randn(R,R));
% Optional: normalise to control total power
Omega = Omega / norm(Omega, 'fro') * sqrt(Nt*Nr);

% Generate one realisation
G = (randn(Nr,Nt) + 1i*randn(Nr,Nt)) / sqrt(2);
H = Ur * (Omega .* G) * Ut';

fprintf('Rank of H: %d\n', rank(H));
% Typically prints: Rank of H: 4
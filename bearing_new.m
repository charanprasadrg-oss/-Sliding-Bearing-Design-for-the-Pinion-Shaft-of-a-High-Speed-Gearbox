%% Sliding Bearing Design – Simple Hydrodynamic Analysis
% Computes minimum film thickness, flow rate, and power loss
% vs relative clearance for three bearing "types":
% Tilting Pad 5-pad, Offset Halves, Three-Lobe.
%
% This is a simplified classical journal-bearing model,
% good for demonstrating trends as in your slides.

clear; clc; close all;

%% Operating conditions (adapt these to your project)

load_kN = 16.2;           % bearing load [kN]
W       = load_kN * 1e3;  % [N]

n_rpm   = 15000;          % shaft speed [rpm]
omega   = 2*pi*n_rpm/60;  % [rad/s]

R       = 0.05;           % journal radius [m] (50 mm radius -> 100 mm dia)
L       = 0.05;           % bearing length [m] (L/D = 1 here, change if needed)

% Oil properties for ISO VG 32 (approx.)
rho     = 850;            % density [kg/m^3]
mu_40   = 0.032;          % dynamic viscosity at 40°C [Pa·s] (approx)

% Relative clearance range (C/R) to study
rel_clearance = [0.0020 0.0025 0.0030 0.0035 0.0040];   % 0.2%–0.4%

%% Bearing "type" factors
% These are simple correction factors to distinguish designs.
types = {'TiltingPad5','OffsetHalves','ThreeLobe'};

% Empirical factors (tune to approximate your results if needed)
K_flow   = [1.0,  0.8,  1.1];  % flow factor
K_power  = [1.1,  0.9,  1.0];  % power-loss factor
K_hmin   = [0.9,  1.1,  1.0];  % h_min factor

% Storage for results
results = struct();

%% Loop over each bearing type
for it = 1:numel(types)
    tname = types{it};
    kf    = K_flow(it);
    kp    = K_power(it);
    kh    = K_hmin(it);

    hmin_vec = zeros(size(rel_clearance));  % [m]
    Q_vec    = zeros(size(rel_clearance));  % [m^3/s]
    P_vec    = zeros(size(rel_clearance));  % [W]

    for i = 1:numel(rel_clearance)
        c_rel = rel_clearance(i);
        C     = c_rel * R;   % radial clearance [m]

        % SHORT-BEARING APPROXIMATION (classical theory)
        % 1) Eccentricity and minimum film thickness
        % For a loaded bearing, eccentricity ratio epsilon ~ 0.6–0.9.
        % Here we relate epsilon roughly to load and clearance:
        epsilon = min(0.95, max(0.5, 0.7 + 0.2*(0.003 - c_rel)/0.003));
        hmin    = C * (1 - epsilon);   % [m]
        hmin    = max(hmin, 1e-6);     % avoid zero

        % 2) Flow rate – classical estimate:
        % Poiseuille + Couette contributions, simplified:
        % Q ≈ (pi * R * C^3 / (6 * mu * L)) * p_avg    (very rough)
        % We'll instead use a dimensional approach:
        mu      = mu_40;   % use constant viscosity for simplicity
        p_avg   = W / (L * 2*R);   % average pressure [Pa]
        Q0      = (pi * R * C^3 * p_avg) / (6 * mu * L);  % [m^3/s]
        Q       = kf * Q0;

        % 3) Friction and power loss
        % Shear stress tau ~ mu * (U/h_mean),
        % U = R*omega, h_mean ~ C
        U       = R * omega;
        tau     = mu * U / C;
        A       = 2*pi*R*L;       % cylindrical area
        F_fric  = tau * A;        % friction force
        P0      = F_fric * U;     % [W]
        P_loss  = kp * P0;

        % Store
        hmin_vec(i) = kh * hmin;
        Q_vec(i)    = Q;
        P_vec(i)    = P_loss;
    end

    results.(tname).relC  = rel_clearance;
    results.(tname).hmin  = hmin_vec * 1e6;       % store in µm
    results.(tname).Q_lpm = Q_vec * 60 * 1e3;     % m^3/s -> L/min
    results.(tname).P_kW  = P_vec / 1e3;          % W -> kW
end

%% Plot: Power Loss vs Relative Clearance
figure;
hold on; grid on; box on;
for it = 1:numel(types)
    tname = types{it};
    plot(results.(tname).relC*100, results.(tname).P_kW, 'LineWidth', 2);
end
xlabel('Relative Clearance C/R (%)');
ylabel('Power Loss (kW)');
title('Power Loss vs Relative Clearance');
legend(types, 'Location', 'Best');

%% Plot: Lubricant Flow Rate vs Relative Clearance
figure;
hold on; grid on; box on;
for it = 1:numel(types)
    tname = types{it};
    plot(results.(tname).relC*100, results.(tname).Q_lpm, 'LineWidth', 2);
end
xlabel('Relative Clearance C/R (%)');
ylabel('Lubricant Flow Rate (L/min)');
title('Lubricant Flow Rate vs Relative Clearance');
legend(types, 'Location', 'Best');

%% Plot: Minimum Film Thickness vs Relative Clearance
figure;
hold on; grid on; box on;
for it = 1:numel(types)
    tname = types{it};
    plot(results.(tname).relC*100, results.(tname).hmin, 'LineWidth', 2);
end
xlabel('Relative Clearance C/R (%)');
ylabel('Minimum Film Thickness (µm)');
title('Minimum Film Thickness vs Relative Clearance');
legend(types, 'Location', 'Best');

%% Print example summary at a chosen clearance index
idx = 3;  % e.g., third clearance value
fprintf('Summary at relative clearance = %.4f:\n', rel_clearance(idx));
for it = 1:numel(types)
    tname = types{it};
    fprintf('  %s:\n', tname);
    fprintf('    h_min  = %.2f µm\n',  results.(tname).hmin(idx));
    fprintf('    Q      = %.2f L/min\n',results.(tname).Q_lpm(idx));
    fprintf('    P_loss = %.2f kW\n',  results.(tname).P_kW(idx));
end
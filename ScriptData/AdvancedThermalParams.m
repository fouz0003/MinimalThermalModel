% AdvancedThermalParams.m
% Parameters for the complete TES simulation model

% Thermal Energy Storage (TES) Parameters (e.g., molten salt or sand)
TES.volume = 50; % Volume of storage material in m^3
TES.density = 1800; % Density in kg/m^3 (typical for nitrate salts, adjust if sand)
TES.specificHeat = 1500; % Specific heat capacity in J/kg*K
TES.maxTemp = 650 + 273.15; % Maximum storage temperature in K (converted from Celsius)
TES.initialTemp = 20 + 273.15; % Initial storage temperature in K (e.g., 20°C)
TES.thermalCapacity = TES.volume * TES.density * TES.specificHeat; % Total thermal capacity in J/K

% Heat Exchanger (HX) Parameters
HX.surfaceArea = 100; % Heat exchange surface area in m^2
HX.U = 5;         % Overall heat transfer coefficient in W/m^2*K
HX.conductance = HX.U * HX.surfaceArea; % Thermal conductance in W/K

% Working Fluid Parameters (e.g., water or air for heat recovery)
fluid.flowRate = 0.1;  % Volumetric flow rate in m^3/s (adjust based on application)
fluid.Cp_water = 4180;   % Specific heat capacity of water in J/kg*K
fluid.density_water = 1000; % Density of water in kg/m^3
fluid.Cp_air = 1005;    % Specific heat capacity of air in J/kg*K
fluid.density_air = 1.2; % Density of air at standard conditions in kg/m^3
% Choose fluid type for simulation (e.g., water)
fluid.Cp = fluid.Cp_water;
fluid.density = fluid.density_water;
fluid.massFlowRate = fluid.flowRate * fluid.density; % Mass flow rate in kg/s

% Photovoltaic (PV) Source Parameters (Example)
PV.Pm = 355;  % Peak power of one panel in W
PV.Vm = 38.8; % Voltage at Pmax in V
PV.numPanels = 10; % Number of panels
PV.totalPower = PV.Pm * PV.numPanels; % Total peak power

% Ambient/Reference Temperature
referenceTemp = 20 + 273.15; % Ambient temperature in K (e.g., 20°C)

disp('AdvancedThermalParams.m loaded.');
disp(['TES Thermal Capacity: ', num2str(TES.thermalCapacity/1e6), ' MJ/K']); 
% MinimalThermalParams.m
% Simplified parameters for the minimal thermal model example

clear;

% Minimal TES Properties (e.g., a small block of material)
MinimalTES.mass = 10; % kg
MinimalTES.specificHeat = 900; % J/kg*K (e.g., Aluminium)
MinimalTES.initialTemp = 25 + 273.15; % Initial temperature in K (25 C)
MinimalTES.thermalCapacity = MinimalTES.mass * MinimalTES.specificHeat; % J/K

% Minimal Heat Source
MinimalHeat.power = 50; % Constant power input in W

% Ambient/Reference Temperature
minimalReferenceTemp = 20 + 273.15; % Ambient temperature in K (20 C)

disp('MinimalThermalParams.m loaded.');
disp(['Minimal TES Thermal Capacity: ', num2str(MinimalTES.thermalCapacity/1000), ' kJ/K']); 
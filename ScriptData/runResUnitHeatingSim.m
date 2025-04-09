% runResUnitHeatingSim.m
% Script to run the complete Residential Building TES and PV cell simulation
% 
% %% Description
% This script runs the complete Residential Building thermal simulation.
% It loads simulation parameters from AdvancedThermalParams.m, verifies the Simulink model's existence,
% configures simulation blocks (TES block, Heat Source, and Heat Exchanger) using set_param, and finally runs the simulation
% and plots the results.
% 
% %% Initialization
clear; clc; close all;

% Add paths if necessary (assuming scripts are in ScriptData and model in models)
% addpath('../ScriptData'); % Adjust if running from a different directory
% addpath('../models');

% 1. Load Parameters
% %% Load Advanced Simulation Parameters - loading parameters from AdvancedThermalParams.m
run('AdvancedThermalParams.m');

% 2. Define Model Name
mdl = 'ResidentialBuildingTESandPVcell'; % Just the model name
mdlPath = fullfile('models', [mdl, '.slx']); % Construct full path

% 3. Check if model exists and load it
% %% Model Verification and Loading - verifies if the Simulink model file exists
if ~isfile(mdlPath)
    warning('Simulink model file %s not found. Please create the model.', mdlPath);
    % Optionally create a blank model placeholder
    % new_system(mdl);
    % save_system(mdl, mdlPath);
    % disp(['Created a blank placeholder model: ', mdlPath]);
    return; % Stop script if model doesn't exist
end
load_system(mdlPath);
disp(['Loaded model: ', mdlPath]);

% 4. Configure Model Parameters using set_param
% %% Configure Model Blocks - updating block parameters for TES, Heat Source, and Heat Exchanger
try
    % Configure TES Block (assuming a Thermal Mass block inside a subsystem 'Sand_TES')
    tes_block_path = [mdl, '/Sand_TES/Thermal Mass'];
    set_param(tes_block_path, 'ThermalMass', num2str(TES.thermalCapacity), ...
                            'InitialTemperature', num2str(TES.initialTemp));
    disp(['Configured TES block: ', tes_block_path]);

    % Configure Heat Source (assuming a Controlled Heat Flow Rate Source)
    % This example uses a constant heat flow for simplicity.
    % Replace with PV model output or other variable source later.
    heat_source_path = [mdl, '/PV_to_TES/Heat Flow Rate Source']; 
    % Example fixed heat flow - replace with connection to PV model later
    simulated_heat_power = PV.totalPower * 0.5; % Example: 50% of peak power
    set_param(heat_source_path, 'Q', num2str(simulated_heat_power)); 
    disp(['Configured Heat Source block: ', heat_source_path, ' with fixed power ', num2str(simulated_heat_power), ' W']);

    % Configure Heat Exchanger (assuming Thermal Conduction block)
    hx_block_path = [mdl, '/Heat_Exchanger/Thermal Conductor']; 
    set_param(hx_block_path, 'ThermalConductance', num2str(HX.conductance));
    disp(['Configured Heat Exchanger block: ', hx_block_path]);
    
    % Configure Fluid Flow (assuming a Mass Flow Rate Source in the fluid loop)
    % This needs adjustment based on how you model the fluid loop (Simscape Fluids etc.)
    % fluid_flow_path = [mdl, '/Fluid_Loop/Mass Flow Rate Source'];
    % set_param(fluid_flow_path, 'mdot', num2str(fluid.massFlowRate));
    % disp(['Configured Fluid Flow block: ', fluid_flow_path]);

catch ME
    warning('Error configuring model parameters. Check block paths and names in %s. Error: %s', mdl, ME.message);
    close_system(mdl, 0); % Close model if configuration fails
    return;
end

% 5. Set Simulation Time
% %% Simulation Settings - Define simulation duration and related parameters
simStopTime = 24 * 3600; % Simulate for 24 hours in seconds
disp(['Setting simulation stop time to: ', num2str(simStopTime), ' s']);

% 6. Run Simulation
% %% Run Simulation and Post-Processing - runs simulation and processes logged data
try
    disp('Starting simulation...');
    simOut = sim(mdl, 'StopTime', num2str(simStopTime));
    disp('Simulation finished.');

    % 7. Process and Plot Results (Example: Plot TES Temperature)
    % Ensure you have added logging to your Simulink model for relevant signals.
    % Example: Logging the temperature signal from the Thermal Mass block with name 'StorageTemperature'
    if isfield(simOut, 'logsout') && ~isempty(simOut.logsout)
        logsout = simOut.get('logsout');
        if logsout.exist('StorageTemperature') % Check if the signal exists
            tempSignal = logsout.getElement('StorageTemperature').Values;
            
            figure;
            plot(tempSignal.Time, tempSignal.Data - 273.15, 'LineWidth', 1.5);
            xlabel('Time (s)');
            ylabel('Storage Temperature (°C)'); % Changed to Celsius for readability
            title('Evolution of TES Temperature');
            grid on;
            disp('Plotting TES temperature.');
        else
            warning('Signal ''StorageTemperature'' not found in simulation logs. Add logging to the TES block in Simulink.');
        end
    else
        warning('No simulation logs (logsout) found. Ensure signal logging is enabled in the model.');
    end

catch ME
    warning('Error during simulation or plotting: %s', ME.message);
end

% 8. Close the model without saving changes
disp('Closing Simulink model.');
close_system(mdl, 0); 
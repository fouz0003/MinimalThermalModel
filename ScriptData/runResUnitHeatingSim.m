% runResUnitHeatingSim.m
% Script to run the complete Residential Building TES and PV cell simulation
% 
% %% Description
% This script orchestrates the simulation of the more complex Residential Building model.
% It loads detailed parameters from AdvancedThermalParams.m, verifies the Simulink model's existence,
% configures key simulation blocks (TES, Heat Source, Heat Exchanger) using set_param,
% runs the simulation for a specified duration (e.g., 24 hours), and plots the resulting TES temperature.
% 
% %% Initialization
clear; clc; close all; % Standard MATLAB practice: clear workspace, command window, close figures

% Add paths if necessary (assuming scripts are in ScriptData and model in models)
% If you run this script from a different directory, uncomment and adjust these lines:
% addpath('../ScriptData'); 
% addpath('../models');

% 1. Load Advanced Parameters
% %% Load Advanced Simulation Parameters - loading parameters from AdvancedThermalParams.m
% Execute the parameter script to load variables representing the properties
% of the larger TES system, PV array, heat exchanger, and fluid loop (if applicable).
run('AdvancedThermalParams.m');
% Parameters now available include structs: TES, HX, fluid, PV.

% 2. Define Model Name and Path
% Store the model name and construct the full relative path to the .slx file.
mdl = 'ResidentialBuildingTESandPVcell'; % Simulink model file name
mdlPath = fullfile('models', [mdl, '.slx']); % Construct path relative to project root

% 3. Check if model exists and load it
% %% Model Verification and Loading - Ensures the required Simulink model file exists.
mdlPlaceholderPath = [mdlPath, '_to_generate_with_matlab'];
if ~isfile(mdlPath)
    if isfile(mdlPlaceholderPath)
        warning('Simulink model file %s not found. Please generate it from %s using MATLAB/Simulink.', mdlPath, mdlPlaceholderPath);
        disp('Refer to the README.md for step-by-step instructions on creating the residential building model.');
    else
        warning('Simulink model file %s not found, and placeholder is missing. Please create the model (see README.md).', mdlPath);
    end
    return; % Stop script if model doesn't exist
end
% Load the Simulink model into memory.
load_system(mdlPath);
disp(['Loaded model: ', mdlPath]);

% 4. Configure Model Parameters using set_param
% %% Configure Model Blocks - Dynamically update block parameters based on loaded values.
% This allows changing system properties (TES size, HX efficiency, PV power) 
% by modifying AdvancedThermalParams.m without editing the Simulink model directly.
try
    % Configure TES Block (assuming path 'ModelName/SubsystemName/BlockName')
    % Verify this path matches your model structure exactly.
    tes_block_path = [mdl, '/Sand_TES/Thermal Mass'];
    set_param(tes_block_path, 'ThermalMass', num2str(TES.thermalCapacity), ...
                            'InitialTemperature', num2str(TES.initialTemp));
    disp(['Configured TES block: ', tes_block_path, ' (Capacity: ', num2str(TES.thermalCapacity/1e6), ' MJ/K)']);

    % Configure Heat Source Block (assuming path 'ModelName/SubsystemName/BlockName')
    % IMPORTANT: This currently uses a SIMPLIFIED constant heat input based on PV peak power.
    % For a realistic simulation, this should be replaced with a variable heat flow 
    % signal derived from a proper PV model (considering irradiance, temperature effects).
    heat_source_path = [mdl, '/PV_to_TES/Heat Flow Rate Source']; 
    % Example: Using 50% of the total peak power as a constant input for demonstration.
    simulated_heat_power = PV.totalPower * 0.5; 
    set_param(heat_source_path, 'Q', num2str(simulated_heat_power)); 
    disp(['Configured Heat Source block: ', heat_source_path, ' with simplified fixed power ', num2str(simulated_heat_power), ' W']);

    % Configure Heat Exchanger Block (assuming path 'ModelName/SubsystemName/BlockName')
    % Assumes the HX is modeled as a simple thermal conductor.
    hx_block_path = [mdl, '/Heat_Exchanger/Thermal Conductor']; 
    % Set the thermal conductance (U*A) of the heat exchanger.
    set_param(hx_block_path, 'ThermalConductance', num2str(HX.conductance));
    disp(['Configured Heat Exchanger block: ', hx_block_path, ' (Conductance: ', num2str(HX.conductance), ' W/K)']);
    
    % --- Optional: Configure Fluid Flow --- 
    % If your model includes a Simscape Fluids loop, configure its source here.
    % Example assumes a Mass Flow Rate Source block.
    % Adjust the path and parameter name ('mdot') based on your specific implementation.
    % fluid_flow_path = [mdl, '/Fluid_Loop/Mass Flow Rate Source'];
    % set_param(fluid_flow_path, 'mdot', num2str(fluid.massFlowRate));
    % disp(['Configured Fluid Flow block: ', fluid_flow_path, ' (Mass Flow: ', num2str(fluid.massFlowRate), ' kg/s)']);

catch ME
    % Error handling: Provide specific feedback if configuration fails.
    warning('Error configuring model parameters. Check block paths and names in %s match your model structure exactly. Error: %s', mdl, ME.message);
    disp('Common issues: Typos in block/subsystem names, incorrect hierarchy in paths.');
    close_system(mdl, 0); % Close model if configuration fails
    return;
end

% 5. Set Simulation Time
% %% Simulation Settings - Define the total duration for the simulation run.
simStopTime = 24 * 3600; % Simulate for 24 hours (converted to seconds)
disp(['Setting simulation stop time to: ', num2str(simStopTime), ' s (', num2str(simStopTime/3600), ' hours)']);

% 6. Run Simulation
% %% Run Simulation and Post-Processing - Execute the simulation and process logged data.
try
    disp('Starting simulation...');
    % Execute the simulation using the 'sim' command.
    simOut = sim(mdl, 'StopTime', num2str(simStopTime));
    disp('Simulation finished.');

    % 7. Process and Plot Results (Example: Plot TES Temperature)
    % Access logged data from the simulation output.
    % Ensure signal logging is enabled in the Simulink model with the correct name.
    if isfield(simOut, 'logsout') && ~isempty(simOut.logsout)
        logsout = simOut.get('logsout');
        % Check if the 'StorageTemperature' signal was logged.
        if logsout.exist('StorageTemperature') 
            tempSignal = logsout.getElement('StorageTemperature').Values;
            
            % Create a new figure for plotting.
            figure;
            % Plot time (in seconds) vs. Storage Temperature (converted to Celsius).
            plot(tempSignal.Time, tempSignal.Data - 273.15, 'LineWidth', 1.5);
            xlabel('Time (s)');
            ylabel('Storage Temperature (°C)'); 
            title('Evolution of TES Temperature (Residential Model)');
            grid on;
            disp('Plotting TES temperature.');
        else
            % Warning if the expected signal is missing.
            warning('Signal ''StorageTemperature'' not found in simulation logs. Ensure logging is enabled for the TES Thermal Mass block with this exact name (see README.md).');
        end
    else
        % Warning if no logs were generated.
        warning('No simulation logs (logsout) found. Ensure signal logging is enabled in the model (see README.md).');
    end

catch ME
    % General error handling for simulation/plotting.
    warning('Error during simulation or plotting: %s', ME.message);
    disp('Refer to the Troubleshooting section in README.md');
end

% 8. Close the model without saving changes
% Clean up by closing the model from memory.
disp('Closing Simulink model.');
close_system(mdl, 0);
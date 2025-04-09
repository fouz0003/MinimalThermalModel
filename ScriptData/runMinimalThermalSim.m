% runMinimalThermalSim.m
% Script to run the minimal thermal model simulation
% 
% %% Description
% This script performs a minimal simulation of a thermal model.
% It loads parameters from MinimalThermalParams.m, verifies the existence of the minimal Simulink model,
% configures the simulation blocks (Thermal Mass and Heat Source), runs the simulation, and plots the temperature results.
% It also includes a theoretical check to compare the simulated final temperature with a calculated value.
% 
% THEORY OVERVIEW:
% ----------------
% This simulation demonstrates the fundamental principle of thermal energy storage:
% dQ = m * cp * dT, where:
% - dQ: Heat energy added/removed [J]
% - m: Mass of storage material [kg]
% - cp: Specific heat capacity [J/kg·K]
% - dT: Temperature change [K]
%
% For constant power input P over time t: dQ = P * t
% Therefore, the expected temperature rise: dT = (P * t) / (m * cp)
% 
% %% Initialization
clear; clc; close all; % Standard MATLAB practice: clear workspace, command window, close figures

% 1. Load Minimal Parameters
% %% Load Minimal Simulation Parameters - loading parameters from MinimalThermalParams.m
% Execute the parameter script to define variables (e.g., MinimalTES, MinimalHeat) in the base workspace.
% These variables represent the physical properties and inputs for the simulation.
run('MinimalThermalParams.m');
% Parameters now available include:
% - MinimalTES.mass: Mass of storage material [kg] -> 'm' in theory
% - MinimalTES.specificHeat: Specific heat capacity [J/kg·K] -> 'cp' in theory
% - MinimalTES.initialTemp: Initial temperature [K] -> 'Tinitial' in theory
% - MinimalTES.thermalCapacity: Calculated Thermal capacity (m*cp) [J/K]
% - MinimalHeat.power: Constant power input [W] -> 'P' in theory

% 2. Define Model Name and Path
% Store the model name and construct the full relative path to the .slx file.
% This makes the script robust to changes in the current directory, as long as
% it's run from the project root.
mdl = 'MinimalThermalModel'; % Simulink model file name (without .slx)
mdlPath = fullfile('models', 'minimal_example', [mdl, '.slx']); % Construct path relative to project root

% 3. Check if model exists and load it
% %% Model Verification and Loading - Ensures the required Simulink model file exists before proceeding.
% Check for the actual model file. If not found, check for the placeholder.
% Provide helpful instructions if the model needs to be created.
mdlPlaceholderPath = [mdlPath, '_to_generate_with_matlab'];
if ~isfile(mdlPath)
    if isfile(mdlPlaceholderPath)
        warning('Simulink model file %s not found. Please generate it from %s using MATLAB/Simulink.', mdlPath, mdlPlaceholderPath);
        disp('Refer to the README.md for step-by-step instructions on creating the minimal model.');
        % (Instructions previously here are now primarily in README)
    else
        warning('Simulink model file %s not found, and placeholder is missing. Please create the minimal model (see README.md).', mdlPath);
    end
    return; % Stop script execution if the model cannot be found
end
% Load the Simulink model into memory without opening the editor window.
load_system(mdlPath);
disp(['Loaded model: ', mdlPath]);

% 4. Configure Model Parameters using set_param
% %% Configure Simulation Blocks - Use set_param to programmatically update block parameters
% This section dynamically sets the parameters of the Simscape blocks based on the
% values loaded from MinimalThermalParams.m. This allows easy parameter sweeps
% without manually editing the Simulink model.
try
    % Construct the full block path within the model.
    % Format: 'ModelName/BlockName' or 'ModelName/Subsystem/BlockName'
    tes_block_path = [mdl, '/Thermal Mass'];
    % Set the 'ThermalMass' parameter (representing m*cp) and 'InitialTemperature'.
    % Note: Parameters are passed as strings to set_param.
    set_param(tes_block_path, 'ThermalMass', num2str(MinimalTES.thermalCapacity), ...
                            'InitialTemperature', num2str(MinimalTES.initialTemp));
    disp(['Configured TES block: ', tes_block_path]);
    disp(['  - Thermal capacity: ', num2str(MinimalTES.thermalCapacity), ' J/K']);
    disp(['  - Initial temperature: ', num2str(MinimalTES.initialTemp - 273.15), ' °C']); % Display in Celsius for readability

    % Configure the Heat Source block.
    heat_source_path = [mdl, '/Heat Source'];
    % Set the 'Q' parameter, representing the constant heat flow rate (Power) in Watts.
    set_param(heat_source_path, 'Q', num2str(MinimalHeat.power));
    disp(['Configured Heat Source block: ', heat_source_path]);
    disp(['  - Power input: ', num2str(MinimalHeat.power), ' W']);

catch ME
    % Error handling: If set_param fails (e.g., wrong block path/name), display a warning.
    warning('Error configuring model parameters. Check block paths/names in %s match the model. Error: %s', mdl, ME.message);
    disp('TROUBLESHOOTING: Ensure block names in the Simulink model are EXACTLY:');
    disp('  - "Thermal Mass"');
    disp('  - "Heat Source"');
    close_system(mdl, 0); % Close the model if configuration failed
    return;
end

% 5. Set Simulation Time
% %% Simulation Settings - Define the duration for the simulation run.
simStopTime = 60 * 60; % Simulate for 1 hour (converted to seconds)
disp(['Setting simulation stop time to: ', num2str(simStopTime), ' s (', num2str(simStopTime/3600), ' hour)']);

% 6. Run Simulation
% %% Run Simulation and Post-Processing - Execute the simulation and process the results.
try
    disp('Starting minimal simulation...');
    % Execute the simulation using the 'sim' command.
    % Pass the model name and simulation options (like 'StopTime').
    % The output 'simOut' contains simulation results, including logged signals.
    simOut = sim(mdl, 'StopTime', num2str(simStopTime));
    disp('Minimal simulation finished.');

    % 7. Process and Plot Results
    % Extract and visualize the logged temperature data.
    if isfield(simOut, 'logsout') && ~isempty(simOut.logsout)
        % 'logsout' is the default object containing logged signals.
        logsout = simOut.get('logsout');
        % Check if the specific signal we logged ('MinimalTemperature') exists.
        if logsout.exist('MinimalTemperature')
            % Access the logged signal data (a timeseries object).
            tempSignal = logsout.getElement('MinimalTemperature').Values;
            
            % Create a new figure for the plot.
            figure;
            % Plot time (converted to minutes) vs. temperature (converted to Celsius).
            plot(tempSignal.Time/60, tempSignal.Data - 273.15, 'LineWidth', 1.5);
            xlabel('Time (minutes)');
            ylabel('Temperature (°C)');
            title('Minimal Model Temperature Evolution');
            grid on;
            
            % --- Theoretical Check --- 
            % Calculate the expected final temperature based on the theoretical formula
            % This helps validate the simulation against the underlying physics.
            finalTemp_theoretical = MinimalTES.initialTemp + (MinimalHeat.power * simStopTime) / MinimalTES.thermalCapacity;
            hold on; % Add the theoretical point to the same plot.
            % Plot the theoretical final point as a red circle.
            plot(simStopTime/60, finalTemp_theoretical - 273.15, 'ro', 'MarkerSize', 8, 'DisplayName', 'Theoretical Final Temp (no loss)');
            legend('show'); % Display legend.
            disp('Plotting minimal model temperature.');
            % Display final temperatures in the command window for comparison.
            fprintf('Simulated Final Temp: %.2f °C\n', tempSignal.Data(end) - 273.15);
            fprintf('Theoretical Final Temp (no loss): %.2f °C\n', finalTemp_theoretical - 273.15);
            
            % Calculate and display the theoretical temperature rise rate (P / (m*cp)).
            temp_rise_rate = MinimalHeat.power / MinimalTES.thermalCapacity; % K/s
            fprintf('Theoretical temperature rise rate: %.4f °C/min\n', temp_rise_rate * 60); % Convert to °C/min
            
            % Add annotation to the plot displaying key simulation parameters.
            annotation('textbox', [0.15, 0.15, 0.3, 0.2], 'String', {...
                ['Mass: ' num2str(MinimalTES.mass) ' kg'], ...
                ['Specific Heat: ' num2str(MinimalTES.specificHeat) ' J/kg·K'], ...
                ['Power Input: ' num2str(MinimalHeat.power) ' W'], ...
                ['Thermal Capacity: ' num2str(MinimalTES.thermalCapacity/1000) ' kJ/K'], ...
                ['Rise Rate: ' num2str(temp_rise_rate * 60, '%.4f') ' °C/min']}, ...
                'EdgeColor', 'none', 'BackgroundColor', [0.95 0.95 0.95]);

        else
            % Error handling if the expected logged signal is missing.
            warning('Signal ''MinimalTemperature'' not found in logs. Ensure logging is enabled correctly in the Simulink model (see README.md).');
            % (Troubleshooting steps previously here are now primarily in README)
        end
    else
        % Error handling if no logsout object is found.
        warning('No simulation logs (logsout) found. Ensure signal logging is enabled in the minimal model (see README.md).');
    end

catch ME
    % General error handling during simulation or plotting.
    warning('Error during minimal simulation or plotting: %s', ME.message);
    disp('Refer to the Troubleshooting section in README.md');
end

% 8. Close the model
% Close the Simulink model from memory without saving any potential changes.
disp('Closing minimal model.');
close_system(mdl, 0);

% %% EXERCISE QUESTIONS FOR STUDENTS (from README)
% 1. How would doubling the thermal mass (mass or specific heat) affect the final temperature?
% 2. What happens if you increase the power input? Calculate the expected temperature rise.
% 3. Try modifying MinimalThermalParams.m to simulate different materials (copper, water, etc.)
% 4. If we added heat loss to the model, how would the temperature curve change?
% 5. Explain why the simulated and theoretical temperatures might differ in a real system (hint: losses). 
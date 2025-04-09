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
clear; clc; close all;

% 1. Load Minimal Parameters
% %% Load Minimal Simulation Parameters - loading parameters from MinimalThermalParams.m
% This loads all the thermal properties and initial conditions for our simulation
run('MinimalThermalParams.m');
% Parameters loaded include:
% - MinimalTES.mass: Mass of storage material [kg]
% - MinimalTES.specificHeat: Specific heat capacity [J/kg·K]
% - MinimalTES.initialTemp: Initial temperature [K]
% - MinimalTES.thermalCapacity: Thermal capacity (m*cp) [J/K]
% - MinimalHeat.power: Constant power input [W]

% 2. Define Model Name
mdl = 'MinimalThermalModel'; % Just the model name
mdlPath = fullfile('models', 'minimal_example', [mdl, '.slx']); % Construct full path

% 3. Check if model exists and load it
% %% Model Verification and Loading - check for model file existence, warn if missing
mdlPlaceholderPath = [mdlPath, '_to_generate_with_matlab'];
if ~isfile(mdlPath)
    if isfile(mdlPlaceholderPath)
        warning('Simulink model file %s not found. Please generate it from %s using MATLAB/Simulink.', mdlPath, mdlPlaceholderPath);
        disp('IMPORTANT: To create the minimal model, follow these steps:');
        disp('1. Open a new Simulink model');
        disp('2. Add these blocks from the Simscape library:');
        disp('   - Thermal Mass (Foundation Library > Thermal > Thermal Elements)');
        disp('   - Controlled Heat Flow Rate Source (Foundation Library > Thermal > Thermal Sources)');
        disp('   - Thermal Reference (Foundation Library > Thermal > Thermal Elements)');
        disp('   - Solver Configuration (Simscape > Utilities)');
        disp('3. Connect blocks: Heat Source positive port → Thermal Mass → Heat Source negative port → Thermal Reference');
        disp('4. Enable logging for the Thermal Mass temperature and name it "MinimalTemperature"');
        disp('5. Save as MinimalThermalModel.slx in the models/minimal_example/ directory');
    else
        warning('Simulink model file %s not found, and placeholder is missing. Please create the minimal model.', mdlPath);
    end
    return; % Stop script if model doesn't exist
end
load_system(mdlPath);
disp(['Loaded model: ', mdlPath]);

% 4. Configure Model Parameters (Update paths if needed)
% %% Configure Simulation Blocks - setting block parameters for Thermal Mass and Heat Source
try
    % Thermal Mass block represents a material with thermal storage capacity
    % Parameters: Thermal capacity [J/K] and Initial temperature [K]
    tes_block_path = [mdl, '/Thermal Mass']; % Adjust if it's inside a subsystem
    set_param(tes_block_path, 'ThermalMass', num2str(MinimalTES.thermalCapacity), ...
                            'InitialTemperature', num2str(MinimalTES.initialTemp));
    disp(['Configured TES block: ', tes_block_path]);
    disp(['  - Thermal capacity: ', num2str(MinimalTES.thermalCapacity), ' J/K']);
    disp(['  - Initial temperature: ', num2str(MinimalTES.initialTemp - 273.15), ' °C']);

    % Heat Flow Rate Source represents a constant power input
    % Parameter: Q [W] - positive means heat flowing into the system
    heat_source_path = [mdl, '/Heat Source']; % Adjust if needed
    set_param(heat_source_path, 'Q', num2str(MinimalHeat.power));
    disp(['Configured Heat Source block: ', heat_source_path]);
    disp(['  - Power input: ', num2str(MinimalHeat.power), ' W']);

catch ME
    warning('Error configuring model parameters. Check block paths/names in %s. Error: %s', mdl, ME.message);
    disp('TROUBLESHOOTING: Ensure that your blocks are named exactly as expected:');
    disp('  - "Thermal Mass" for the thermal mass block');
    disp('  - "Heat Source" for the heat flow rate source block');
    close_system(mdl, 0);
    return;
end

% 5. Set Simulation Time
% %% Simulation Settings - Define simulation duration (1 hour in seconds)
simStopTime = 60 * 60; % Simulate for 1 hour (3600 seconds)
disp(['Setting simulation stop time to: ', num2str(simStopTime), ' s (', num2str(simStopTime/3600), ' hour)']);

% 6. Run Simulation
% %% Run Simulation and Post-Processing - execute simulation and process results
try
    disp('Starting minimal simulation...');
    simOut = sim(mdl, 'StopTime', num2str(simStopTime));
    disp('Minimal simulation finished.');

    % 7. Process and Plot Results (Example: Plot Temperature)
    if isfield(simOut, 'logsout') && ~isempty(simOut.logsout)
        logsout = simOut.get('logsout');
        if logsout.exist('MinimalTemperature') % Ensure you log this signal in your minimal model
            tempSignal = logsout.getElement('MinimalTemperature').Values;
            
            figure;
            plot(tempSignal.Time/60, tempSignal.Data - 273.15, 'LineWidth', 1.5); % Convert time to minutes and temp to °C
            xlabel('Time (minutes)');
            ylabel('Temperature (°C)');
            title('Minimal Model Temperature Evolution');
            grid on;
            
            % Theoretical check (ignoring losses)
            % Using formula: T_final = T_initial + (P * t) / (m * cp)
            finalTemp_theoretical = MinimalTES.initialTemp + (MinimalHeat.power * simStopTime) / MinimalTES.thermalCapacity;
            hold on;
            plot(simStopTime/60, finalTemp_theoretical - 273.15, 'ro', 'MarkerSize', 8, 'DisplayName', 'Theoretical Final Temp (no loss)');
            legend('show');
            disp('Plotting minimal model temperature.');
            fprintf('Simulated Final Temp: %.2f °C\n', tempSignal.Data(end) - 273.15);
            fprintf('Theoretical Final Temp (no loss): %.2f °C\n', finalTemp_theoretical - 273.15);
            
            % Calculate and display temperature rise rate
            temp_rise_rate = MinimalHeat.power / MinimalTES.thermalCapacity; % K/s
            fprintf('Theoretical temperature rise rate: %.4f °C/min\n', temp_rise_rate * 60);
            
            % Add annotation with key parameters
            annotation('textbox', [0.15, 0.15, 0.3, 0.2], 'String', {...
                ['Mass: ' num2str(MinimalTES.mass) ' kg'], ...
                ['Specific Heat: ' num2str(MinimalTES.specificHeat) ' J/kg·K'], ...
                ['Power Input: ' num2str(MinimalHeat.power) ' W'], ...
                ['Thermal Capacity: ' num2str(MinimalTES.thermalCapacity/1000) ' kJ/K'], ...
                ['Rise Rate: ' num2str(temp_rise_rate * 60, '%.4f') ' °C/min']}, ...
                'EdgeColor', 'none', 'BackgroundColor', [0.95 0.95 0.95]);

        else
            warning('Signal ''MinimalTemperature'' not found in logs. Add logging to the Thermal Mass block in the minimal model.');
            disp('TROUBLESHOOTING: To enable logging:');
            disp('1. Right-click on the Thermal Mass port/node');
            disp('2. Select Properties and go to the Logging tab');
            disp('3. Check "Log simulation data"');
            disp('4. Set the logging name to "MinimalTemperature"');
        end
    else
        warning('No simulation logs (logsout) found. Ensure signal logging is enabled in the minimal model.');
        disp('TROUBLESHOOTING: Check if:');
        disp('1. Logging is enabled at the Simulink model level');
        disp('2. You have a Solver Configuration block in your model');
        disp('3. Signal logging is enabled for specific blocks of interest');
    end

catch ME
    warning('Error during minimal simulation or plotting: %s', ME.message);
    disp('TROUBLESHOOTING:');
    disp('- Ensure your model is correctly built with all required blocks');
    disp('- Check that all blocks are properly connected');
    disp('- Verify that parameter values are within reasonable ranges');
end

% 8. Close the model
disp('Closing minimal model.');
close_system(mdl, 0); 

% %% EXERCISE QUESTIONS FOR STUDENTS
% 1. How would doubling the thermal mass (mass or specific heat) affect the final temperature?
% 2. What happens if you increase the power input? Calculate the expected temperature rise.
% 3. Try modifying MinimalThermalParams.m to simulate different materials (copper, water, etc.)
% 4. If we added heat loss to the model, how would the temperature curve change?
% 5. Explain why the simulated and theoretical temperatures might differ. 
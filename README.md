# Thermal Energy Storage (TES) Simulation with Simscape

This project provides MATLAB scripts and Simulink/Simscape model placeholders for simulating a Thermal Energy Storage (TES) system, potentially coupled with a PV source and heat exchanger, based on the analysis of various research papers.

## Project Structure

```
Thermal-Energy-Storage/
  ├── ThermalEnergyStorageSimscape.prj_to_generate_with_matlab  (Placeholder - Create in MATLAB)
  ├── models/                                                  (Simulink models)
  │   ├── ResidentialBuildingTESandPVcell.slx_to_generate_with_matlab  (Placeholder - Create in Simulink)
  │   └── minimal_example/
  │         └── MinimalThermalModel.slx_to_generate_with_matlab         (Placeholder - Create in Simulink)
  ├── ScriptData/                                              (MATLAB scripts)
  │   ├── AdvancedThermalParams.m               (Parameters for full model)
  │   ├── MinimalThermalParams.m               (Parameters for minimal model)
  │   ├── runMinimalThermalSim.m               (Script to run minimal simulation)
  │   └── runResUnitHeatingSim.m               (Script to run full simulation)
  ├── Tests/                                                   (Unit tests)
  │     └── README.md                           (Placeholder for Test Directory)
  └── README.md                                                (This file)
```

## Thermal Energy Storage - Theory and Application

Thermal Energy Storage (TES) is a technology that stores thermal energy by heating or cooling a storage medium so that the stored energy can be used later for heating, cooling, or power generation applications. The core of this simulation relies on the principles of heat transfer.

### Key Thermal Energy Storage Principles:

1. **Basic Heat Transfer Equation**:
   ```
   Q = m × cp × ΔT
   ```
   Where:
   - Q = Heat energy transferred [J]
   - m = Mass of storage material [kg]
   - cp = Specific heat capacity [J/kg·K]
   - ΔT = Temperature change [K]

   **IMPORTANT**: This fundamental equation links energy (Q) to the material properties (mass `m`, specific heat `cp`) and the resulting temperature change (`ΔT`). The Simscape `Thermal Mass` block directly models this behavior.

2. **Temperature Rise Rate**:
   For a constant power (P) input:
   ```
   Rate of temperature rise = P / (m × cp) [K/s]
   ```

   **IMPORTANT**: This equation shows how quickly temperature rises when applying constant power (`P`). The term `(m × cp)` is the thermal capacity. A larger thermal capacity means the temperature rises more slowly for the same power input.

3. **Final Temperature Calculation**:
   For a constant power input over time (t):
   ```
   Tfinal = Tinitial + (P × t) / (m × cp)
   ```

   **IMPORTANT**: This allows predicting the final temperature (`Tfinal`) based on the initial temperature (`Tinitial`), applied power (`P`), duration (`t`), and the material's thermal capacity (`m × cp`). We use this for theoretical verification against simulation results.

## Getting Started: Building the Minimal Thermal Model (Step-by-Step)

This section provides detailed instructions for creating the minimal thermal model from scratch.

### Prerequisites

*   **MATLAB Version**: R2020a or newer
*   **Required Products**:
    *   Simulink
    *   Simscape
    *   Simscape Foundation Library (usually included with Simscape)
    *   MATLAB

### Part 1: Creating the Minimal Thermal Model

1. **Open MATLAB and Navigate to Project Directory**
   - Launch MATLAB
   - Use the 'Current Folder' browser to navigate to the `Thermal-Energy-Storage` directory
   - *(Optional)* Create a MATLAB project (`.prj` file) for easier management if you haven't already

2. **Create a New Simulink Model**
   - In MATLAB, navigate to the `models/minimal_example/` directory
   - Click `New` → `Simulink Model` (or type `simulink` in the Command Window and create a Blank Model)
   - Save the model as `MinimalThermalModel.slx` in the `models/minimal_example/` directory

3. **Add Required Simscape Blocks**
   - Open the Simulink Library Browser (Ctrl+Shift+L or the icon)
   - Navigate to `Simscape` → `Foundation Library` → `Thermal`

4. **Add and Configure the Thermal Mass Block**
   - Drag `Thermal Elements` → `Thermal Mass` into your model
   - **Purpose**: This block represents the physical object storing thermal energy. It directly implements the concept of thermal capacity (`m × cp`).
   - Position it centrally
   - Double-click to open parameters
   - Name it exactly `Thermal Mass` (this is crucial for the MATLAB script to find it)
   - Leave parameters like `Thermal mass` and `Initial temperature` as default for now; the script will set them

5. **Add and Configure the Heat Source**
   - Drag `Thermal Sources` → `Controlled Heat Flow Rate Source` into your model
   - **Purpose**: This block simulates the constant power (`P`) being added to the system, as described in the theory section
   - Position it to the left of the Thermal Mass
   - Name it exactly `Heat Source`
   - The script will set the heat flow rate (power)

6. **Add a Thermal Reference**
   - Drag `Thermal Elements` → `Thermal Reference` into your model
   - **Purpose**: This block provides the temperature reference point (like electrical ground). All thermal potentials (temperatures) are measured relative to this. It's essential for defining the thermal network
   - Position it below the Heat Source

7. **Add a Solver Configuration**
   - Navigate to `Simscape` → `Utilities` and drag `Solver Configuration` into your model
   - **Purpose**: This mandatory block defines how the Simscape physical network equations are solved numerically
   - Position it anywhere
   - Connect it to the circuit by right-clicking the block and selecting `Simscape` -> `Connect to Simscape Network`
   - Keep default solver settings (Simscape often uses appropriate variable-step solvers like `ode15s` automatically)

8. **Connect the Blocks**
   - Connect the positive port `+` (port `A`) of the `Heat Source` to the thermal port (port `A`) of the `Thermal Mass`. This directs the heat flow *into* the mass
   - Connect the negative port `-` (port `B`) of the `Heat Source` to the `Thermal Reference`. This completes the heat flow path
   - Ensure the `Solver Configuration` block is connected to the circuit (a dashed line should appear)

   **IMPORTANT NOTE**: Connections represent physical heat flow paths. Ensure ports are connected correctly (A to A, B to Reference)

   Your model should look something like this:
   ```
     +-------------+         +---------------+
     |             | A       A               |
     | Heat Source +---------> Thermal Mass  |
     |      B      |         |               |
     +------+------+         +---------------+
            |
            |
            v
     +-------------+         +-------------------+
     |  Thermal    |         | Solver            |
     |  Reference  |         | Configuration     | ---- (connected to circuit)
     +-------------+         +-------------------+
   ```

   ![Minimal Thermal Model Diagram](https://github.com/fouz0003/MinimalThermalModel/blob/main/medias/MinimalThermalModel.slx.png?raw=true)

9. **Enable Temperature Logging**
   - Right-click on the thermal port (connection point `A`) of the `Thermal Mass` block
   - Select `Simscape` -> `Log Simulation Data`
   - A `Simscape Logging` dialog appears. Ensure `Temperature` is checked
   - Set the `Logging name` to exactly `MinimalTemperature` (case-sensitive, crucial for the script)
   - Click `OK`

   **IMPORTANT NOTE**: Logging allows us to capture simulation data for analysis and plotting. The MATLAB script specifically looks for this logged signal by name

10. **Save the Model**
    - Save your model (`File` → `Save` or Ctrl+S)
    - Verify it is saved as `MinimalThermalModel.slx` in `models/minimal_example/`
    - You can delete the placeholder file `MinimalThermalModel.slx_to_generate_with_matlab` if it exists

### Part 2: Running the Minimal Thermal Simulation

1. **Open the Simulation Script**
   - In MATLAB, navigate to the `ScriptData` folder
   - Open `runMinimalThermalSim.m`. Review the comments explaining each step

2. **Review Simulation Parameters (Optional)**
   - Open `MinimalThermalParams.m`. This script defines the physical properties (`m`, `cp`), initial conditions (`Tinitial`), and input (`P`) used in the simulation
   - Default values: Mass = 10 kg, Specific heat = 900 J/kg·K, Initial Temp = 25°C, Heat input = 50 W
   - **Link to Theory**: These values directly correspond to `m`, `cp`, `Tinitial`, and `P` in the theoretical equations

3. **Run the Simulation**
   - Ensure your MATLAB 'Current Folder' is the root `Thermal-Energy-Storage` directory
   - Run `runMinimalThermalSim.m` by typing `runMinimalThermalSim` in the MATLAB Command Window or clicking the Run button in the editor
   - The script will:
     - Load parameters from `MinimalThermalParams.m`
     - Use `set_param` to configure the blocks in `MinimalThermalModel.slx`
     - Run the simulation for 1 hour (`simStopTime`)
     - Plot the logged `MinimalTemperature` signal
     - Perform the theoretical final temperature calculation for comparison

   **IMPORTANT NOTE**: If errors occur, check the MATLAB Command Window messages. Refer to the Troubleshooting section below

4. **Analyze the Results**
   - Examine the plot: Temperature should increase linearly from 25°C
   - Check the Command Window output: Compare the `Simulated Final Temp` with the `Theoretical Final Temp`. They should be very close in this ideal model
   - Note the `Theoretical temperature rise rate`

### Part 3: Expected Results and Learning Outcomes

**Expected Results:**
- Linear temperature rise from 25°C
- For the default parameters (50 W, 10 kg, 900 J/kg·K, 1 hour):
  - Thermal capacity `m × cp` = 9,000 J/K
  - Temp rise rate `P / (m × cp)` ≈ 0.0056 K/s ≈ 0.33 °C/min
  - Final temperature `Tfinal` ≈ 25°C + (0.33 °C/min × 60 min) ≈ 45°C

**Theoretical Calculations:**
(Repeated here for clarity)
1. Thermal capacity = 10 kg × 900 J/kg·K = 9,000 J/K
2. Temp rise rate = 50 W / 9,000 J/K ≈ 0.0056 K/s ≈ 0.33 °C/min
3. Total temp rise = 0.33 °C/min × 60 min ≈ 20 °C
4. Final temperature = 25°C + 20°C = 45°C

**IMPORTANT**: Verify your understanding by manually performing these calculations and comparing them to the script's output and the plot

**Learning Outcomes:**
- Connect theoretical heat transfer equations to Simscape blocks
- Understand how parameters (mass, specific heat, power) affect thermal behavior
- Implement basic thermal simulations in Simulink/Simscape
- Validate simulation results against theoretical predictions
- Develop foundational skills for more complex thermal modeling

### Part 4: Exercises and Extensions

Try these exercises to deepen your understanding:

1. **Parameter Variation:**
   - Modify `MinimalThermalParams.m` to double the mass or specific heat
   - Run the simulation again and observe how the temperature rise rate changes
   - Calculate the expected new temperature rise and compare with simulation
   
   **HINT**: Doubling the mass will halve the temperature rise rate

2. **Material Comparison:**
   - Change the specific heat to model different materials:
     - Water: ~4200 J/kg·K
     - Copper: ~385 J/kg·K
     - Concrete: ~880 J/kg·K
   - Compare how different materials store thermal energy
   
   **HINT**: Materials with higher specific heat can store more thermal energy per unit mass for the same temperature change

3. **Add Heat Loss:**
   - For more advanced students, modify the model to include heat loss to the environment
   - Add a `Thermal Conductor` block between the Thermal Mass and Thermal Reference
   - Set an appropriate thermal conductance value
   - Observe how the temperature curve changes from linear to exponential
   
   **HINT**: With heat loss, the temperature will rise more slowly and eventually reach equilibrium when heat input equals heat loss

4. **Variable Power Input:**
   - Replace the constant heat source with a variable one
   - Use a Simulink signal to control the heat flow (e.g., sinusoidal pattern)
   - Observe how the temperature responds to variable input
   
   **HINT**: You'll need to add a Simulink-PS converter block to convert a Simulink signal to a physical signal

## Creating the Full Residential Building Simulation Model

Follow these detailed steps to create the more complex residential building TES model (`ResidentialBuildingTESandPVcell.slx`):

1. **Create a New Simulink Model**
   - Navigate to the `models` directory
   - Create a new Simulink model, save it as `ResidentialBuildingTESandPVcell.slx`

2. **Organize Your Model with Subsystems (Recommended)**
   - Create subsystems for logical parts:
     - `Sand_TES`: Contains the main `Thermal Mass` for storage
     - `PV_to_TES`: Contains the `Controlled Heat Flow Rate Source` representing PV input
     - `Heat_Exchanger`: Contains a `Thermal Conductor` for heat transfer to load
     - *(Optional)* `Fluid_Loop`, `Building_Load` if modeling these explicitly

3. **Build the TES Subsystem (`Sand_TES`)**
   - Inside `Sand_TES`, add a `Thermal Mass` block. Name it exactly `Thermal Mass`
   - Add ports (using `Simscape` -> `Ports & Connections` -> `Connection Port`) for heat input and output

4. **Build the PV Heat Source (`PV_to_TES`)**
   - Inside `PV_to_TES`, add `Controlled Heat Flow Rate Source`. Name it `Heat Flow Rate Source`
   - Add ports for control signal (optional) and heat output

5. **Build the Heat Exchanger (`Heat_Exchanger`)**
   - Inside `Heat_Exchanger`, add `Thermal Conductor`. Name it `Thermal Conductor`
   - Add ports for connecting to TES and the load side

6. **Add Top-Level References and Configuration**
   - Add a `Thermal Reference` block at the top level
   - Add a `Solver Configuration` block and connect it

7. **Connect the Subsystems and References**
   - Wire the subsystems according to your intended heat flow path (PV -> TES -> HX)
   - Connect all necessary thermal reference points to the main `Thermal Reference`

8. **Enable Temperature Logging**
   - Inside `Sand_TES`, right-click the port of the `Thermal Mass`, enable logging (`Log Simulation Data`), and name the signal `StorageTemperature`

9. **Save Your Model**
   - Ensure block names inside subsystems match the paths used in `runResUnitHeatingSim.m` (e.g., `Sand_TES/Thermal Mass`)

   ![Residential Building TES Model Diagram](https://github.com/fouz0003/MinimalThermalModel/blob/main/medias/ResidentialBuildingTESandPVcell.slx.png?raw=true)

## Running the Full Residential Building Simulation

1. **Review Advanced Parameters**
   - Open `AdvancedThermalParams.m`. Note the larger scale (volume, density) and additional components (HX, fluid properties)

2. **Run the Full Simulation**:
   - Ensure MATLAB's 'Current Folder' is the project root
   - Run `runResUnitHeatingSim.m`
   - This script configures `ResidentialBuildingTESandPVcell.slx`, simulates 24 hours, and plots `StorageTemperature`

3. **Analyze the Results**
   - Observe the 24-hour temperature profile of the TES
   - Consider factors influencing the shape (charging/discharging cycles, potential losses if modeled)

## Troubleshooting Common Issues

If you encounter problems, check these common issues:

1. **Model Not Found Error**
   - **Check**: Is the `.slx` file saved with the exact name the script expects?
   - **Check**: Is the MATLAB 'Current Folder' set to the project root directory?
   - **Check**: Does the path in the script (`fullfile(...)`) correctly point to the model location?

2. **Block Configuration Error (`set_param` fails)**
   - **Check**: Do the block names inside your model *exactly* match the names used in the script (e.g., `Thermal Mass`, `Heat Source`)? Check for typos and case sensitivity
   - **Check**: If using subsystems, does the *full path* in the script match the hierarchy (e.g., `mdl/SubsystemName/BlockName`)?

3. **Logging Issues / No Plot Generated**
   - **Check**: Is signal logging enabled for the correct port (`Thermal Mass` temperature port)?
   - **Check**: Is the `Logging name` *exactly* `MinimalTemperature` or `StorageTemperature` (case-sensitive)?
   - **Check**: Look for warnings in the MATLAB Command Window about missing signals

4. **Simulation Errors (General)**
   - **Check**: Is the `Solver Configuration` block present and connected to the Simscape network?
   - **Check**: Is the `Thermal Reference` block present and connected correctly to complete the thermal circuit?
   - **Check**: Are all Simscape blocks properly connected (no dangling ports)?
   - **Check**: Are parameter values reasonable (e.g., positive mass, specific heat)?
   - **Check**: Are units consistent? While Simscape handles units, ensure inputs from MATLAB scripts have the expected base units (K for temperature, W for power, J/K for thermal mass, etc.)

5. **Unexpected Results (e.g., Temperature doesn't change, goes to infinity)**
   - **Check**: Review block connections carefully
   - **Check**: Verify parameter values loaded from the `.m` files
   - **Check**: Ensure the heat source is providing non-zero power
   - **Check**: Make sure the simulation `StopTime` is long enough to see changes

## Important Notes

*   **Block Paths:** Critical for `set_param`. If you rename blocks or subsystems, update the paths in the `.m` scripts
*   **Parameter Files:** `MinimalThermalParams.m` and `AdvancedThermalParams.m` control the physics. Modify them to experiment
*   **Signal Logging:** Essential for analysis. Ensure logged signals have the exact names the scripts expect

## Testing

The `Tests/` directory is for MATLAB Unit Tests (`.m` files using `matlab.unittest.TestCase`). Use this to create automated checks for your model or script logic. (See `Tests/README.md`)

## File Descriptions

*   `README.md`: This file - provides setup, theory, instructions, and troubleshooting
*   `models/minimal_example/MinimalThermalModel.slx` (To be created): Simple Simscape model with thermal mass and heat source
*   `models/ResidentialBuildingTESandPVcell.slx` (To be created): More complex model involving TES, PV source, and heat exchanger
*   `ScriptData/MinimalThermalParams.m`: MATLAB script defining parameters for the minimal model
*   `ScriptData/AdvancedThermalParams.m`: MATLAB script defining parameters for the full residential model
*   `ScriptData/runMinimalThermalSim.m`: MATLAB script to configure, run, and plot results for the minimal model
*   `ScriptData/runResUnitHeatingSim.m`: MATLAB script to configure, run, and plot results for the full residential model
*   `Tests/README.md`: Placeholder instructions for the testing directory
*   `*.slx_to_generate_with_matlab`: Placeholder text files indicating which models need to be created by the user
*   `*.prj_to_generate_with_matlab`: Placeholder text file indicating the MATLAB project file needs to be created

## Code Documentation

MATLAB scripts (`.m` files) contain comments explaining their purpose and specific steps. Review these scripts to understand how the simulation is controlled and configured

**Important Reminder:** Replace the `*_to_generate_with_matlab` placeholder files with actual `.slx` models and the `.prj` file as you follow the instructions. Ensure signal logging names match the scripts

  
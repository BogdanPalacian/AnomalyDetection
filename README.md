# Sensor Anomaly Detection System 🔍📊

A hybrid Python-VHDL implementation for detecting anomalies in temperature sensor data using the CUSUM algorithm. This project combines software analysis with hardware design to create a complete solution for sensor anomaly detection.

## Project Overview 📋

This project consists of two main parts:

1. **Python Implementation** - Handles data preprocessing, normalization, anomaly detection using CUSUM algorithm, and visualization of results
2. **VHDL Implementation** - Provides hardware implementation of the same algorithm using AXI4 streaming interfaces for real-time processing

The system is designed to process temperature readings from multiple sensors (DS18B20, DHT11, LM35DZ, BMP180, Thermistor, DHT22) and identify anomalous patterns that might indicate sensor failures or environmental changes.

## Features ✨

- Data normalization and preprocessing
- CUSUM algorithm implementation (both Python and VHDL)
- Anomaly detection and visualization
- Real-time hardware processing using AXI4 interfaces
- Customizable threshold and drift parameters
- Binary data conversion for hardware processing

## Setup Instructions 🛠️

### Software Requirements

- ✓ Python 3.7 or higher
- ✓ Required Python packages: matplotlib, numpy
- ✓ VHDL simulation environment (for hardware simulation)

### Installation Steps

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/sensor-anomaly-detection.git
   cd sensor-anomaly-detection
   ```

2. Install required Python packages:
   ```
   pip install matplotlib numpy
   ```

3. Place your sensor data file in the project directory (default expected file: "04-12-22_temperature_measurements.csv")

## Running the Software 🚀

### Python Implementation

1. Run the Python script:
   ```
   python sensor_data_anomalies.py
   ```

2. The script will:
   - Normalize the sensor data
   - Apply the CUSUM algorithm to detect anomalies
   - Create binary files for hardware processing
   - Generate visualizations for each sensor showing normal readings vs. anomalies
   - Create an anomaly file with labels "N" (normal) and "A" (anomaly)

### VHDL Implementation

1. Load the VHDL files into your preferred HDL simulation environment
2. Run the testbench file `TLM_tb.vhd` to simulate the hardware implementation
3. The testbench reads binary sensor data from files created by the Python script
4. Results are written to an output file for analysis

## Understanding the Results 📈

- The Python script generates plots for each sensor showing sensor readings over time
- Anomalies are marked in red on these plots
- The "AnomalyFile.csv" contains a classification of each data point as normal (N) or anomalous (A)
- The hardware implementation outputs a similar label for each data point

## Project Structure 📁

```
.
├── sensor_data_anomalies.py     # Python implementation of CUSUM algorithm
├── axi4_adder.vhd               # VHDL adder component with AXI4 interface
├── axi4_subtractor.vhd          # VHDL subtractor component
├── axi4_max_finder.vhd          # VHDL maximum finder component
├── axi4_threshold_processor.vhd # VHDL threshold processor
├── TLM.vhd                      # Top-level VHDL module
├── TLM_tb.vhd                   # Testbench for hardware verification
└── [Test files]                 # Various testbench files for individual components
```

## Customization ⚙️

You can adjust several parameters to customize the anomaly detection:
- In `sensor_data_anomalies.py`:
  - `threshold` - Threshold for flagging anomalies (default: 200)
  - `drift` - Drift parameter for CUSUM algorithm (default: 50)

- In VHDL implementation:
  - Modify the threshold and drift values in the testbench

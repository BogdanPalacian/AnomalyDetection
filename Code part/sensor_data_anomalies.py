import matplotlib.pyplot as plt

threshold = 200
drift = 50

def normalizeFileData():
    #original file
    file = open("04-12-22_temperature_measurements.csv", "r")

    #normalized file
    normalizedFile = open("04-12-22_temperature_measurements_normalized.csv", "w")

    lines = file.readlines()

    normalizedFile.write(lines[0])

    for line in lines[1:]:
        parts = line.strip().split(",")
        timestamp = parts[0]

        normalized_values = [str(round(float(value) * 100)) for value in parts[1:]]
        normalized_line = timestamp + "," + ",".join(normalized_values) + "\n"
        normalizedFile.write(normalized_line)

    file.close()
    normalizedFile.close()  


def cusum_alg(column, threshold, drift):
    s = [0] * len(column)        # Initialize the list 's' with zeroes
    gplus = [0] * len(column)    # Initialize the list 'gplus' with zeroes
    gminus = [0] * len(column)   # Initialize the list 'gminus' with zeroes
    tAbnormal = []               # Initialize the list 'tAbnormal' as an empty list

   
    for t in range(1, len(column)):
        value = column[t]
        prevVal = column[t-1]

        s[t] = value - prevVal
        gplus[t] = max(gplus[t-1] + s[t] - drift, 0)
        gminus[t] = max(gminus[t-1] - s[t] - drift, 0)
        
        if gplus[t] > threshold or gminus[t] > threshold:
            tAbnormal.append(t)
            gplus[t] = 0
            gminus[t] = 0
    
    return tAbnormal


def createAnomalyFile(abnormalMatrix):
    file = open("04-12-22_temperature_measurements_normalized.csv", "r")

    anomalyFile = open("AnomalyFile.csv", "w")

    lines = file.readlines()

    anomalyFile.write(lines[0])

    iText = 0
    
    iteratorRow = [0, 0, 0, 0, 0, 0]
    
    for line in lines[1:]:
        parts = line.strip().split(",")
        timestamp = parts[0]
        abnormalLine = timestamp
        j = 0
        for part in parts[1:]:
            if iteratorRow[j] < len(abnormalMatrix[j]) and abnormalMatrix[j][iteratorRow[j]] == iText:
                abnormalLine = abnormalLine + "," + "A"
                iteratorRow[j] = iteratorRow[j] + 1
            else:
                abnormalLine = abnormalLine + "," + "N"
            j = j + 1

        iText = iText + 1
        abnormalLine = abnormalLine + "\n"
        anomalyFile.write(abnormalLine)
    
    file.close()
    anomalyFile.close()


def generateColumnsAndDetectAnomalies():
    # Open the normalized file and read the values
    normalizedFile = open("04-12-22_temperature_measurements_normalized.csv", "r")
    lines = normalizedFile.readlines()
    
    # Initialize lists for each column
    columns = [[] for _ in range(6)]

    for line in lines[1:]:  # Skip the header line
        parts = line.strip().split(",")
        for i in range(6):
            columns[i].append(float(parts[i+1]))  # Append each value to its respective column list

    normalizedFile.close()
    
    # Apply the CUSUM algorithm to each column
    abnormalMatrix = []
    for column in columns:
        tAbnormal = cusum_alg(column, threshold, drift)
        abnormalMatrix.append(tAbnormal)

    # Create the anomaly file
    createAnomalyFile(abnormalMatrix)


def plot_anomalies():
    # Open the normalized file and read the values
    normalizedFile = open("04-12-22_temperature_measurements_normalized.csv", "r")
    lines = normalizedFile.readlines()
    normalizedFile.close()

    # Initialize lists for each column
    columns = [[] for _ in range(6)]
    timestamps = []

    for line in lines[1:]:  # Skip the header line
        parts = line.strip().split(",")
        timestamps.append(parts[0])
        for i in range(6):
            columns[i].append(float(parts[i + 1]))

    # Apply the CUSUM algorithm to each column to get the anomaly matrix
    abnormalMatrix = []
    for column in columns:
        tAbnormal = cusum_alg(column, threshold, drift)
        abnormalMatrix.append(tAbnormal)

    sensor_names = ["DS18B20", "DHT11", "LM35DZ", "BMP180", "Thermistor", "DHT22"]

    # Plot each column of data
    for i in range(6):
        plt.figure(figsize=(10, 5))

        # Plot all points in blue
        plt.plot(range(len(columns[i])), columns[i], 'b', label='Normal')

        # Plot abnormal points in red
        abnormal_indices = abnormalMatrix[i]
        abnormal_values = [columns[i][index] for index in abnormal_indices]
        plt.scatter(abnormal_indices, abnormal_values, color='red', label='Abnormal')

        plt.title(f'Sensor: {sensor_names[i]}')
        plt.xlabel('Measurement Number')
        plt.ylabel('Temperature (°C)')
        plt.legend()

        plt.show()



def createBinaryFiles():
    # Open the normalized file and read the values
    with open("04-12-22_temperature_measurements_normalized.csv", "r") as normalizedFile:
        lines = normalizedFile.readlines()

    # Initialize lists for each column
    columns = [[] for _ in range(6)]
    sensor_names = ["DS18B20", "DHT11", "LM35DZ", "BMP180", "Thermistor", "DHT22"]

    # Skip the header line and process the data
    for line in lines[1:]:
        parts = line.strip().split(",")
        for i in range(6):
            columns[i].append(float(parts[i + 1]))

    # Write each column's data to a separate file in binary form
    for i in range(6):
        # Find the maximum value and its binary length
        
        max_binary_length = 16

        # Open the output file for writing
        with open(f"{sensor_names[i]}_binary.csv", "w") as f:
            # Convert each value to binary, padded to the maximum length
            binary_values = [
                format(int(value), f'0{max_binary_length}b') for value in columns[i]
            ]
            # Write the padded binary values to the file
            for binary_value in binary_values:
                f.write(binary_value + "\n")



        




normalizeFileData()
generateColumnsAndDetectAnomalies()
createBinaryFiles()
plot_anomalies()

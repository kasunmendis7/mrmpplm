# Create CSV File
import os

folder = 'S:\\University\Research\\Undergraduate Research\MRMPPLM\Data-and-Logs\Experiment-Data\\fake-dirty\Experiments_2024-06-01_2\HBFDP(SHA1)_Enabled_Precopy_2024-06-01_1\\'


def Strip(str, char=" "):
    str = str.strip("\n")
    str = str.split(char)
    return str


for filename in os.listdir(folder):
    if filename.startswith("ram"):
        for exp in os.listdir(f"{folder}{filename}\\"):
            if exp.startswith("Experiment"):
                with open(f"./iperf/iperf_{filename}_{exp}.csv", 'w') as csv:
                    csv.write("Time,Bitrate\n")
                    with open(f'{folder}\\{filename}\\{exp}\\iperf_vm.log', 'r') as f:
                        lines = f.readlines()
                        # Check whether line contains a string pattern
                        for line in lines:
                            if "sec" in line:
                                line = Strip(line)
                                line = list(filter(None, line))
                                x = line[2].split("-")[1]
                                y = line[6]

                                if "Gbits/sec" in line[7]:
                                    y = float(y) * 1000

                                csv.write(f"{x},{y}\n")

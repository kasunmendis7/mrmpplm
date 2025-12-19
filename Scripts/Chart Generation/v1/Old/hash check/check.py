# Create CSV File
import json
import os

folder = input("Enter Folder Name : ") + '\\'


# Get the name of the txt files in directory
for filename in os.listdir(folder):
    if filename.startswith("output_mcd") and filename.endswith(".log"):

        with open(f'{folder}{filename}', 'r') as f:
            lines = f.readlines()
            # Check whether line contains a string pattern
            for line in lines:
                if ("HBFDP_SHA1 : Error Detected" in line) or ("NORMAL : Error Detected" in line):
                    print(filename)
                    print("Error Detected")

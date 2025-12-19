# Create CSV File
import json
import os

# folder = 'S:\\University\\Research\\Undergraduate Research\\MRMPPLM\\Data-and-Logs\\optimization (not considering)-Data\\fake-dirty\\experiment-workbench-data\\Quicksort_2024-06-10_1\\'
folder = 'S:\\University\\Research\\Undergraduate Research\\MRMPPLM\\Data-and-Logs\\Experiment-Data\\preliminary_2024-11-11_2\\vanilla_2024-11-11_1\\Quicksort_2024-11-11_1\\'

# Get the name of the txt files in directory
for optimization in os.listdir(folder):

    optimization_data = "Vanilla"
    workload_data = "Quicksort"

    for filename in os.listdir(f"{folder}"):

        if filename.startswith("ram") and filename.endswith("migration_status.log"):
            filename = filename.strip(".log")

            output_file = filename.split(".")[0].strip("ram")

            with open(f".\\data\\{optimization_data}\\{workload_data}\\{output_file}.csv", 'w') as csv:
                arr = []
                number = 0

                csv.write(
                    "Experiment,Iterations,Setup-Time,Downtime,Total-Time,Ram-Total,Ram-Postcopy-Requests,Ram-Dirty-Sync-Count,Ram-Remaining,Ram-Mbps,Ram-Transferred,Ram-Duplicate,Ram-Dirty-Pages-Rate,Ram-Skipped,Ram-Normal-Bytes,Ram-Normal,Total-Fake-Dirty-Pages,Outlier\n")

                with open(f'{folder}\\{filename}.log', 'r') as f:
                    lines = f.readlines()
                    # Check whether line contains a string pattern
                    for line in lines:
                        if "No:" in line:
                            number = line.strip("\n").split(": ")[1]
                        elif "completed" in line:
                            line = json.loads(line.strip("\n").replace("'", "\""))
                            arr.append(number)
                            arr.append(line["return"]["iterations"])
                            arr.append(line["return"]["setup-time"])
                            arr.append(line["return"]["downtime"])
                            arr.append(line["return"]["total-time"])
                            arr.append(line["return"]["ram"]["total"])
                            arr.append(line["return"]["ram"]["postcopy-requests"])
                            arr.append(line["return"]["ram"]["dirty-sync-count"])
                            arr.append(line["return"]["ram"]["remaining"])
                            arr.append(line["return"]["ram"]["mbps"])
                            arr.append(line["return"]["ram"]["transferred"])
                            arr.append(line["return"]["ram"]["duplicate"])
                            arr.append(line["return"]["ram"]["dirty-pages-rate"])
                            arr.append(line["return"]["ram"]["skipped"])
                            arr.append(line["return"]["ram"]["normal-bytes"])
                            arr.append(line["return"]["ram"]["normal"])

                            fd_count = 0
                            for count in range(0, len(line["return"]["fake-dirty"])):
                                fd_count += line["return"]["fake-dirty"][count]
                            arr.append(fd_count)

                            arr.append("No")

                            # Write all the items in arr array to CSV file
                            count = 1
                            for item in arr:
                                csv.write(f"{item}")
                                if count != 18:
                                    csv.write(",")
                                count += 1

                            csv.write("\n")

                            arr = []
                        elif "------------------------------------------------------" in line:
                            continue

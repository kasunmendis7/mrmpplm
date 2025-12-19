# Create CSV File
import json
import os

folder = 'S:\\University\\Research\\Undergraduate Research\\MRMPPLM\\Data-and-Logs\\Experiment-Data\\v2\\migration-performance\\gap-fill-data\\downtime_2025-05-02_1'

# Get the name of the txt files in directory
for workload in os.listdir(f"{folder}"):
    workload_data = workload.split("_")[0]

    for optimization in os.listdir(f"{folder}\\{workload}"):

        optimization_data = ""

        if "Vanilla_PreCopy" in optimization:
            optimization_data = "Vanilla"
        elif "HBFDP_PreCopy" in optimization:
            if "SHA1" in optimization:
                optimization_data = "HBFDP_SHA1"
            elif "MD5" in optimization:
                optimization_data = "HBFDP_MD5"
            elif "Murmur3" in optimization:
                optimization_data = "HBFDP_Murmur3"
        elif "HBFDP_XBZRLE_PreCopy" in optimization:
            if "SHA1" in optimization:
                optimization_data = "XBZRLE_HBFDP_SHA1"
            elif "MD5" in optimization:
                optimization_data = "XBZRLE_HBFDP_MD5"
            elif "Murmur3" in optimization:
                optimization_data = "XBZRLE_HBFDP_Murmur3"
        elif "Dtrack_XBZRLE_PreCopy" in optimization:
            optimization_data = "XBZRLE_Dtrack"
        elif "XBZRLE_PreCopy" in optimization:
            optimization_data = "XBZRLE"
        elif "HBFDP_Compress_PreCopy" in optimization:
            if "SHA1" in optimization:
                optimization_data = "Compress_HBFDP_SHA1"
            elif "MD5" in optimization:
                optimization_data = "Compress_HBFDP_MD5"
            elif "Murmur3" in optimization:
                optimization_data = "Compress_HBFDP_Murmur3"
        elif "Dtrack_Compress_PreCopy" in optimization:
            optimization_data = "Compress_Dtrack"
        elif "Compress_PreCopy" in optimization:
            optimization_data = "Compress"
        elif "Dtrack_PreCopy" in optimization:
            optimization_data = "Dtrack"

        if optimization_data == "":
            continue

        for filename in os.listdir(f"{folder}\\{workload}\\{optimization}"):

            if filename.startswith("ram") and filename.endswith("migration_status.log"):
                filename = filename.strip(".log")

                output_file = f'{filename.split(".")[0].strip("ram")}'

                if os.path.exists(f".\\data\\{optimization_data}\\{workload_data}\\{output_file}.csv"):
                    continue

                with open(f".\\data\\{optimization_data}\\{workload_data}\\{output_file}.csv", 'w') as csv:
                    arr = []
                    number = 0

                    csv.write("Experiment,Outlier,Iterations,Setup-Time,Downtime,Total-Time,Ram-Total,Ram-Postcopy-Requests,Ram-Dirty-Sync-Count,Ram-Remaining,Ram-Mbps,Ram-Transferred,Ram-Duplicate,Ram-Dirty-Pages-Rate,Ram-Skipped,Ram-Normal-Bytes,Ram-Normal,Total-Fake-Dirty-Pages,Total-Transferred-Page-Count\n")

                    with open(f'{folder}\\{workload}\\{optimization}\\{filename}.log', 'r') as f:
                        lines = f.readlines()
                        # Check whether line contains a string pattern
                        for line in lines:
                            if "No:" in line:
                                number = line.strip("\n").split(": ")[1]
                            elif "completed" in line:
                                line = json.loads(line.strip("\n").replace("'", "\""))
                                arr.append(number)
                                arr.append("Yes")
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

                                pg_count = 0
                                for count in range(0, len(line["return"]["page-count"])):
                                    pg_count += line["return"]["page-count"][count]
                                arr.append(pg_count)

                                # Write all the items in arr array to CSV file
                                count = 1
                                for item in arr:
                                    csv.write(f"{item}")
                                    if count != 19:
                                        csv.write(",")
                                    count += 1

                                csv.write("\n")

                                arr = []
                            elif "------------------------------------------------------" in line:
                                continue
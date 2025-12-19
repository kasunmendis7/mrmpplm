# Create CSV File
import json
import os

folder = 'S:\\University\\Research\\Undergraduate Research\\MRMPPLM\\Data-and-Logs\\Experiment-Data\\dtrack_2025-02-16_1\\'

# Get the name of the txt files in directory
for optimization in os.listdir(folder):

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
    elif "XBZRLE_PreCopy" in optimization:
        optimization_data = "XBZRLE"
    elif "HBFDP_Compress_PreCopy" in optimization:
        if "SHA1" in optimization:
            optimization_data = "Compress_HBFDP_SHA1"
        elif "MD5" in optimization:
            optimization_data = "Compress_HBFDP_MD5"
        elif "Murmur3" in optimization:
            optimization_data = "Compress_HBFDP_Murmur3"
    elif "Compress_PreCopy" in optimization:
        optimization_data = "Compress"
    elif "Dtrack" in optimization:
        optimization_data = "Dtrack"

    if optimization_data == "":
        continue

    for workload in os.listdir(f"{folder}\\{optimization}"):

        workload_data = workload.split("_")[0]

        for filename in os.listdir(f"{folder}\\{optimization}\\{workload}"):

            if filename.startswith("ram") and filename.endswith("migration_status.log"):
                filename = filename.strip(".log")

                output_file = filename.split(".")[0].strip("ram")

                with open(f".\\data\\{optimization_data}\\{workload_data}\\{output_file}.csv", 'w') as csv:
                    arr = []
                    number = 0

                    csv.write(
                        "Experiment,Outlier,Iterations,Setup-Time,Downtime,Total-Time,Ram-Total,Ram-Postcopy-Requests,Ram-Dirty-Sync-Count,Ram-Remaining,Ram-Mbps,Ram-Transferred,Ram-Duplicate,Ram-Dirty-Pages-Rate,Ram-Skipped,Ram-Normal-Bytes,Ram-Normal,Total-Fake-Dirty-Pages,Total-Transferred-Page-Count\n")

                    with open(f'{folder}\\{optimization}\\{workload}\\{filename}.log', 'r') as f:
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
#
# pg = {
#     "Vanilla": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "XBZRLE": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "Compress": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "HBFDP_SHA1": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "HBFDP_MD5": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "HBFDP_Murmur3": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "XBZRLE_HBFDP_SHA1": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "XBZRLE_HBFDP_MD5": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     },
#     "XBZRLE_HBFDP_Murmur3": {
#         "1024": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "2048": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "4096": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "8192": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "12288": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
#         "16384": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#     }
# }
#
# for optimization in os.listdir(folder):
#
#     optimization_data = ""
#
#     if "Vanilla_PreCopy" in optimization:
#         optimization_data = "Vanilla"
#     elif "HBFDP_PreCopy" in optimization:
#         if "SHA1" in optimization:
#             optimization_data = "HBFDP_SHA1"
#         elif "MD5" in optimization:
#             optimization_data = "HBFDP_MD5"
#         elif "Murmur3" in optimization:
#             optimization_data = "HBFDP_Murmur3"
#     elif "HBFDP_XBZRLE_PreCopy" in optimization:
#         if "SHA1" in optimization:
#             optimization_data = "XBZRLE_HBFDP_SHA1"
#         elif "MD5" in optimization:
#             optimization_data = "XBZRLE_HBFDP_MD5"
#         elif "Murmur3" in optimization:
#             optimization_data = "XBZRLE_HBFDP_Murmur3"
#     elif "XBZRLE_PreCopy" in optimization:
#         optimization_data = "XBZRLE"
#     # elif "HBFDP_Compress_PreCopy" in optimization:
#     #     if "SHA1" in optimization:
#     #         optimization_data = "Compress_HBFDP_SHA1"
#     #     elif "MD5" in optimization:
#     #         optimization_data = "Compress_HBFDP_MD5"
#     #     elif "Murmur3" in optimization:
#     #         optimization_data = "Compress_HBFDP_Murmur3"
#     elif "Compress_PreCopy" in optimization:
#         optimization_data = "Compress"
#
#     if optimization_data == "":
#         continue
#
#     for workload in os.listdir(f"{folder}\\{optimization}"):
#
#         workload_data = workload.split("_")[0]
#
#         for filename in os.listdir(f"{folder}\\{optimization}\\{workload}"):
#
#             if filename.startswith("ram") and filename.endswith("migration_status.log"):
#                 filename = filename.strip(".log")
#
#                 output_file = filename.split(".")[0].strip("ram")
#
#                 d_count = 0
#
#                 with open(f'{folder}\\{optimization}\\{workload}\\{filename}.log', 'r') as f:
#                     lines = f.readlines()
#                     # Check whether line contains a string pattern
#                     for line in lines:
#                         if "No:" in line:
#                             number = line.strip("\n").split(": ")[1]
#                         elif "completed" in line:
#                             line = json.loads(line.strip("\n").replace("'", "\""))
#
#                             page_count = 0
#                             for count in range(0, len(line["return"]["page-count"])):
#                                 page_count += line["return"]["page-count"][count]
#
#                             pg[optimization_data][output_file][d_count] = page_count
#                             d_count += 1
#
#                             arr = []
#                         elif "------------------------------------------------------" in line:
#                             continue
#
# optimizations = ['XBZRLE', 'Compress', 'HBFDP_SHA1', 'HBFDP_MD5', 'HBFDP_Murmur3', 'XBZRLE_HBFDP_SHA1',
#                  'XBZRLE_HBFDP_MD5', 'XBZRLE_HBFDP_Murmur3']
# # optimizations = ['Vanilla']
# workloads = ['Memcached']
# rams = [1, 2, 4, 8, 12, 16]
# # rams = [1, 2, 4, 8]
#
# for optimization in optimizations:
#
#     for workload in workloads:
#
#         for ram in rams:
#             ram_mb = str(ram * 1024)
#
#             if not os.path.exists(f".\\data\\{optimization}\\{workload}\\{ram_mb}.csv"):
#                 continue
#
#             with open(f".\\data\\{optimization}\\{workload}\\{ram_mb}.csv", 'r+') as f:
#
#                 lines = f.readlines()  # Read all lines
#                 f.seek(0)
#
#                 d_count = 0
#                 for line in lines:
#
#                     initial = line.strip("\n")
#                     f.write(f"{initial},")
#                     if "Experiment" in line:
#                         f.write(f"Total-Transferred-Page-Count\n")
#                     else:
#                         f.write(f"{pg[optimization][ram_mb][d_count]}\n")
#                         d_count += 1

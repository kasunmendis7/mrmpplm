# # Create CSV File
# import json
# import os
#
# folder = input("Enter Folder Name : ") + '\\'
#
#
# def get_cpu_usage(mcd, experiment):
#     cpu = []
#     with open(f'{folder}mcd{mcd}\\Experiment{experiment}\cpu_usage.log', 'r') as log:
#         log_lines = log.readlines()
#         for log_line in log_lines:
#             if "all" in log_line:
#                 log_line = log_line.strip("\n")
#                 log_line = log_line.split(" ")
#                 log_line = list(filter(None, log_line))
#                 cpu.append({"USR": log_line[2], "SYS": log_line[4]})
#         return cpu
#
#
# def get_mem_usage(mcd, experiment):
#     mem = []
#     with open(f'{folder}mcd{mcd}\\Experiment{experiment}\mem_usage.log', 'r') as log:
#         log_lines = log.readlines()
#         for log_line in log_lines:
#             if "Mem:" in log_line:
#                 log_line = log_line.strip("\n")
#                 log_line = log_line.split(" ")
#                 log_line = list(filter(None, log_line))
#                 mem.append(log_line[2])
#         return mem
#
#
# def get_net_usage(mcd, experiment):
#     net = []
#     keys = ["Time", "HH:MM:SS"]
#     with open(f'{folder}mcd{mcd}\\Experiment{experiment}\\net_usage.log', 'r') as log:
#         log_lines = log.readlines()
#         for log_line in log_lines:
#             if any(key in log_line for key in keys):
#                 continue
#             else:
#                 log_line = log_line.strip("\n")
#                 log_line = log_line.split(" ")
#                 log_line = list(filter(None, log_line))
#                 net.append({"In": log_line[1], "Out": log_line[2]})  # In KB/s
#         return net
#
#
# def get_memaslap_stat(mcd, experiment):
#     memaslap = []
#     flag = False
#     with open(f'{folder}mcd{mcd}\\Experiment{experiment}\\memaslap_stat.log', 'r') as log:
#         log_lines = log.readlines()
#         for log_line in log_lines:
#             if "Total Statistics" in log_line:
#                 flag = True
#             elif "Period" in log_line and flag:
#                 log_line = log_line.strip("\n")
#                 log_line = log_line.split(" ")
#                 log_line = list(filter(None, log_line))
#                 memaslap.append({"TPS": log_line[3], "Average Latency": log_line[8]})
#                 flag = False
#         return memaslap
#
#
# def Strip(str):
#     str = str.strip("\n")
#     str = str.split(": ")
#     return str[1]
#
#
# # Get the name of the txt files in directory
# for filename in os.listdir(folder):
#     if filename.startswith("migration_status") and filename.endswith(".log"):
#
#         filename = filename.strip(".log")
#
#         index = -1
#         keys = ["No:"]
#         precopy = []
#         arr = []
#         EXPERIMENT = ""
#         number = 0
#         mode = ""
#         output_file = filename.split("_")[2].strip("mcd")
#
#         hash_type = folder.split("\\")[8]
#
#         if "Vanilla_PreCopy" in folder.split("\\")[9]:
#             mode = "Vanilla"
#         elif "HBFDP_Enabled_XBZRLE_Enabled_Precopy" in folder.split("\\")[9]:
#             mode = "XBZRLE_HBFDP"
#         elif "XBZRLE_Enabled_Precopy" in folder.split("\\")[9]:
#             mode = "XBZRLE"
#         elif "HBFDP_Enabled_Precopy" in folder.split("\\")[9]:
#             mode = "HBFDP"
#
#         # print(mode)
#
#         # with open(f"S:\\Python Virtual ENV\\Chart Generation\\data\\{mode}\\{output_file}.csv", 'a') as csv:
#         with open(f"S:\\Python Virtual ENV\\Chart Generation\\sha1 vs md5\\{hash_type}\\{mode}\\{output_file}.csv", 'a') as csv:
#             with open(f'{folder}{filename}.log', 'r') as f:
#                 lines = f.readlines()
#                 # Check whether line contains a string pattern
#                 for line in lines:
#                     if "Experiments" in line:
#                         line = line.strip("----------------")
#                         line = line.strip("----------------\n")
#                         line = line.strip(" ")
#                         line = line.split(" ")
#                         EXPERIMENT = line[0]
#                         csv.write(
#                             "Experiment,Iterations,Setup-Time,Downtime,Total-Time,Ram-Total,Ram-Postcopy-Requests,Ram-Dirty-Sync-Count,Ram-Remaining,Ram-Mbps,Ram-Transferred,Ram-Duplicate,Ram-Dirty-Pages-Rate,Ram-Skipped,Ram-Normal-Bytes,Ram-Normal,Total-Fake-Dirty-Pages\n")
#                     elif any(key in line for key in keys):
#                         number = Strip(line)
#                     elif "completed" in line:
#                         line = line.strip("\n")
#                         # Convert String to JSON
#                         line = line.replace("'", "\"")
#                         line = json.loads(line)
#                         # Access value in JSON
#                         arr.append(number)
#                         arr.append(line["return"]["iterations"])
#                         arr.append(line["return"]["setup-time"])
#                         arr.append(line["return"]["downtime"])
#                         arr.append(line["return"]["total-time"])
#                         arr.append(line["return"]["ram"]["total"])
#                         arr.append(line["return"]["ram"]["postcopy-requests"])
#                         arr.append(line["return"]["ram"]["dirty-sync-count"])
#                         arr.append(line["return"]["ram"]["remaining"])
#                         arr.append(line["return"]["ram"]["mbps"])
#                         arr.append(line["return"]["ram"]["transferred"])
#                         arr.append(line["return"]["ram"]["duplicate"])
#                         arr.append(line["return"]["ram"]["dirty-pages-rate"])
#                         arr.append(line["return"]["ram"]["skipped"])
#                         arr.append(line["return"]["ram"]["normal-bytes"])
#                         arr.append(line["return"]["ram"]["normal"])
#
#                         fd_count = 0
#                         for count in range(0, len(line["return"]["page-count"])):
#                             fd_count += line["return"]["fake-dirty"][count]
#                         arr.append(fd_count)
#
#                         # Write all the items in arr array to CSV file
#                         for item in arr:
#                             csv.write(f"{item},")
#                         csv.write("\n")
#                         # Append arr to the appropriate list
#                         if EXPERIMENT == "Precopy":
#                             precopy.append(arr)
#                         arr = []
#                     elif "------------------------------------------------------" in line:
#                         continue

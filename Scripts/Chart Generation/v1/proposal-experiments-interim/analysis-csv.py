import os

optimizations = ['Vanilla']
workloads = ['Quicksort']
rams = [1, 2, 4, 8, 12, 16]
cells = [2, 6]

for optimization in optimizations:

    for workload in workloads:

        cells = [2, 6]

        with open(f".\\data\\Analysis\\{optimization}_{workload}.csv", 'w') as data:

            for ram in rams:
                ram_mb = str(ram * 1024)

                if not os.path.exists(f"S:\\Python Virtual ENV\\Chart Generation\\proposal-experiments\\data\\{optimization}\\{workload}\\{ram_mb}.csv"):
                    continue

                average = {
                    "Iterations": 'B',
                    "Setup-Time": 'C',
                    "Downtime": 'D',
                    "Total-Time": 'E',
                    "Ram-Total": 'F',
                    "Ram-Postcopy-Requests": 'G',
                    "Ram-Dirty-Sync-Count": 'H',
                    "Ram-Remaining": 'I',
                    "Ram-Mbps": 'G',
                    "Ram-Transferred": 'K',
                    "Ram-Duplicate": 'L',
                    "Ram-Dirty-Pages-Rate": 'M',
                    "Ram-Skipped": 'N',
                    "Ram-Normal-Bytes": 'O',
                    "Ram-Normal": 'P',
                    "Total-Fake-Dirty-Pages": 'Q'
                }

                with open(f".\\data\\{optimization}\\{workload}\\{ram_mb}.csv", 'r') as f:

                    lines = f.readlines()
                    for line in lines:
                        data.write(line)

                        if "Experiment" not in line:
                            avg_line = line.split(",")

                    # tmt_formula = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # fd_formula = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", Q{cells[0]}:Q{cells[1]})"'
                    #
                    # average["Iterations"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", B{cells[0]}:B{cells[1]})"'
                    # average["Setup-Time"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", C{cells[0]}:C{cells[1]})"'
                    # average["Downtime"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", D{cells[0]}:D{cells[1]})"'
                    # average["Total-Time"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Total"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Postcopy-Requests"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Dirty-Sync-Count"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Remaining"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Mbps"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Transferred"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Duplicate"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Dirty-Pages-Rate"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Skipped"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Normal-Bytes"] =  f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Ram-Normal"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", E{cells[0]}:E{cells[1]})"'
                    # average["Total-Fake-Dirty-Pages"] = f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", Q{cells[0]}:Q{cells[1]})"

                    data.write("Average,")
                    for key in average.keys():
                        data.write(f'"=AVERAGEIF($R{cells[0]}:$R{cells[1]}, ""No"", {average[key]}{cells[0]}:{average[key]}{cells[1]})",')
                    data.write("\n")
                    data.write("\n")

                cells[0] += 8
                cells[1] += 8
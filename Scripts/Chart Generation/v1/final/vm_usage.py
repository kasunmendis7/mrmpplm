import os


def parse_quicksort(folder, workload, name):
    for ram in os.listdir(f"{folder}"):
        if "RAM" in ram:
            size = ram.strip("RAM")
            with open(f".\\data\\Application-Overhead\\{workload}\\{name}\\ram{size}.{name}.quicksort.csv", 'w') as csv:
                csv.write("Time,Second,Number of Sorts,State\n")
                with open(f'{folder}\\{ram}\\Experiment\\quicksort_nop.log', 'r') as log:
                    log_lines = log.readlines()
                    for log_line in log_lines:
                        if "Second" in log_line:
                            log_line = log_line.strip("\n")
                            log_line = log_line.split("|")
                            log_line = list(filter(None, log_line))
                            time = f'{log_line[0].split(":")[1].split()[0]}:{log_line[0].split(":")[2].split()[0]}:{log_line[0].split(":")[3].split()[0]}'
                            sec = log_line[1].split(":")[1].strip()
                            nop = log_line[2].split(":")[1].strip()
                            csv.write(f"{time},{sec},{nop},\n")


vanilla_folder = 'S:\\University\\Research\\Undergraduate Research\\MRMPPLM\\Data-and-Logs\\Experiment-Data\\application-overhead_2025-02-20_2\\Quicksort_2025-02-20_1\\Vanilla_PreCopy_2025-02-20_1'
parse_quicksort(vanilla_folder, "Quicksort", "Vanilla")
dtrack_folder = 'S:\\University\\Research\\Undergraduate Research\\MRMPPLM\\Data-and-Logs\\Experiment-Data\\application-overhead_2025-02-20_2\\Quicksort_2025-02-20_1\\Dtrack_PreCopy_2025-02-20_1'
parse_quicksort(dtrack_folder, "Quicksort", "Dtrack")

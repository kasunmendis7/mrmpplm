def parse_cpu(file):
    with open(f".\\data\\Analysis\\CPU.csv", 'w') as csv:
        csv.write("Time,USR,SYS\n")
        with open(f'{file}\\cpu_usage.log', 'r') as log:
            log_lines = log.readlines()
            for log_line in log_lines:
                if "all" in log_line:
                    log_line = log_line.strip("\n")
                    log_line = log_line.split(" ")
                    log_line = list(filter(None, log_line))
                    csv.write(f"{log_line[0]},{log_line[2]},{log_line[4]}\n")


def parse_mem(file):
    mem = []
    with open(f'{file}\\mem_usage.log', 'r') as log:
        log_lines = log.readlines()
        for log_line in log_lines:
            if "Mem:" in log_line:
                log_line = log_line.strip("\n")
                log_line = log_line.split(" ")
                log_line = list(filter(None, log_line))
                mem.append(log_line[2])
    return mem


def parse_net(file):
    net = []
    keys = ["Time", "HH:MM:SS"]
    with open(f'{file}\\net_usage.log', 'r') as log:
        log_lines = log.readlines()
        for log_line in log_lines:
            if any(key in log_line for key in keys):
                continue
            else:
                log_line = log_line.strip("\n")
                log_line = log_line.split(" ")
                log_line = list(filter(None, log_line))
                net.append({"In": log_line[1], "Out": log_line[2]})  # In KB/s


def parse_memaslap(file):
    memaslap = []
    flag = False
    with open(f'{file}\\memaslap_stat.log', 'r') as log:
        log_lines = log.readlines()
        for log_line in log_lines:
            if "Total Statistics" in log_line:
                flag = True
            elif "Period" in log_line and flag:
                log_line = log_line.strip("\n")
                log_line = log_line.split(" ")
                log_line = list(filter(None, log_line))
                memaslap.append({"TPS": log_line[3], "Average Latency": log_line[8]})
                flag = False
# Create CSV File
def Strip(str, char=": "):
    str = str.strip("\n")
    str = str.split(char)
    return str[1]


iteration = src = dst = ""
mismatch = []

with (open('dst_hbfdp_log2.out', 'r') as f):
    lines = f.readlines()
    # Check whether line contains a string pattern
    for line in lines:
        if "# Pages Received in Current Iteration " in line:
            continue
        elif "Iteration " in line:
            iteration = Strip(line, " ")
        elif "SRC HASH : " in line:
            src = Strip(line)
        elif "DST HASH : " in line:
            dst = Strip(line)
            if src != dst:
                mismatch.append({"iteration": iteration, "src": src, "dst": dst})
            src = dst = ""

for i in mismatch:

    print("========================")
    print(i)

    with (open('src_hbfdp_log2.out', 'r') as f):
        lines = f.readlines()

        for line in lines:
            if "# Pages Received in Current Iteration " in line:
                continue
            elif "Iteration " in line:
                iteration = line
            elif i["src"] in line:
                print(iteration.strip("\n"))
                print(line)
            elif i["dst"] in line:
                print(iteration.strip("\n"))
                print(line)

    print("========================")

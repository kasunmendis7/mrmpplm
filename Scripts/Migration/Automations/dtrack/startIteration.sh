#!/bin/bash
OPTIMIZATION="$1"
WORKLOAD="$2"
RAM=$3
VM="$4"
TAP="$5"
CORE=$6
WORKINGSET="$7"
LOG_FILE="$8"
EXPERIMENT_DIR="$9"
HASH_TYPE="${10}"

DST=163
POST="false"
IP=195
PASSWORD="vmpassword"
USER="vmuser"
WORKLOAD_ID=""
COUNT=0

printpara() {
	echo $OPTIMIZATION
	echo $WORKLOAD
	echo $RAM
	echo $VM
	echo $TAP
	echo $CORE
	echo $WORKINGSET
	echo $HASH_TYPE
	echo $LOG_FILE
	echo $EXPERIMENT_DIR
}

log() {
	echo $1 >> $LOG_FILE
}

terminate-qemu () {
	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 root@10.22.196.$IP "poweroff"
	sleep 20
	ping -c 5 10.22.196.$IP > /dev/null
	PING=$?
	if [[ $PING -ne 0 ]];
	then
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "pkill qemu"
	fi
	sleep 10
	pkill qemu
}

check-error() {
	if [ $2 -ne 0 ]; then
		echo ">>> $1 command failed with error code $2."
		terminate-qemu
		exit 255
	fi
}

get-migration-details() {
	MIGRATION=""

	while [[ $MIGRATION != *"completed"* ]];
	do
		if [[ $COUNT -eq 100 ]]
		then 
			echo ">>> Migration Failure"
			log ">>> Migration Failure"
			HOSTS=("162" "163")
			for HOST  in "${HOSTS[@]}"
			do
				sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$HOST "pkill qemu"
				sleep 10
			done
			exit 255
		fi
		sleep 1m
		echo ">>> Checking for Migration Status"
		MIGRATION=$(bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Status/migration-status.sh)
		((COUNT++))
	done

	echo ">>> Migration Completed"

	ping -c 10 10.22.196.$IP > /dev/null
	PING=$?

	if [[ $PING -eq 0 ]]; 
	then
		# FILES=("cpu" "mem" "net")
		# for FILE  in "${FILES[@]}"
		# do
		# 	echo root@10.22.196.$IP:/home/${USER}/Desktop/${FILE}_usage.log
		# 	echo "$EXPERIMENT_DIR"
		# 	sshpass -p "$PASSWORD" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.$IP:/home/${USER}/Desktop/${FILE}_usage.log "$EXPERIMENT_DIR"
		# 	check-error "rsync" $?
		# 	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "rm /home/$USER/Desktop/${FILE}_usage.log"
		# done
		log "Migration:" 
		log "$MIGRATION"      
		log ""
	else
		echo ">>> Ping Failed : VM is Not Responding after Migration"
		log ">>> Ping Failed : VM is Not Responding after Migration"
		HOSTS=("162" "163")
		for HOST  in "${HOSTS[@]}"
		do
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$HOST "pkill qemu"
			sleep 10
		done
		exit 255
	fi

	terminate-qemu
	exit 100
}

# Readying Destination to Recieve VM
echo ">>> Readying Destination to Recieve VM"
sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Automations/vm-start/startDestination.sh $VM $TAP $RAM $CORE $POST" &
sleep 5
DESTINATION_ID=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "pgrep qemu")

if [[ -n $DESTINATION_ID ]];
then
	echo ">>> Successfull Started Destination"
else
	echo ">>> Destination Container Not Started"
	exit 255       
fi

# Starting the VM in Source Machine
bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Automations/vm-start/startSource.sh $VM $TAP $RAM $CORE $POST &
sleep 1m
if [ "$WORKLOAD" = "oltp" ]
then 
	IP=200 
	PASSWORD="workingset"
	USER="workingset"
fi
ping -c 10 10.22.196.$IP > /dev/null
SOURCE_PING=$?

if [[ $SOURCE_PING -eq 0 ]];
then
	echo ">>> VM Up & Running"
	# sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "mpstat 1 180 > /home/$USER/Desktop/cpu_usage.log 2>&1 &"
	# sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "free -h -s 1 > /home/$USER/Desktop/mem_usage.log 2>&1 &"
	# sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "ifstat -t 1 > /home/$USER/Desktop/net_usage.log 2>&1 &"
else
	echo ">>> VM Not Started"
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "pkill qemu"
	exit 255
fi

# Starting the Specific Workload in VM
printf ">>> Starting %s in VM\n" ${WORKLOAD^}
sleep 10

if [ "$WORKLOAD" = "sysbench" ]
then
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "sysbench --test=cpu --cpu-max-prime=5000000 run > /dev/null 2>&1 &"
	sleep 10
	WORKLOAD_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep sysbench")
elif [ "$WORKLOAD" = "quicksort" ]
then
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "/home/vmuser/Desktop/quicksort > quicksort_nop 2>&1 &" &
	sleep 10
	WORKLOAD_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep quicksort")
elif [ "$WORKLOAD" = "workingset" ]
then
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "/home/vmuser/Desktop/workingset $WORKINGSET &" &
	sleep 10
	WORKLOAD_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep workingset")
elif [ "$WORKLOAD" = "memcached" ]
then
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "memcached -u root -t 4 -m $WORKINGSET &" &
	sleep 10
	WORKLOAD_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep memcached")
elif [ "$WORKLOAD" = "oltp" ]
then
	sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "cd /home/workingset/Desktop/benchbase/target/benchbase-postgres && java -jar benchbase.jar -b ycsb -c config/postgres/sample_ycsb_config.xml --create=true --load=true --execute=true -s 1  > /dev/null 2>&1 &" &
	sleep 10
	WORKLOAD_ID=$(sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep -f ycsb")
fi

if [[ -n $WORKLOAD_ID ]]; 
then
	printf ">>> Started %s in VM, Process ID : %s\n" ${WORKLOAD^} $WORKLOAD_ID

	# Have to start memaslap from the client if the workoad is memcached
	if [ "$WORKLOAD" = "memcached" ]
	then 
		echo ">>> Starting Memaslap in Client"
		sleep 10
		sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.158 "/home/cloudnet/samindu/workloads/libmemcached-1.0.18/clients/memaslap -s 10.22.196.$IP:11211 -c 6 > $EXPERIMENT_DIR/memaslap_stat.log 2>&1 &"
		sleep 10
		MEMASLAP_ID=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.158 "pgrep memaslap")

		if [[ -n $MEMASLAP_ID ]]; 
		then
			printf ">>> Started Memaslap in Client, Process ID : %s\n" $MEMASLAP_ID
		else
			echo ">>> Process Memaslap Not Started"
			terminate-qemu
			exit 255
		fi
	fi
else
	printf ">>> Process %s Not Started" ${WORKLOAD^}
	terminate-qemu
	exit 255
fi

sleep 2m

# Trigger Migration
if [ "$OPTIMIZATION" = "compress" ] || [ "$OPTIMIZATION" = "compress-hbfdp" ] || [ "$OPTIMIZATION" = "compress-dtrack" ]
then
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Triggers/Pre-Copy/precopy-compress-dst.sh"
fi

bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Triggers/Pre-Copy/precopy-vm-migrate.sh $OPTIMIZATION $HASH_TYPE $DST

# Collect Migration Data
get-migration-details

#!/bin/bash

EXPERIMENT="$1"
OPTIMIZATION="$2"
VM="$3"
TAP="$4"
RAM=$5
CORE=$6
TYPE="$7"
LOG="$8"
WS="$9"
LOGFILE="${10}"
HASHTYPE="${11}"

POST=""
MIGRATION=""
STATUS=""

terminate-qemu () {
	if [ "$EXPERIMENT" = "oltp" ]
	then
        sshpass -p "workingset" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 root@10.22.196.200 "poweroff"
	else
        sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 root@10.22.196.195 "poweroff"
	fi
	sleep 10
	DESTINATION_CHECK=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pgrep qemu")
	if [[ -n $DESTINATION_CHECK ]];
	then
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pkill qemu"
	fi
	sleep 10
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pkill qemu"
}

check_error() {
	if [ $2 -ne 0 ]; then
		echo ">>> $1 command failed with error code $2."
		terminate-qemu
		exit 255
	fi
}

migration_complete() {
	log "Migration:" 
	log "$MIGRATION"      
	log ""
}

get_migration_details() {

	MIGRATION=""

	while [[ $MIGRATION != *"completed"* ]];
	do
		sleep 60
		echo ">>> Checking for Migration Status"
		MIGRATION=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Status/migration-status.sh")
	done

	echo ">>> Migration Completed"

	if [ "$EXPERIMENT" = "idle" ]
	then
		ping -c 5 10.22.196.195 > /dev/null
		PING=$?
		if [[ $PING -eq 0 ]]; 
		then
			migration_complete
		else
			echo ">>> Ping Failed : VM is Not Responding after Migration"
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pkill qemu"
			sleep 10
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pkill qemu"
			exit 255
		fi
	elif [ "$EXPERIMENT" = "iperf" ]
	then
		ping -c 5 10.22.196.195 > /dev/null
		PING=$?
		if [[ $PING -eq 0 ]]; 
		then
			sshpass -p "vmpassword" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.195:/home/vmuser/Desktop/iperf_vm.log "$LOGFILE"
			check_error "rsync" $?
			migration_complete
		else
			echo ">>> Ping Failed : VM is Not Responding after Migration"
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pkill qemu"
			sleep 10
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pkill qemu"
			exit 255
		fi
	elif [ "$EXPERIMENT" = "memcached" ]
	then
		sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.168 "pkill -15 memaslap"
		#sleep 10
		#sshpass -p "primedirective" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.168:/mnt/nfs/samindu/workloads/libmemcached-1.0.18/memaslap_stat.log "$LOGFILE"
		sleep 10
		SSH=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 root@10.22.196.195 "pgrep memcached")
		if [[ -n $SSH ]]; 
		then
			#sshpass -p "vmpassword" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.195:/home/vmuser/Desktop/cpu_usage.log "$LOGFILE"
			#check_error "rsync" $?
			#sshpass -p "vmpassword" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.195:/home/vmuser/Desktop/mem_usage.log "$LOGFILE"
			#check_error "rsync" $?
			#sshpass -p "vmpassword" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.195:/home/vmuser/Desktop/net_usage.log "$LOGFILE"
			#check_error "rsync" $?

			migration_complete
		else
			echo ">>> VM is Not Responding after Migration"
			sleep 600
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pkill qemu"
			sleep 10
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pkill qemu"
			exit 255
		fi
	elif [ "$EXPERIMENT" = "workingset" ]
	then
		SSH=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 root@10.22.196.195 "pgrep memcached")
		if [[ -n $SSH ]]; 
		then
			migration_complete
		else
			echo ">>> VM is Not Responding after Migration"
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pkill qemu"
			sleep 10
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pkill qemu"
			exit 255
		fi
	elif [ "$EXPERIMENT" = "oltp" ]
	then
		ping -c 5 10.22.196.200 > /dev/null
		PING=$?
		if [[ $PING -eq 0 ]]; 
		then
			migration_complete
		else
			echo ">>> Ping Failed : VM is Not Responding after Migration"
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pkill qemu"
			sleep 10
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pkill qemu"
			exit 255
		fi
	fi

	terminate-qemu

	exit 100
}

log() {
	echo $1 >> $LOG
}

echo ">>> Readying Destination to Recieve VM"
if [ "$TYPE" = "tcp" ]
then
	POST="false"
else
	POST="true"
fi

# Making Destination Ready to Recieve
sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Automations/vm-start/startDestination.sh $VM $TAP $RAM $CORE $POST" &
sleep 5
DESTINATION_ID=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "pgrep qemu")

if [[ -n $DESTINATION_ID ]];
then
	echo ">>> Successfull Started Destination"
else
	echo ">>> Destination Container Not Started"
	exit 255       
fi

# Starting the VM in Source Machine
sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Automations/vm-start/startSource.sh $VM $TAP $RAM $CORE $POST" &
sleep 60
SOURCE_ID=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "pgrep qemu")

if [[ -n $SOURCE_ID ]];
then
	echo ">>> VM Up & Running"
	#sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "mpstat 1 180 > /home/vmuser/Desktop/cpu_usage.log 2>&1 &"
	#sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "free -h -s 1 > /home/vmuser/Desktop/mem_usage.log 2>&1 &"
	#sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "ifstat -t 1 > /home/vmuser/Desktop/net_usage.log 2>&1 &"
else
	echo ">>> VM Not Started"
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.163 "kill $(pgrep qemu)"
	exit 255
fi

if [ "$EXPERIMENT" = "idle" ]
then
	echo ">>> Idle VM, No Work in VM"
elif [ "$EXPERIMENT" = "iperf" ]
then
	echo ">>> Starting Iperf in VM"
	sleep 10
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "iperf3 -s -i 0.1 > /home/vmuser/Desktop/iperf_vm.log 2>&1 &"
	sleep 10
	IPERF_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "pgrep iperf3")

	if [[ -n $IPERF_ID ]]; 
	then
		printf ">>> Started Iperf in VM, Process ID : %s\n" $IPERF_ID
		echo ">>> Starting Iperf in Client"
		sleep 10
		iperf3 -c 10.22.196.195 -t 300 -i 0.1 > $LOGFILE/iperf_client.log 2>&1 &
		sleep 10
		IPERF_CLIENT_ID=$(pgrep iperf3)

		if [[ -n $IPERF_CLIENT_ID ]]; 
		then
			printf ">>> Started Iperf in Client, Process ID : %s\n" $IPERF_CLIENT_ID
		else
			echo ">>> Process Iperf in Client Not Started"
			terminate-qemu
			exit 255
		fi

	else
		echo ">>> Process Iperf in VM Not Started"
		terminate-qemu
		exit 255
	fi
elif [ "$EXPERIMENT" = "sysbench" ]
then
	echo ">>> Starting Sysbench in VM"
	sleep 10
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "sysbench --test=cpu --cpu-max-prime=5000000 run > /home/vmuser/Desktop/sysbench_out.log 2>&1 &"
	sleep 10
	SYSBENCH_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "pgrep sysbench")

	if [[ -n $SYSBENCH_ID ]]; 
	then
		printf ">>> Started Sysbench in VM, Process ID : %s\n" $SYSBENCH_ID
	else
		echo ">>> Process Sysbench Not Started"
		terminate-qemu
		exit 255
	fi
elif [ "$EXPERIMENT" = "memcached" ]
then
	echo ">>> Starting Memcached in VM"
	sleep 10
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "memcached -u root -t 4 -m $WS &" &
	sleep 10
	MEMCACHED_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "pgrep memcached")

	if [[ -n $MEMCACHED_ID ]]; 
	then
		printf ">>> Started Memcached in VM, Process ID : %s\n" $MEMCACHED_ID
		echo ">>> Starting Memaslap in Client"
		sleep 10
		#sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.168 "/mnt/nfs/samindu/workloads/libmemcached-1.0.18/clients/memaslap -s 10.22.196.195:11211 -c 6  -S 1s > /mnt/nfs/samindu/workloads/libmemcached-1.0.18/memaslap_stat.log 2>&1 &"
		/mnt/nfs/samindu/workloads/libmemcached-1.0.18/clients/memaslap -s 10.22.196.195:11211 -c 6 > /mnt/nfs/samindu/workloads/libmemcached-1.0.18/memaslap_stat.log 2>&1 &
		sleep 10
		# MEMASLAP_ID=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.168 "pgrep memaslap")
		MEMASLAP_ID=$(pgrep memaslap)

		if [[ -n $MEMASLAP_ID ]]; 
		then
			printf ">>> Started Memaslap in Client, Process ID : %s\n" $MEMASLAP_ID
		else
			echo ">>> Process Memaslap Not Started"
			terminate-qemu
			exit 255
		fi
	else
		echo ">>> Process Memcached Not Started"
		terminate-qemu
		exit 255	
	fi
elif [ "$EXPERIMENT" = "workingset" ]
then
	echo ">>> Starting Workingset in VM"
	sleep 10
	sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "/home/vmuser/Desktop/workingset $WS &" &
	sleep 10
	WORKINGSET_ID=$(sshpass -p "vmpassword" ssh -o StrictHostKeyChecking=no root@10.22.196.195 "pgrep workingset")

	if [[ -n $WORKINGSET_ID ]]; 
	then
		printf ">>> Started Workingset in VM, Process ID : %s\n" $WORKINGSET_ID
	else
		echo ">>> Process Workingset Not Started"
		terminate-qemu
		exit 255
	fi
elif [ "$EXPERIMENT" = "oltp" ]
then
	echo ">>> Starting Oltp in VM"
	sleep 10
	sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.200 "cd /home/workingset/Desktop/benchbase/target/benchbase-postgres && java -jar benchbase.jar -b ycsb -c config/postgres/sample_ycsb_config.xml --create=true --load=true --execute=true -s 1  > /dev/null 2>&1 &" &
	sleep 10
	OLTP_ID=$(sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.200 "pgrep -f ycsb")

	if [[ -n $OLTP_ID ]]; 
	then
		printf ">>> Started Oltp in VM, Process ID : %s\n" $OLTP_ID
	else
		echo ">>> Process Oltp Not Started"
		terminate-qemu
		exit 255
	fi
fi

TRIGGERS=/mnt/nfs/samindu/mrmpplm/Scripts/Migration/Triggers

if [ "$TYPE" = "tcp" ]
then
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "bash $TRIGGERS/Pre-Copy/precopy-vm-migrate.sh $OPTIMIZATION $HASHTYPE"
elif [ "$TYPE" = "pp" ]
then
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "bash  $TRIGGERS/Post-Copy/postcopy-vm-migrate.sh"
elif [ "$TYPE" = "hb" ]
then
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.162 "bash $TRIGGERS/Hybrid/hybrid-vm-migrate.sh"
fi

get_migration_details

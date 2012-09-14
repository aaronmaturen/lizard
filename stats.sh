#!/bin/bash
USAGE="Usage: -h[host] -u [username] -p [password]."

host="localhost"
time_to_live=600

while getopts ":p:u:h:k:t:" OPTIONS; do
	case $OPTIONS in
		p ) password="-p"$OPTARG;;
		u ) user=$OPTARG;;
		h ) host=$OPTARG;;
		k ) murder=$OPTARG;;
		t ) time_to_live=$OPTARG;;
		\? ) echo $USAGE
	 		 exit 1;;
		* ) echo $usage
			exit 1;;
	esac
done

echo "logging into MySQL host " $host" with username" $user


function get_number_of_queries(){
	echo "show status like 'Queries';" | mysql -h $host -u $user $password | sed "s/[^0-9]//g"
}

function get_number_of_connections(){
	echo "show status like 'Connections';" | mysql -h $host -u $user $password | sed "s/[^0-9]//g"
}

function get_uptime(){
	echo "show status like 'Uptime';" | mysql -h $host -u $user $password| sed "s/[^0-9]//g"
}

function get_processes(){
	echo "show processlist;" | mysql -h $host -u $user $password  
}

function kill_stale_connections(){
	echo "show processlist;" | mysql -h $host -u $user $password | awk "/$murder.*Sleep/"'{if ($6 > 5) print "kill "$1";"}' | mysql -h $host -u $user $password
}

#get number of queries to start with
initialquery=$(get_number_of_queries)
initialconnection=$(get_number_of_connections)
initialuptime=$(get_uptime)
echo "Initial Number of Queries:" $initialquery
echo "Initial Number of Connections:" $initialconnection
echo "Initial Uptime:" $initialuptime
echo "Loop Interval:" $time_to_live
#initialize correction variable for queries per interval
queries_to_last_interval=$initialquery
connections_to_last_interval=$initialconnection
intervals=0

#loop forever while counting number of queries
while true;
do
	kill_stale_connections
	queries=$(get_number_of_queries)
	connections=$(get_number_of_connections)
	intervals=$(($intervals+1))

	echo "connections in last interval:" $(($connections-$connections_to_last_interval)) "| queries in the last interval:" $(($queries-$queries_to_last_interval))
	
	#update total queries to this second
	queries_to_last_interval=$queries
	connections_to_last_interval=$connections
	
	#shh, it's nap time.
	sleep $time_to_live
done

#EOF

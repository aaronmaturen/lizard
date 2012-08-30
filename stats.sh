#!/usr/bin/bash
USAGE="Usage: -h[host] -u [username] -p [password]."

while getopts ":p:u:h:" OPTIONS; do
	case $OPTIONS in
		p ) password=$OPTARG;;
		u ) user=$OPTARG;;
		h ) host=$OPTARG;;
		\? ) echo $USAGE
	 		 exit 1;;
		* ) echo $usage
			exit 1;;
	esac
	echo "logging into MySQL host " $host" with username" $user", and password" $password
done

function get_number_of_queries(){
	echo "show status like 'Queries';" | mysql -h $host -u $user -p$password | sed "s/[^0-9]//g"
}

function get_number_of_connections(){
	echo "show status like 'Connections';" | mysql -h $host -u $user -p$password | sed "s/[^0-9]//g"
}

function get_uptime(){
	echo "show status like 'Uptime';" | mysql -h $host -u $user -p$password| sed "s/[^0-9]//g"
}
#get number of queries to start with
initialquery=$(get_number_of_queries)
initialconnection=$(get_number_of_connections)
initialuptime=$(get_uptime)
echo "Initial Number of Queries:" $initialquery
echo "Initial Number of Connections:" $initialconnection
echo "Initial Uptime:" $initialuptime
#initialize correction variable for queries per {sec:hour:min}
queries_to_last_second=$initialquery
queries_to_last_minute=$initialquery
queries_to_last_hour=$initialquery
connections_to_last_second=$initialconnection
connections_to_last_minute=$initialconnection
connections_to_last_hour=$initialconnection
seconds=0
minutes=0
hours=0

#loop every second forever while counting number of queries
while true;
do
	#sleep for a second
	sleep 1
	queries=$(get_number_of_queries)
	connections=$(get_number_of_connections)
	seconds=$(($seconds+1))
	if [ "$seconds" -eq "60" ]; then
		seconds=0
		minutes=$(($minutes+1))
		echo "connections in the last minute:" $(($connections-$connections_to_last_minute)) "| queries in the last minute:" $(($queries-$queries_to_last_minute))
	   	queries_to_last_minute=$queries
		connections_to_last_minute=$connections
		if [ "$minutes" -eq "60" ]; then
			minutes=0
			hours=$(($hours+1))
			echo "connections in the last hour: " $(($connections-$connections_to_last_hour))"| queries in the last hour:" $(($queries-$queries_to_last_hour))
			queries_to_last_hour=$queries
			connections_to_last_hour=$connections
		fi
	fi
	echo "connections in last second:" $(($connections-$connections_to_last_second)) "| queries in the last second:" $(($queries-$queries_to_last_second))

	
	#update total queries to this second
	queries_to_last_second=$queries
	connections_to_last_second=$connections
done

#EOF

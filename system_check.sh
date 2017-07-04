#! /bin/bash

#Description: the script is one test for vps such as netword-speed,I/O speed for hardinfo 
#							,ping time(loss)  from everywhere and system-information

#copyright 2017 (C) by hectorchou
#Author :hectorchou
#E-mail:hectorchou@hotmail.com
#E-mail:me@hectorchou.com
#thanks: teddy.com
#URL:http://hectorchou.com/

#pre_setting_files
echo -e "VPS Testing Continue..."
WHITE='\033[0;37m'
BLACK='\033[1;30m'
RED='\033[0;31m'
ORANGE='\033[0;35m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m'

if [ $UID -ne 0 ];then
	echo "You must be login the machine by root (which is super admin for machine).Please Use "su - root "to change the user."
	exit 1
fi 

#install bc , awk ,dd and wget

[[ -f /etc/redhat-release ]] && os='centos'
[[ ! -z "`egrep -i debian /etc/issue`" ]] && os='debian'
[[ ! -z "`egrep -i ubuntu /etc/issue`" ]] && os='ubuntu'
[[ "$os" == '' ]] && echo 'Error: Your system is not supported to run it!' && exit 1

if [ "$os" == 'centos' ]; then
    yum -y  -q install bc wget >/dev/null
else
    apt-get -y -q update >/dev/null
    apt-get -y -q install bc wget >/dev/null
fi

#function for test moudle

#test input -output speed for disk
disk_iotest_check(){
echo -e "Disk_iotest_Result is following:\n"
echo -e "Test_times \t Block=4k \t Block=8k \t Block=16K \n"
		for count1 in {1,2,3}
			do
				size16K=$( (dd if=/dev/zero of=/var/testio   bs=16k count=16K conv=fdatasync && rm -f /var/testio ) 2>&1 | awk -F, '{print $NF}' | tail -1 )
				size4K=$( (dd if=/dev/zero of=/var/testio   	bs=4k count=16K conv=fdatasync && rm -f /var/testio ) 2>&1 | awk -F, '{print $NF}' | tail -1 )
				size8K=$( (dd if=/dev/zero of=/var/testio   	bs=8k count=16K conv=fdatasync && rm -f /var/testio ) 2>&1 | awk -F, '{print $NF}' | tail -1 )   
				echo -e "\033[1,0m $count1 \t \t ${size4K} \t  ${size8K} \t  ${size16K} \n"
			done
	}

#calculate the storage of disk---total
disk_info_total(){
		
				i=$(df -h | grep -Ev "none|devtmpfs|tmpfs|Filesystem" |wc -l)
				n=1
			  #df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'
			  disktotal=0
			  parameters=$1
			 while (( i>0 ))
				do
			 			
			 			df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'|tail -$n|head -1 | grep -qE "M"
			 			if [[ $? == 0 ]];then
								disktotal1=$(df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'| tail -$n|head -1| awk -F'[M]' '{printf "%.1f", $1/1024}')	
			 			fi
			 			
			 			df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'|tail -$n|head -1 | grep -qE "G"
			 			if [[ $? == 0 ]];then
								disktotal1=$(df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'| tail -$n|head -1| awk -F'[G]' '{printf "%.1f", $1}')	
			 			fi
			 			
			 			df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'|tail -$n|head -1 | grep -qE "T"
			 			if [[ $? == 0 ]];then
								disktotal1=$(df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $2}'| tail -$n|head -1| awk -F'[T]' '{printf "%.1f", $1*1024}')
			 			fi
			 			disktotal=$( echo -e "$disktotal+$disktotal1"|bc)
			 			let ++n
						let --i
				done
			 		echo -e " $disktotal"
 }
 
 #calculate the storage of disk---used
disk_info_used(){
		
				i=$(df -h | grep -Ev "none|devtmpfs|tmpfs|Filesystem" |wc -l)
				n=1
			  diskused=0
			 while (( i>0 ))
				do
			 			
			 			df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $3}'|tail -$n|head -1 | grep -qE "M"
			 			if [[ $? == 0 ]];then
								diskused1=$(df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $3}'| tail -$n|head -1| awk -F'[M]' '{printf "%.1f", $1/1024}')	
			 			fi
			 			
			 			df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $3}'|tail -$n|head -1 | grep -qE "G"
			 			if [[ $? == 0 ]];then
								diskused1=$(df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $3}'| tail -$n|head -1| awk -F'[G]' '{printf "%.1f", $1}')	
			 			fi
			 			
			 			df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $3}'|tail -$n|head -1 | grep -qE "T"
			 			if [[ $? == 0 ]];then
								diskused1=$(df -h | grep -Ev "devtmpfs|tmpfs|Filesystem|none"| awk '{print $3}'| tail -$n|head -1| awk -F'[T]' '{printf "%.1f", $1*1024}')
			 			fi
			 			diskused=$( echo -e "$diskused+$diskused1"|bc)
			 			let ++n
						let --i
				done
			 		echo -e " $diskused"
 }
 
 
 #wget test the speed of vps;parameters  are that $1 is url for testwebsite;$2 is that CityName for testsite.

 speed_test(){
 			#wget -4O /dev/null http://cachefly.cachefly.net/100mb.test 2>&1 |awk '/\/dev\/null/ {speed=$3 $4}END{print speed}'|awk -F'[( )]' '{print $2}'
 			local speedtest=`wget -4O /dev/null $1 2>&1 |awk '/\/dev\/null/ {speed=$3 $4}END{print speed}'|awk -F'[( )]' '{print $2}'`
 			local ipaddr=$(ping -c1 `awk -F'/' '{print $3}' <<< $1` | awk -F'[( )]' '{print $4}' | head -1)
			local node_addr=$2
			printf "${YELLOW}%-10s${GREEN}%-60s${RED}%-27s${BLUE}%-10s\n" "${node_addr}" "$1" "${ipaddr}" "${speedtest}"
 }
 
 #default speedtest url parameters function
  network_speed(){
  		speed_test 'http://speedtest.newark.linode.com/100MB-newark.bin' 'US East'
  		speed_test 'http://speedtest.atlanta.linode.com/100MB-atlanta.bin' 'US South'
  		speed_test 'http://speedtest.dallas.linode.com/100MB-dallas.bin' 'US Central'
  		speed_test 'http://speedtest.fremont.linode.com/100MB-fremont.bin' 'US West'
  		speed_test 'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin' 'Frankfurt'
  		speed_test 'http://speedtest.london.linode.com/100MB-london.bin' 'UK London'
  		speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Singapore'
  		speed_test 'http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin' 'Japan Tokyo'
  		speed_test 'http://speedtest.dal05.softlayer.com/downloads/test100.zip' 'Dallas'
    	speed_test 'http://speedtest.sea01.softlayer.com/downloads/test100.zip' 'Seattle'
    	speed_test 'http://speedtest.fra02.softlayer.com/downloads/test100.zip' 'Frankfurt'
    	speed_test 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Singapore'
    	speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'HongKong'
  		
 
 }
 
 
 

					
#cpu informatione
logic_cpu_count=$( cat /proc/cpuinfo | grep "processor"| sort | uniq | wc -l )
physical_cpu_count=$( cat /proc/cpuinfo | grep "physical id" | sort |uniq | wc -l )
physical_cores_in_cpu=$(cat /proc/cpuinfo | grep "cpu cores" | uniq | awk -F: '{print $2}')
cpu_name=$(cat /proc/cpuinfo | grep "model name"| uniq | gawk -F: '{print $2}')
cache_size=$( cat /proc/cpuinfo | grep "cache size" |uniq| gawk -F: '{print $2}' )
thread=$( cat /proc/cpuinfo | grep "siblings"|uniq| awk -F: '{print $2}')
cpu_freq_num=$( cat /proc/cpuinfo  | grep "cpu MHz" | uniq | awk -F: '{print $2}')
cpu_frequence=${cpu_freq_num}"Mhz"
				  
#memery information
memory_total=$( free -m | grep "Mem:" | awk '{print $2}')
memory_used=$( free -m | grep "Mem:" | awk '{print $3}')
swap_total=$( free -m | grep "Swap:" | awk '{print $2}')
swap_used=$( free -m | grep "Swap:" | awk '{print $3}')



# Operation System information
				 if [ -f /etc/redhat-release ];then
				  	os_release=$( awk '{print $1 ,$4}' /etc/redhat-release )
				  elif [ -f /etc/os-release ];then
				  os_release=$( awk -F'[="]' '/PRETTY_/{print $3}' /etc/os-release )
				  elif [ -f /etc/lsb-release ];then
				  	os_release=$( awk -F'[="]' '/DISTRIB_DESCRIPTION/{print $3}' /etc/lsb-release )
				  fi
				  
# kernel information
kernel_release=$( uname -a | awk '{print $3}')
uname -a | grep "x86_64" >>/dev/null
if [ $? == 0 ];then
		os_bits="64bits"
else
		os_bits="32bits"
fi
#disk information
disk_storage=$(disk_info_total)
disk_used=$(disk_info_used) 
			
					
				
					
#show the information for the linux private server
clear
echo -e "${BLUE}CPU Model			:$cpu_name"
echo -e "CPU Frequence 			:$cpu_frequence"
echo -e "CPU cache			:$cache_size"
echo -e "CPU physical_count		: $physical_cpu_count CPU(s)"
echo -e "CPU cores_number		:$physical_cores_in_cpu Core(s)"
echo -e "CPU Thread			:$thread"
echo -e "CPU logic_count			: $logic_cpu_count CPU(s)"
echo -e "RAM_Memory_Total		: $memory_total MB"
echo -e "RAM_Memory_Used			: $memory_used MB"
echo -e "Swap_Total			: $swap_total MB"
echo -e "Swap_Used			: $swap_used MB"
echo -e "OS release			: $os_release $os_bits"
echo -e "Kernel release			: $kernel_release"
echo -e "Disk_Total			:$disk_storage GB"
echo -e "Disk_Used			:$disk_used GB"
echo -e "${RED}"

disk_iotest_check
echo -e "\033[1,37mTest_Area \t Test_URL \t \t \t \t \t \t Test_IP \t \t Speed"
echo -e "(the testing for network speed needs more time ,please wait for a moment...)"
network_speed				  
				  
echo -e "The testing for your vps is completed!\n"
echo -e "${RESET}"
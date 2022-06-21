#!/bin/bash                                                                                                                                                               
set -e                                                                                                                                                                    

echo -n "Введите сервер бекапа: "
read param1;

get_backup(){
    barman list-backup $param1 | awk '{print $2}'
}                                                                                                                                                                   

echo "ID backup:"                                                                                                                                                                          
echo $(get_backup)
echo -n "Восстановить id бекапа: ";                                                                                                                                
read param2;  

get_time_backup() {                                                                                                                                                            
barman show-backup $param1 $param2 | grep "End time" | awk '{print $4, $5, $6}'                                                                                                   
}
echo "Время бекапа:"
echo $(get_time_backup)                                                                                                                                                                                                                                                                                                                            
# echo -n "Восстановить на указаную дату: ";                                                                                                                                
# read param3; 
# barman recover \
# --remote-ssh-command "ssh postgres@192.168.56.51" \
# pgnode-m latest /var/lib/postgresql/13/main

# barman recover \\
#   --target-time "$param3" \\
#   --remote-ssh-command "ssh postgres@192.168.56.51" \\
#   ssh-pg $param2 /var/lib/postgresql/13/main


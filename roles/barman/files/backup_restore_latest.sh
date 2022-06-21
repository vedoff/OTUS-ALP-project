#!/bin/bash                                                                                                                                                               
set -e                                                                                                                                                                    

# echo "Введите latest если хотите восстановится из последнего бекапа: "

# read param1;


# get_backup(){
#     barman list-backup $param1
# }

barman recover \
--remote-ssh-command "ssh postgres@192.168.56.51" \
pgnode-m latest /var/lib/postgresql/13/main

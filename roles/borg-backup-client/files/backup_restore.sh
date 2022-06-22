#!/bin/bash                                                                                                                                                               
set -e                                                                                                                                                                    
                                                                                                                                                                          
get_backup() {                                                                                                                                                            
borg list borg@192.168.56.55:/var/Backuprepo/backup/ | awk '{print $1}'                                                                                                   
}                                                                                                                                                                         
                                                                                                                                                                          
echo $(get_backup)                                                                                                                                                                                                                                                                                                                                  
echo -n "Восстановить на указаную дату: ";                                                                                                                                
read param;                                                                                                                                                                                                                                                                                                                                      
echo "Дата восстановления = "$param                                                                                                                                       
                                                                                                                                                                          
#if [ $param -eq 0 ]                                                                                                                                                      
#then                                                                                                                                                                                                                                                                                                              
borg extract borg@192.168.56.55:/var/Backuprepo/backup/::$param                                                                                                      
                                                                                                                                                                          
#else                                                                                                                                                                     
                                                                                                                                                                          
echo "Восстановление проведено"                                                                                                                         
                                                                                                                                                                          
#fi
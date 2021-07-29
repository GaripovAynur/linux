
while true; do for i in stop start; do systemctl ${i} haproxy; sleep 100; done; done;

mysql -uroot -pqaz -e "show databases;" | sed 2p | sed 1,3d > 2.txt; c="2.txt"; for BD in $(cat $c); do mysql -uroot -pqaz -e "use $BD; show tables;" > 1.txt; file="1.txt"; for i in $(tac $file); do echo $BD, $i > 5.txt && mysql -uroot -pqaz -e "select * from $BD.$i" | grep -c 2000297115; sleep 1; done; done; > 3.txr

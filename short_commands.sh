
while true; do for i in stop start; do systemctl ${i} haproxy; sleep 100; done; done;

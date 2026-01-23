cat /etc/fstab 
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/vda2 during curtin installation
/dev/disk/by-uuid/82aeea96-6d42-49e6-85d5-9071d3c9b6aa / ext4 defaults 0 1
/dev/nfs/nfs /opt/nfs ext4 defaults 0 0
s3fs#nexus-bucket /opt/nexus-backup-bucket/ fuse _netdev,allow_other,use_path_request_style,url=https://storage.yandexcloud.net,passwd_file=/root/.passwd-s3fs 0 0


cat /root/.passwd-s3fs 
YJFHJDSTt7fGjOELaRMwss3pE:YCMJ6JLKFDiCM1GhXv7I_AQx8KQJs

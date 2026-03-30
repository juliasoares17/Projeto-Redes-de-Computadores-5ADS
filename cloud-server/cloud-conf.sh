apt update && apt install vsftpd -y

systemctl enable vsftpd

groupadd ftpgroup
useradd -m -s /usr/sbin/nologin -G ftpgroup ftpuser
echo "ftpuser:ftppassword" | chpasswd

mkdir -p /home/ftpuser/uploads
chown ftpuser:ftpgroup /home/ftpuser/uploads
chmod 755 /home/ftpuser/uploads

chown root:root /home/ftpuser
chmod 755 /home/ftpuser

cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
nano /etc/vsftpd.conf

cat << EOF > /etc/vsftpd.conf
listen=YES

# Disable anonymous access
anonymous_enable=NO

# Allow local users
local_enable=YES

# Allow uploads
write_enable=YES

# Restrict users to their home directory
chroot_local_user=YES
allow_writeable_chroot=NO

# Only allow users in /etc/vsftpd.userlist
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Passive mode (required for VPN/NAT)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
pasv_address=<YOUR_EC2_PUBLIC_IP>

# Logging
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
log_ftp_protocol=YES

# Permissions for uploaded files
local_umask=022

# Disable anonymous uploads explicitly
anon_upload_enable=NO
anon_mkdir_write_enable=NO
EOF

echo "ftpuser" | tee /etc/vsftpd.userlist

systemctl restart vsftpd
systemctl status vsftpd

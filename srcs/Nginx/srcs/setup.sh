#!/bin/bash

if [ ! -d "/var/www/html" ]; then
	mkdir -p var/www/html
fi

#create users for ssh and nginx
	adduser -D -g 'www' www
	adduser -D admin

#setting up nginx webserver user permissions to directories
	chown -R www:www /var/lib/nginx
	chown -R www:www /var/www/html
#setting up ssh server user and permissions
	echo "root:toor"|chpasswd

# generate the host keys with the default key file path,
	ssh-keygen -A

if [ ! -f /etc/ssl/certs/key.key -o ! -f /etc/ssl/certs/cer.crt ]; then
	# generate fresh ssl certificate and private key
	mkdir -p /etc/ssl/certs/
	openssl req -newkey rsa:2048 -nodes -keyout /etc/ssl/certs/key.key -x509 -days 365 -out /etc/ssl/certs/cer.crt -subj "/C=MA/ST=BENGUERIR/L=1337/O=ael-ghem/OU=IT Department/CN=Archi"
fi

#prepare nginx run dir
if [ ! -d "/run/nginx/" ]; then
	mkdir -p /run/nginx/
fi

#prepare openrc run dir
if [ ! -d "/run/openrc/" ]; then
  mkdir -p /run/openrc/
  touch /run/openrc/softlevel
fi

rc-update add sshd
nginx -t
rc-service nginx start
(/usr/sbin/sshd -D &)  && (nginx -g "daemon off;" &)
while true;	do
sleep 5
ret1="$(ps | grep sshd | grep -vc grep)"
ret2="$(ps | grep nginx | grep -vc grep)"
if [ $ret1 -eq 0 -o $ret2 -eq 0 ]; then
    echo "pod is unhealthy"
    break ;
else
    echo "pod is healthy"
fi
done

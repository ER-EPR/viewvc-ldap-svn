#!/bin/bash
# Initialize the configuration and start the web server.

DEFAULT_AUTH_NAME="SVN"

# Set the web server auth name for access
perl -pi -e "s/ +AuthName .+$/AuthName \"${AUTH_NAME:-$DEFAULT_AUTH_NAME}\"/g" /etc/apache2/sites-available/viewvc.conf

group=$(egrep "^[^:]+:[^:]+:${SVN_GID:-0}:" /etc/group | cut -d: -f 1)
if [ -z "$group" ]; then
        # Group with gid does not exist
        group="viewvc"
        addgroup --gid "$SVN_GID" "$group"
fi

user=$(egrep "^[^:]+:[^:]+:${SVN_UID:-0}:" /etc/passwd | cut -d: -f 1)
if [ -n "$user" ]; then
        # User with the uid already exists
        # Set the primary group for the existing user
        usermod -g "$group" "$user"
else
        # User with the uid does not exist and should be added
        user="viewvc"
        adduser --home "/svn" --no-create-home --gecos "" \
                --uid "${SVN_UID:-0}" --gid "${SVN_GID:-0}" \
                --disabled-password "$user"
fi

# Set the apache user and group
perl -pi -e "s/^export APACHE_RUN_USER=.+/export APACHE_RUN_USER=$user/g" /etc/apache2/envvars
perl -pi -e "s/^export APACHE_RUN_GROUP=.+/export APACHE_RUN_GROUP=$group/g" /etc/apache2/envvars
mkdir -p /var/lock/apache2 /var/run/apache2
chown -R "$user:$group" /var/lock/apache2 /var/run/apache2

# Start CRON 
service cron start

# Start apache2
. /etc/apache2/envvars
exec /usr/sbin/apache2 -D FOREGROUND

# Start apache
#/usr/sbin/apache2 -DFOREGROUND

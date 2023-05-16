#!/bin/bash

# Start CRON 
service cron start

# Start apache
/usr/sbin/apache2 -DFOREGROUND

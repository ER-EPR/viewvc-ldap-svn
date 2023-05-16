FROM ubuntu:latest
MAINTAINER xucong <shark_xc@hotmail.com>
ENV APACHE_RUN_USER    www-data
ENV APACHE_RUN_GROUP   www-data
ENV APACHE_PID_FILE    /var/run/apache2.pid
ENV APACHE_RUN_DIR     /var/run/apache2
ENV APACHE_LOCK_DIR    /var/lock/apache2
ENV APACHE_LOG_DIR     /var/log/apache2
# Install subversion and ldap apache
RUN apt-get -y update && apt-get install -y subversion apache2 libapache2-mod-svn libapache2-svn libsvn-dev
RUN apt-get -y update && apt-get install -y cron
RUN apt-get -y update && apt-get install -y python python-ldap
RUN /usr/sbin/a2enmod dav
RUN /usr/sbin/a2enmod dav_svn
RUN /usr/sbin/a2enmod ldap
RUN /usr/sbin/a2enmod authnz_ldap
RUN service apache2 restart
# Install websvn
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y viewvc \
    apache2-utils && \
    rm -rf /var/lib/apt/lists/*

# Set configuration
RUN perl -pi -e \
    's/^#root_parents\s*=.*$/root_parents = \/svn: svn/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#default_root\s*=.*$/default_root = svn/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#authorizer\s*=.*$/authorizer = svnauthz/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#authzfile\s*=.*$/authzfile = \/svn\/svn.authz/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#docroot\s*=.*$/docroot = \/docroot/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#log_pagesize\s*=.*$/log_pagesize = 20/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#max_filesize_kbytes\s*=.*$/max_filesize_kbytes = 1024/g' \
    /etc/viewvc/viewvc.conf

RUN perl -pi -e \
    's/^#allowed_views\s*=.*$/allowed_views = annotate, co, diff, markup, roots/g' \
    /etc/viewvc/viewvc.conf

# Add the viewvc apache configuration and enable the site
ADD viewvc.conf /etc/apache2/sites-available/
RUN a2enmod cgid expires auth_digest authz_groupfile && \
    a2dissite 000-default && a2ensite viewvc
    
# Set permissions
RUN addgroup subversion
RUN usermod -a -G subversion www-data
RUN chown -R www-data:subversion /svn
RUN chmod -R g+rws /svn
RUN touch /var/log/cron.log

RUN echo "0 * * * * /config/scripts/cron.sh > /dev/null 2>&1" >> /etc/crontab

COPY config/apache-default.conf /etc/apache2/sites-available/000-default.conf
COPY script/ldap_to_authz.py /ldap_to_authz.py
COPY script/start.sh /start.sh

# Configure Apache to serve up Subversion
RUN /usr/sbin/a2enmod auth_digest

# Add the start script
ADD start /opt/

# Archives and configuration are stored in /svn
VOLUME /svn
VOLUME /config
VOLUME /etc/cron.d

# Expose public port for web server
EXPOSE 80

# Initialize configuration and run the web server
CMD [ "/opt/start" ]

# CMD ["/start.sh"]

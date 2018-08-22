#!/bin/sh

log=/var/log/nextcloud-scb.log

err(){
    echo "$0: error: $@"
    exit 1
}

# https://docs.nextcloud.com/server/13/admin_manual/configuration_server/occ_command.html?highlight=command%20line
alias occ="runuser --user www-data -- /var/www/html/occ"

randstr(){
    strings /dev/urandom | grep -o '[a-zA-Z0-9]' \
        | head -n$1 | tr -d '\n'; echo
}

do_start(){
    admin_pass=$(randstr 30)
    user_pass=$(randstr 30)

    # entrypoint.sh from nextcloud base image, start Nextcloud
    /entrypoint.sh apache2-foreground 2>&1 | tee -a $log &
    sleep 5

    # same as the first login where we need to define the admin user
    occ maintenance:install --admin-user=admin --admin-pass=$admin_pass

    # remove annoying default files, rescan to inform the database, else we see
    # the files listed in the Files UI, we have to do it this way b/c the above
    # install does create the "occ" command along with then admin user and
    # /var/www/html/config/config.php so we cannot set this config before
    rm -rv /var/www/html/data/admin/files/*
    occ files:scan --all
    occ files:cleanup

    # disable default files for new users
    occ config:system:set --value '' skeletondirectory
    
    # create normal user
    export OC_PASS=$user_pass
    occ user:add --display-name="Johnny User" --password-from-env user
    # create data dir, this is normally created only after the first login but
    # we need it now such that we can run lsyncd afterwards
    mkdir -p /var/www/html/data/user/files
    chown -R www-data:root /var/www/html/data/user

    echo $admin_pass > /tmp/scb/admin_pass
    echo $user_pass > /tmp/scb/user_pass
}

do_stop(){
    for sig in 15 9; do
        pd=$(ps aux | awk '/[a]pache2/ {print $2}')
        [ -n "$pd" ] && kill -s $sig $pd
        sleep 2
    done
}

if [ "$1" = "start" ]; then
    do_start
elif [ "$1" = "stop" ]; then
    do_stop
elif [ "$1" = "restart" ]; then
    do_stop
    do_start
else
    err "illegal command"
fi

#!/bin/sh

# TODO: Check if one is root

trees="${trees}"
jails="${jails}"
sets="${sets}"

# TODO: Test if supplied input is correct -- otherwise: exit
pconfd=/usr/local/etc/poudriere.d
pdatad=/usr/local/poudriere
pbdir=/tmp/port-builder

# Ports trees
for t in $sets
do
    # TODO: Update existing (manged!) ports trees
    if [ ! -d $pdatad/ports/$t ]
    then
        echo
        echo "--> Creating ports tree: $t"
        echo

        if poudriere ports -l | tail +2 | cut -wf 1 | grep '^$t$' >/dev/null 2>&1
        then
            echo "--> Poudriere claims that ports tree exists but it doesn't."
            echo "    Deleting the ports tree in poudriere's cache..."
            poudriere -d -p $t
            echo
        fi
        poudriere ports -c -p $t
    fi

    # Copies user provided ports to ports tree
    test -d $pbdir/ports/$t && cp -vr $pbdir/ports/$t/* /usr/local/poudriere/ports/$t

    # If there are jails for ARM prepare for crossbuilding
    case "$jails" in
        *arm*)
            echo
            echo "--> Preparing for crossbuilding"
            echo

            # Sets crossbuilding flag
            crossbuilding="-x"

            # Gets /usr/src for building native-xtools
            fetch -o /tmp ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.0-RELEASE/src.txz
            tar -C / -xzvf /tmp/src.txz

            service qemu_user_static onestart &>/dev/null
            ;;
    esac

    for j in $jails
    do
        method=$(echo $j | cut -d '_' -f 1)
        name=$(echo $j | cut -d '_' -f 2)
        arch=$(echo $j | cut -d '_' -f 3)
        rel=$(echo $j | cut -d '_' -f 4)

        if [ ! -d $pdatad/jails/$j ]
        then
            echo
            echo "--> Creating jail: $name"
            echo "           method: $method"
            echo "     architecture: $arch"
            echo "          release: $rel"
            echo

            if poudriere jail -l | tail +2 | cut -wf 1 | grep '^$name$' >/dev/null 2>&1
            then
                echo "--> Poudriere claims that jail exists but it doesn't."
                echo "    Deleting the jail in pourdiere's cache..."
                poudriere -d -j $name
                echo
            fi

            # TODO: I am not sure whether this works bc of $crossbuilding flag at
            # the end
            poudriere jail -c -j $name -a $arch -v $rel -m $method $crossbuilding
        fi

        # Sets
        for z in $sets
        do
            echo
            echo "--> Building ports from list $pkglist"
            echo "                       tree: $t"
            echo "                       jail: $name"
            echo "                        set: $z"
            echo

            pkglist=$pbdir/pkglists/$t-$name-$z

            if [ -f $pkglist ]
            then
                poudriere bulk -p $t -j $name -z $z -f $pkglist
            else
                echo "Cannot build ports: No pkglist provided for above combination."
            fi
        done
    done
done

upload-to-s3

# vim:set ft=sh:

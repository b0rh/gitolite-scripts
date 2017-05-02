#!/bin/bash

# b0rh <francisco@garnelo.eu>
# https://github.com/b0rh/gitolite-scripts/


# Usage:  ./add_usr_gitrepo.sh <user> <repository>

# NOTE: Check that gitolite.conf is configure with admin group and root.pub key was exists in keydir

# gitolite.conf ---
# @admin       =  root
# repo gitolite-admin
#     RW+      =  @admin
# 
## ## ## ## ## ## ##

# Enviroment configurations
USR=$1
REPO=$2
KEYSTORE="/root/KEYS"
USRKEYPATH="$KEYSTORE/$1@git-mysite"


# Repository ssh access configurations
GITUSR=git
HOST=127.0.0.1
EXTHOST="mysite.tld/X.X.X.X"
PORT=282
GITOLITEREPO=gitolite-admin

GITURI="ssh://${GITUSR}@${HOST}:${PORT}/${GITOLITEREPO}.git"


# Clones administration repo
cd /tmp
rm /tmp/$GITOLITEREPO -rf 2>&1 > /dev/null  
git clone -q $GITURI
    
# Checks existence
#TODO: Put in functions and use local variables 
if [ -f $USRKEYPATH ]; # Exists user keys
then
    echo "WARNING: User keys ${USRKEYPATH}.pub and ${USRKEYPATH} exists, remove first if you want update."
else # Non exists user keys
    echo "Generating $USR keys .."
    #Generate user pair (priveate & public keys)
    ssh-keygen -b 2048 -t rsa -f $USRKEYPATH -q -N "mahou5*"
    
    # Copies/Updates new public key
    rm /tmp/$GITOLITEREPO/keydir/${USR}.pub -rf  2>&1 > /dev/null  
    cp ${USRKEYPATH}.pub /tmp/$GITOLITEREPO/keydir
fi    
    
   
# Sets permission access
# TODO: Put in functions and use local variables 
_gitolitePatchConf="/tmp/$GITOLITEREPO/conf/gitolite.conf"

# TODO: Add init function with this to enable group access to gitolite administration
#    cat << "-- EOF --" > $_gitolitePatchConf
#@admin       =  root
#  
#repo gitolite-admin
#    RW+      =  @admin
#-- EOF --

chmod 644 $_gitolitePatchConf
    
#if grep -q "@${REPO}-grp" $_gitolitePatchConf ; then # Exists Repository

if grep -q "^@${REPO}-grp.*=.*$" $_gitolitePatchConf ; then # Exists Repository    
    if grep -q "^@${REPO}-grp.*${USR}.*$" $_gitolitePatchConf ; then  # Exists user access in repository
        echo " WARNNING: Exists user $USR access to $REPO "
    else # Non Exists user access in repository
        # Add user
        sed "/\(^@${REPO}-grp.*=.*$\)/ s/$/ ${USR}/" $_gitolitePatchConf  > ${_gitolitePatchConf}.new
        rm $_gitolitePatchConf
        mv ${_gitolitePatchConf}.new $_gitolitePatchConf
        #sed "/\(^@${REPO}-grp.*$\)/ s/$/ ${USR}/" $_gitolitePatchConf 
        echo "Added user $USR to repository $REPO."
    fi
else # Non Exists Repository
     # Create repository and user access
    echo -e "@${REPO}-grp       =  $USR\n$(cat $_gitolitePatchConf)" > $_gitolitePatchConf
    echo -e "\nrepo ${REPO}\n    RW+      =  @${REPO}-grp\n" >> $_gitolitePatchConf
    echo "Created group and added user $USR to repository $REPO."
fi

cd  /tmp/$GITOLITEREPO
git config --global user.name "GIT admin"
git config --global user.email root@gitrepo
git config --global push.default simple
git add conf
git add keydir
git commit -q -a -m "$0 : Grant RW access to user $USR in repository $REPO."
git push -q
cd ..
rm /tmp/$GITOLITEREPO -rf 2>&1 > /dev/null

echo "DONE"

# Updates URI to use with external ip
CLIGITURI="ssh://${GITUSR}@${EXTHOST}:${PORT}/${REPO}.git"

cat << EOF

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

Repository URI: $CLIGITURI
Public key: ${USRKEYPATH}.pub

$(cat ${USRKEYPATH}.pub)

Private key: ${USRKEYPATH}

$(cat ${USRKEYPATH})

EOF

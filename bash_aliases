#!/bin/bash

alias df='df -h| grep -vE " /snap|^tmpfs"'

alias tmux=byobu
alias termbin='nc termbin.com 9999'

. ~/.devhelpers/git-helpers
. ~/.devhelpers/bzr-helpers
. ~/.devhelpers/juju-helpers
. ~/.devhelpers/go-helpers
if [[ -e /usr/share/virtualenvwrapper/virtualenvwrapper.sh ]]; then
    . /usr/share/virtualenvwrapper/virtualenvwrapper.sh
fi

alias open='xdg-open'
alias jbs='juju bootstrap --config test-mode=true'

#function jbs() {
#    jenv=${1-$(juju switch)}
#    shift
#    if [[ "$jenv" == aws* ]]; then
#        juju bootstrap --constraints "instance-type=m3.medium" "$@"
#    else
#        juju bootstrap "$@"
#    fi
#}

function jres() {
    services="$(juju pprint | sed -e 's/^- \([^\/]*\).*/\1/')"
    machines="$(juju status | grep machine: | sed -e 's/.*"\(.*\)"/\1/' | sort | uniq)"
    for s in $services; do
        juju remove-service $s
    done
    for m in $machines; do
        juju remove-machine --force $m
    done
    ~/bin/juju-machine-count > ~/.juju/.machine-count
}

unset -f jv
function jv() {
    # Select juju version using update-alternatives
    version=$1
    juju_alternatives=($(update-alternatives --list juju))
    selected=${juju_alternatives[$(expr $version - 1)]}
    sudo update-alternatives --set juju $selected
}

#alias cfendpoint='juju status haproxy | grep public-address | sed -e "s/.*: //"'
#alias cfdomain='cfendpoint | sed -e "s/ec2-\([^.]*\).*/\1/" | tr - . | sed -e "s/$/.xip.io/"'
#alias cfadminpass='juju run --unit uaa/0 "relation-get -r \$(relation-ids credentials) admin-password cloudfoundry/0"'
#alias cflogin='juju expose haproxy && cf api http://api.`cfdomain` && cf auth admin `cfadminpass` && cf create-space -o juju-org my-space && cf target -o juju-org -s my-space'
#function cfdep() {
#    jd local:trusty/cloudfoundry && juju set cloudfoundry admin_secret=`juju-secret` placement=dense generate_dependents=true "$@" && watch juju pprint -a
#}
function cfswitch() {
    (cd ~/juju/charms/trusty; rm -f cloudfoundry; ln -s ../../cf/$1 cloudfoundry)
}

unalias rqd 2> /dev/null
unset -f rqd
function rqd() {
    image='jujusolutions/charmbox'
    branch='devel'
    net=''
    jr=$HOME/juju/envs/rq
    while [[ $# > 0 ]]; do
        case "$1" in
            -l) branch='latest'
                net='--net=host'
                shift ;;
            -d) branch='devel'
                net=''
                shift ;;
            -c) image='seman/cwrbox'
                branch='latest'
                net=''
                shift ;;
            -e) jr="$JR"
                shift ;;
            *) break
        esac
    done
    deployer_cache=/tmp/deployer-store-cache-$$
    mkdir $deployer_cache
    chmod a+wx $deployer_cache
    docker run $net --rm \
               --detach-keys 'ctrl-l,d' \
               -v ${HOME}/.go-cookies:/home/ubuntu/.go-cookies \
               -v ${HOME}/.bashrc:/home/ubuntu/.bashrc \
               -v ${HOME}/.bash_aliases:/home/ubuntu/.bash_aliases \
               -v ${HOME}/.devhelpers:/home/ubuntu/.devhelpers \
               -v ${HOME}/.vimrc:/home/ubuntu/.vimrc \
               -v ${HOME}/.vim:/home/ubuntu/.vim \
               -v ${HOME}/bin:/home/ubuntu/bin \
               -v ${HOME}/lib/liquidprompt:/home/ubuntu/lib/liquidprompt \
               -v ${HOME}/.config/liquidpromptrc:/home/ubuntu/.config/liquidpromptrc \
               -v ${HOME}/.config/liquid.ps1:/home/ubuntu/.config/liquid.ps1 \
               -v ${HOME}/.juju-plugins:/home/ubuntu/.juju-plugins \
               -v ${HOME}/.local/share/juju:/home/ubuntu/.local/share/juju \
               -v ${JUJU_HOME}:/home/ubuntu/.juju \
               -v $deployer_cache:/home/ubuntu/.juju/.deployer-store-cache \
               -v $jr/builds:/home/ubuntu/builds \
               -v $jr/xenial:/home/ubuntu/xenial \
               -v $jr/trusty:/home/ubuntu/trusty \
               -v $jr/precise:/home/ubuntu/precise \
               -v $jr/bundle:/home/ubuntu/bundle \
               -v $jr/layers:/home/ubuntu/layers \
               -v $jr/interfaces:/home/ubuntu/interfaces \
               -v /var/tmp/cwr-reports:/var/tmp/cwr-reports \
               "$@" \
               -it $image:$branch
    rm -rf $deployer_cache
}

unalias rq 2> /dev/null
unset -f rq
function rq() {
    jr=$HOME/juju/envs/rq
    deployer_cache=/tmp/deployer-store-cache-$$
    mkdir $deployer_cache
    chmod a+wx $deployer_cache
    #lxc launch ubuntu:16.10 cwrbox
    lxc launch cwrbox cwrbox
    {
        lxc-mount cwrbox ${HOME}/.bashrc                  /home/ubuntu/.bashrc
        lxc-mount cwrbox ${HOME}/.bash_aliases            /home/ubuntu/.bash_aliases
        lxc-mount cwrbox ${HOME}/.devhelpers              /home/ubuntu/.devhelpers
        lxc-mount cwrbox ${HOME}/.vimrc                   /home/ubuntu/.vimrc
        lxc-mount cwrbox ${HOME}/.vim                     /home/ubuntu/.vim
        lxc-mount cwrbox ${HOME}/bin                      /home/ubuntu/bin
        lxc-mount cwrbox ${HOME}/lib/liquidprompt         /home/ubuntu/lib/liquidprompt
        lxc-mount cwrbox ${HOME}/.config/liquidpromptrc   /home/ubuntu/.config/liquidpromptrc
        lxc-mount cwrbox ${HOME}/.config/liquid.ps1       /home/ubuntu/.config/liquid.ps1
        lxc-mount cwrbox ${HOME}/.juju-plugins            /home/ubuntu/.juju-plugins
        lxc-mount cwrbox ${HOME}/.local/share/juju        /home/ubuntu/.local/share/juju
        lxc-mount cwrbox ${HOME}/.go-cookies              /home/ubuntu/.go-cookies
        lxc-mount cwrbox ${JUJU_HOME}                     /home/ubuntu/.juju
        lxc-mount cwrbox $deployer_cache                  /home/ubuntu/.juju/.deployer-store-cache
        lxc-mount cwrbox $jr/builds                       /home/ubuntu/builds
        lxc-mount cwrbox $jr/xenial                       /home/ubuntu/xenial
        lxc-mount cwrbox $jr/trusty                       /home/ubuntu/trusty
        lxc-mount cwrbox $jr/precise                      /home/ubuntu/precise
        lxc-mount cwrbox $jr/bundle                       /home/ubuntu/bundle
        lxc-mount cwrbox $jr/layers                       /home/ubuntu/layers
        lxc-mount cwrbox $jr/interfaces                   /home/ubuntu/interfaces
        lxc-mount cwrbox /var/tmp/cwr-reports             /var/tmp/cwr-reports
        #lxc exec cwrbox -- mkdir -p /home/ubuntu/.ssh
        lxc file push ${HOME}/.ssh/launchpad.pub          cwrbox/home/ubuntu/.ssh/authorized_keys
    } > /dev/null
    until lxc exec cwrbox service sshd status > /dev/null; do
        sleep 0.5
    done
    ip=$(lxc info cwrbox | grep -E 'eth0:\sinet\s' | awk '{print $3}')
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$ip
    lxc delete --force cwrbox
    rm -rf $deployer_cache
}

unset -f promulgate
function promulgate() {
    charm_id=${1#cs:}
    promulgated=${2:-true}
    bhttp put -j https://api.jujucharms.com/charmstore/v5/$charm_id/promulgate Promulgated:=$promulgated
}

unset -f lxc-mount
function lxc-mount() {
    container=$1
    src="$2"
    dst="$3"
    device_name=$(basename $src | sed -e 's/[^A-Za-z0-9]/_/g')
    lxc config set $container raw.idmap 'both 1000 1000'
    lxc config device add $container $device_name disk source="$src" path="$dst"
}

unset -f clean-models
function clean-models() {
    if [[ -z "$1" ]]; then
        >&2 echo "Must provide a pattern"
        return 1
    fi
    for model in `juju models --format=json | jq -r '.models[].name' | grep "$1"`; do
        echo -n "Cleaning $model..."
        timeout 60s juju destroy-model --destroy-storage -y $model 2> /dev/null
        if [[ $? == 124 ]]; then
            echo " timed out"
        else
            echo " done"
        fi
    done
}

unalias maas-tunnel 2> /dev/null
unset -f maas-tunnel
function maas-tunnel() {
    cmd=${1:-start}
    shift
    sshoot $cmd maas-tunnel "$@"
}

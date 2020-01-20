HISTSIZE=10000
HISTFILESIZE=20000
#PROMPT_COMMAND='history -a; history -c; history -r'

export PS1='\[\033]0;\u@\h:\w\007\][\[\e[1;32m\]\u@\h\[\e[0m\] \[\e[1;34m\]\W\[\e[0m\]\[$(git_color)\]$(git_branch_p)\[\e[0m\]] \$ '
export PROMPT_DIRTRIM=2
[[ $- = *i* ]] && source ~/.devhelpers/liquidprompt/liquidprompt

export CHARM_BUILD_DIR=/home/johnsca/juju/build
export CHARM_CHARMS_DIR=/home/johnsca/juju/charms
export CHARM_LAYERS_DIR=/home/johnsca/juju/layers
export CHARM_INTERFACES_DIR=/home/johnsca/juju/interfaces
export CHARM_BUNDLES_DIR=/home/johnsca/juju/bundles
export CBD=$CHARM_BUILD_DIR
export CCD=$CHARM_CHARMS_DIR
export CLD=$CHARM_LAYERS_DIR
export CID=$CHARM_INTERFACES_DIR
export CBND=$CHARM_BUNDLES_DIR

export PATH=$PATH:/home/johnsca/go/bin

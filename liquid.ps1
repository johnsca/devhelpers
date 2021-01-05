
#######################################
# LIQUID PROMPT DEFAULT TEMPLATE FILE #
#######################################

# Available features:
# LP_BATT battery
# LP_LOAD load
# LP_JOBS screen sessions/running jobs/suspended jobs
# LP_USER user
# LP_HOST hostname
# LP_PERM a colon ":"
# LP_PWD current working directory
# LP_PROXY HTTP proxy
# LP_VCS the content of the current repository
# LP_ERR last error code
# LP_MARK prompt mark
# LP_TIME current time
# LP_RUNTIME runtime of last command
# LP_PS1_PREFIX user-defined general-purpose prefix (default set a generic prompt as the window title)

# Remember that most features come with their corresponding colors,
# see the README.

if (( LP_ENABLE_GIT )); then
    local branch
    branch="$(_lp_git_branch)"
    if [[ -n "$branch" ]]; then
        local changes
        local remote
        local remote_branch
        local commit_ahead
        local commit_behind
        changes="$(git diff --shortstat HEAD 2>/dev/null)"
        remote="$(\git config --get branch.${branch}.remote 2>/dev/null)"
        if [[ -n "$remote" ]]; then
            remote_branch="$(\git config --get branch.${branch}.merge)"
            if [[ -n "$remote_branch" ]]; then
                commit_ahead="$(\git rev-list --count $remote_branch..HEAD 2>/dev/null)"
                commit_behind="$(\git rev-list --count HEAD..$remote_branch 2>/dev/null)"
            fi
        fi
        local vcs_color
        if [[ -n "$changes" ]]; then
            vcs_color="$LP_COLOR_CHANGES"
        elif [[ "$commits_ahead" -ne "0" ]]; then
            vcs_color="$LP_COLOR_COMMITS"
        elif [[ "$commits_behind" -ne "0" ]]; then
            vcs_color="$LP_COLOR_COMMITS_BEHIND"
        else
            vcs_color="$LP_COLOR_UP"
        fi
        LP_VCS=" ${vcs_color}${branch}${NO_COL}"
    fi
fi

# add time, jobs, load and battery
LP_PS1="${LP_PS1_PREFIX}${LP_TIME}${LP_BATT}${LP_LOAD}${LP_JOBS}"
# add user, host and permissions colon
LP_PS1="${LP_PS1}[${LP_USER}${LP_HOST}${LP_PERM}"

LP_JENV=" $(juju-current-model)"

# if not root
if [[ "$EUID" -ne "0" ]]
then
    # path in foreground color
    LP_PS1="${LP_PS1}${LP_PWD}]${LP_VENV}${LP_JENV}"
    # add VCS infos
    LP_PS1="${LP_PS1}${LP_VCS}"
    LP_MARK='$'
else
    # path in yellow
    LP_PS1="${LP_PS1}${LP_PWD}]${LP_VENV}${LP_JENV}${LP_PROXY}"
    # do not add VCS infos unless told otherwise (LP_ENABLE_VCS_ROOT)
    [[ "$LP_ENABLE_VCS_ROOT" = "1" ]] && LP_PS1="${LP_PS1}${LP_VCS}"
    LP_MARK='#'
fi
# add return code and prompt mark
LP_PS1="${LP_PS1}${LP_RUNTIME}${LP_ERR} ${LP_MARK} "

# "invisible" parts
# Get the current prompt on the fly and make it a title
LP_TITLE=$(_lp_title $PS1)

# Insert it in the prompt
PS1="${LP_TITLE}${PS1}"

# vim: set et sts=4 sw=4 tw=120 ft=sh:

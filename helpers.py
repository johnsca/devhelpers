#!/usr/bin/env python

import sys
import re
import os
import imp

COMMANDS = ['story_from_branch', 'format_commit_message', 'git_opts']

config = None  # loaded below


def story_from_branch(branch_name):
    """Usage: %s story_from_branch BRANCH_NAME"""
    story_number = re.search(config.BRANCH_PATTERN, branch_name)
    if story_number is not None:
        print story_number.group(1)
    else:
        print >> sys.stderr, 'Fatal: Could not get story number from branch'

def format_commit_message(story_num, message):
    """Usage: %s format_commit_message STORY_NUM MESSAGE"""
    print config.COMMIT_PATTERN.format(
        story_num=story_num,
        message=message,
    )

def git_opts():
    print config.GIT_OPTS


class Config(object):
    BRANCH_PATTERN = r'^\w{2,3}/(\d+)'
    COMMIT_PATTERN = '[#{story_num}] {message}'
    GIT_OPTS = ''

    def __init__(self):
        self.load_rcfile(self.find_rcfile())

    def find_rcfile(self):
        with os.popen('git rev-parse --show-toplevel') as p:
            gitdir = p.readline().rstrip('\n') + '/.git'
        usrdir = os.path.expanduser('~')
        for rcfile in [gitdir+'/.dhrc', usrdir+'/.dhrc', None]:
            if rcfile is None or os.path.exists(rcfile):
                break
        return rcfile

    def load_rcfile(self, rcfile):
        if rcfile is None:
            return
        rc = imp.load_source('devhelpers_rc', rcfile)
        for p in dir(rc):
            if not p.startswith('__'):
                setattr(self, p, getattr(rc, p))

if __name__ == "__main__":
    if len(sys.argv) <= 1:
        print >> sys.stderr, 'Usage: %s COMMAND OPTIONS ...'
        sys.exit(1)

    config = Config()

    prop = sys.argv[1]
    func = globals().get(prop, None)
    if prop not in COMMANDS or not callable(func):
        print >> sys.stderr, 'ERROR: Unknown command: '+prop
        sys.exit(1)
    try:
        func(*sys.argv[2:])
    except TypeError:
        print >> sys.stderr, func.__doc__ % sys.argv[0]
        sys.exit(1)

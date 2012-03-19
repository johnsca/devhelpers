#!/usr/bin/env python

import sys
import re

from config import Config

COMMANDS = ['help', 'story_from_branch', 'format_commit_message', 'git_opts']

config = Config()


def _argnames(func):
    if callable(func):
        return ' '.join([n.upper() for n in func.func_code.co_varnames[:func.func_code.co_argcount]])
    else:
        return ''


def help():
    '''Displays this help message.'''
    print 'Usage: %s COMMAND OPTIONS'
    print
    print 'The available COMMANDS are:'
    for command in COMMANDS:
        func = globals().get(command, None)
        if callable(func):
            print '    %-40s    %s' % (command + ' ' + _argnames(func), func.__doc__)
        else:
            print "    %-40s    Returns the value for %s (currently '%s')" % (command, command.upper(), resolve(command))

def story_from_branch(branch_name):
    '''Extracts the story number from a branch name, based on the conventions defined in the .dhrc file.'''
    story_number = re.search(config.BRANCH_PATTERN, branch_name)
    if story_number is not None:
        print story_number.group(1)
    else:
        print >> sys.stderr, 'Fatal: Could not get story number from branch'

def format_commit_message(story_num, message):
    '''Formats a commit message, given a story number, based on the conventions defined in the .dhrc file.'''
    print config.COMMIT_PATTERN.format(
        story_num=story_num,
        message=message,
    )

def resolve(prop):
    '''Resolves a basic property and sends it back to the user.'''
    return getattr(config, prop.upper(), '')


if __name__ == "__main__":
    if len(sys.argv) <= 1:
        help()
        sys.exit(1)

    prop = sys.argv[1]
    args = sys.argv[2:]
    if prop not in COMMANDS:
        print >> sys.stderr, 'Fatal: Unknown command: '+prop
        help()
        sys.exit(1)

    func = globals().get(prop, None)
    argcount = func.func_code.co_argcount if callable(func) else 0
    if len(args) != argcount:
        print >> sys.stderr, 'Usage: %s %s %s' % (sys.argv[0], prop, _argnames(func))
        sys.exit(1)

    if callable(func):
        func(*args)
    else:
        print resolve(prop)

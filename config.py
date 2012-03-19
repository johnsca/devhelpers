import os
import imp


class Config(object):
    BRANCH_PATTERN = r'^\w{2,3}/(\d+)'
    COMMIT_PATTERN = '[#{story_num}] {message}'
    BASE_BRANCH = 'master'

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

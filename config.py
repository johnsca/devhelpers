import os
from importlib.machinery import SourceFileLoader


class Config(object):
    BRANCH_PATTERN = r'^\w{2,3}/(\d+)'
    COMMIT_PATTERN = '[#{story_num}] {message}'
    BASE_BRANCH = None

    def __init__(self):
        self.load_rcfile(self.find_rcfile())
        with os.popen('git config repo.defaultbranch') as p:
            repo_default = p.read().strip()
        with os.popen('git branch --list main') as p:
            repo_main = p.read().strip()
        with os.popen('git branch --list master') as p:
            repo_master = p.read().strip()
        with os.popen('git config init.defaultbranch') as p:
            init_default = p.read().strip()
        self.BASE_BRANCH = repo_default or repo_main or repo_master or init_default or "master"
        if self.BASE_BRANCH.startswith("* "):
            self.BASE_BRANCH = self.BASE_BRANCH[2:]

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
        rc = SourceFileLoader('devhelpers_rc', rcfile).load_module()
        for p in dir(rc):
            if not p.startswith('__'):
                setattr(self, p, getattr(rc, p))

#!/usr/bin/env python
import irclib
import sys
import os
import time
from getopt import getopt
from datetime import datetime
from subprocess import Popen, PIPE
import readline
import re
import urllib2
import json

from git import Repo, GitCommandError
from rbtools.postreview import ReviewBoardServer, SCMCLIENTS

import rbtools.postreview


AGILEZEN_KEY = '108dd82a8d1b40d99289ef6e9cfc2a6c'
AGILEZEN_PROJECT_ID = '17041'
AGILEZEN_URL = 'https://agilezen.com/api/v1/projects/%s/' % AGILEZEN_PROJECT_ID

IRC_SERVER = 'irc.nextowntech.com'

def post_az_comment(story_number, text):
    print 'Posting to AZ story %s... ' % story_number,
    request = urllib2.Request(AGILEZEN_URL + 'stories/%s/comments' % story_number,
        headers={'X-Zen-ApiKey': AGILEZEN_KEY,
                 'Content-Type': 'application/json'},
        data=json.dumps({'text': text})
        )
    contents = urllib2.urlopen(request).read()
    data = json.loads(contents)
    print 'Done'

class rb_options(object):
    username = None
    password = None
    debug = False
    diff_filename = None
rbtools.postreview.options = rb_options()

DEBUG=False
AUTO_POST=False
OPEN_BROWSER=True
USE_COLORS=True
FORCE=False
try:
    from termcolor import colored
except ImportError, e:
    print "Unable to use colors: {0}".format(e)
    USE_COLORS=False

COLORS = {
    'review': 'green',
    'sha': 'green',
    'date': None,
    'author': 'cyan',
    'message': None,
    'diff-prompt': 'yellow',
    'details-prompt': 'yellow',
    'details': 'magenta',
    'warning': 'magenta',
}

def main(argv):
    opts, args = getopt(argv, 'u:df')
    opts = dict(opts)

    if '-f' in opts:
        global FORCE
        FORCE = True

    repo = Repo('.')

    global REVIEW_BOARD_URL
    REVIEW_BOARD_URL = repo.config_reader().get('reviewboard', 'url')

    diff_against_branch = 'master'
    if not update_diff_against_branch(diff_against_branch, repo):
        return

    if not check_pushed(repo):
        return

    commits = [commit for commit in repo.iter_commits('{0}..'.format(diff_against_branch), no_merges=True)]

    if not commits:
        print "Nothing new to post."
        return


    update_review = get_update_review(opts, repo.head.ref.name)
    options = collect_options(repo, commits, update_review)
    if options:
        review_id = post_review(diff_against_branch, options)
        if not review_id:
            return

        review_url = '%s/r/%s' % (REVIEW_BOARD_URL.rstrip('/'), review_id)
        story_number = get_story_number(repo)

        post_az_comment(story_number,
            'Review request {0}: {1}'.format('changed' if update_review else 'posted', review_url))

        post_message_on_irc(
            'hey guys, please review #{0} at {1}'.format(
                story_number,
                review_url,
            )
        )

def check_pushed(repo):
    if FORCE:
        return True
    branch = repo.head.ref # store current HEAD
    if repo.git.log('origin/{0}..HEAD'.format(branch)):
        print 'You have unpushed changes.  You must push before posting a review'
        return False
    return True

def update_diff_against_branch(diff_against_branch, repo):
    if FORCE:
        return True
    if repo.is_dirty():
        print 'You have uncommitted changes.  You must commit or stash before posting a review'
        return False
    branch = repo.head.ref # store current HEAD
    if diff_against_branch is None:
        print 'Iteration branch {0} has not yet been created'.format(diff_against_branch)
        return False
    print 'Bringing {0} up to date...'.format(diff_against_branch),
    sys.stdout.flush()
    repo.git.checkout(diff_against_branch)
    repo.git.pull()
    repo.git.checkout(branch.name)
    print 'done.\n'
    if len(list(repo.iter_commits('..{0}'.format(diff_against_branch), no_merges=True))) > 0:
        print 'Your branch is behind {0}.  Please run update'.format(diff_against_branch)
        return False
    return True

def get_iter_branch(repo):
    iter_num = datetime.now().strftime('%U')
    for branch in repo.heads:
        if branch.name.startswith('iteration/{0}-'.format(iter_num)):
            return branch.name
    return None

def short_sha(repo, rev):
    return repo.git.rev_parse(rev, short=True)

def get_message(commit):
    return commit.message.split('\n')[0]

def get_review(commit):
    try:
        return commit.repo.git.notes('show', commit.hexsha, ref='review')
    except GitCommandError, e:
        if 'No note found' in e.stderr:
            return None
        else:
            raise e

def get_update_review(opts, branch):
    if '-u' in opts:
        review_data = get_existing_review_data(review_id=opts['-u'])
    else:
        review_data = get_existing_review_data(branch=branch)

    if not review_data:
        print color('New review', 'details-prompt')
    else:
        title = review_data['summary']
        print '{0}{1} - {2} (link: {3})\n'.format(
            color('Updating existing review #', 'details-prompt'),
            color(review_data['id'], 'review'),
            color(review_data['summary'], 'review'),
            color("{0}/r/{1}/".format(REVIEW_BOARD_URL, review_data['id']), 'details-prompt')
        )

    return review_data

def get_existing_review_data(review_id=None, branch=None):
    if 'APPDATA' in os.environ:
        homepath = os.environ['APPDATA']
    elif 'HOME' in os.environ:
        homepath = os.environ["HOME"]
    else:
        homepath = ''
    cookie_file = os.path.join(homepath, ".post-review-cookies.txt")
    rb = ReviewBoardServer(REVIEW_BOARD_URL, SCMCLIENTS[2], cookie_file)
    rb.has_valid_cookie() # load cookie
    if review_id != None:
        return rb.get_review_request(review_id)
    else:
        results = filter(lambda r: r['branch'] == branch, rb.api_get('/api/review-requests')['review_requests'])
        return results[0] if results else None

def get_story_number(repo):
    match = re.search(r'(?:i/\d+|story)/\w+/(\d+)-', repo.head.ref.name)
    if match:
        return match.group(1)
    return None

def collect_options(repo, commits, update_review):
    descriptions = [u'{0} - {1}  '.format(short_sha(repo, commit.hexsha), get_message(commit)) for commit in commits]
    options = {
        'summary': repo.head.ref.name,
        'description': '\n'.join(descriptions),
        'target-group': 'tech',
        'branch': repo.head.ref.name,
    }

    story = get_story_number(repo)
    if story:
        options['bugs-closed'] = story

    if update_review:
        # collect existing additional description
        old_descriptions = update_review['description'].split('\n')
        while old_descriptions and old_descriptions[0] != '':
            del old_descriptions[:1]
        descriptions += old_descriptions

        options['review-request-id'] = update_review['id']
        options['summary'] = update_review['summary']
        options['description'] = '\n'.join(descriptions)

    just = lambda s: '{0:13}'.format(s)
    print '{0} {1}'.format(color(just('Summary:'), 'details'), options['summary'])
    for i, desc in enumerate(descriptions):
        print u'{0} {1}'.format(color(just('Description:' if i == 0 else ''), 'details'), desc)
    print ''

    post = raw_input('{0} [Y/n] '.format(color('Post?', 'details-prompt'))).lower()
    if not post.startswith('n'):
        return [u'--{0}={1}'.format(k,v) for (k,v) in options.items()]
    else:
        return False

def post_review(diff_against_branch, options):
    options.append('--revision-range={0}:HEAD'.format(diff_against_branch))
    if AUTO_POST:
        options.append('-p')
    if OPEN_BROWSER:
        options.append('-o')
    if DEBUG:
        options.append('-n')
        options.append('--output-diff')
    proc = Popen(['post-review'] + options, stdout=PIPE)
    output = []
    for line in proc.stdout:
        print line,
        output.append(line)
    proc.wait()
    if proc.returncode == 0 and not DEBUG:
        for o in output:
            found = re.search(r'Review request #(\d+)', o)
            if found:
                return found.group(1)
    else:
        return None

def color(text, type):
    if USE_COLORS:
        text = colored(text, COLORS.get(type, None))
    return text

def post_message_on_irc(message, channels=None):
    irc = irclib.IRC()
    server = irc.server()
    print "connecting to " + IRC_SERVER
    server.connect(
        IRC_SERVER, 6667,
        'reviewboard',
        ircname='rb-%s' % os.getenv('USER', 'developer'),
    )
    if not channels:
        channels = ['#dev']

    for channel in channels:
        print "joining %s" % channel
        server.join(channel, 'dOSO83uK')
        print "asking devs to review the current story"
        server.privmsg(channel, message)
        server.process_data()
        time.sleep(1)

    print "disconnecting from irc"
    time.sleep(1)
    server.disconnect()

if __name__ == '__main__':
    main(sys.argv[1:])


DevHelpers Project
##################

This project is for holding scripts, etc, that are intended to help with the
development workflow, without being specific to any one project.

Anything related to ReviewBoard, AgileZen, GitHub, etc, should go here, while
anything that is tied to a specific project (such as a command-line interface
to the signup API on the bidsite project, for example) belongs with the
specific project that it is tied to.  (Since, if the API were to change, the
helper tied to that API would need to change at the same time to continue
working, whereas prw, for example, will change independently of any changes to
the bidsite project.)


List of Helpers in this Repo
============================

git-helpers, qa-helpers::
    These provide shortcuts and aliases that make working with git easier,
    enforce consistent branch naming and commit message standards, running
    tests easier, etc.

    To use these, you must source them from your .profile or .bashrc file:

        source ~/devhelpers/git-helpers
        source ~/devhelpers/qa-helpers

    It is likely that most, if not all, of qa-helpers might better belong
    in the bidsite project.

prw::
    This is a wrapper around post-review that handles generating the diff
    for you based on the differences between your branch and master, as well
    as filling in most of the fields on the review automatically.  To use,
    just run it from within your project directory.  I recommend setting up an
    alias so you don't have to type the full path:

        alias prw=~/devhelpers/prw

    Then you can just run it with:

        prw

    You should only need to confirm the list of commits to be included in the
    review and hit enter.  prw will post the review to Review Board (updating
    the review if it already exists), and it will post to IRC letting the devs
    know that they need to take a look at it.

    prw does require that you have all of your changes committed and pushed,
    and that you're up-to-date with any changes in master before you can post
    the review.

reviewboard.user.js::
    This is a UserScript (a.k.a. GreaseMonkey script) that fades out reviews
    on the main listing on Review Board if they have already been merged to
    dev or master.  This makes it much easier to see which reviews need
    attention and which can probably be ignored (assuming the dev prefix
    is removed if the story is sent back).

    Screenshots are available at:

    * Before: http://i.imgur.com/zFetc.png
    * After: http://i.imgur.com/Q4re4.png

    This should work in either Chrome or FireFox (if you have the GreaseMonkey
    extension installed).

    To use this in Chrome, just drag the file into any Chrome window and it
    will prompt you to confirm that you wish to install it.

    To use this in FireFox, once you have GreaseMonkey installed, navigate
    the browser to the file and it should prompt you to install it.  (Dragging
    the file into a window will probably work, too.)

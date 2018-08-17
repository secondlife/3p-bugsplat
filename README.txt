BugsplatMac updates
-------------------

On 2018-08-15, we were notified by mail of a new BugsplatMac drop 1.0.4 on
GitHub: https://github.com/BugSplatGit/BugsplatMac

Before today we'd been using the prebuilt Mac binary framework provided by
BugSplat, so had to build this one ourselves.

Per https://www.bugsplat.com/docs/platforms/os-x, I installed Carthage (which
is supported by macports as well as homebrew:
sudo port install carthage)
and added the present Cartfile with contents as recommended.

FIRST -- VERY IMPORTANT!!
hg update vendor

We DO have patches to the BugsplatMac.framework, notably to the
upload-archive.sh script in its Resources directory. I've already been through
losing the Linden patches due to unpacking a vendor drop before switching to
the vendor branch, and having to restore them to the source repo from an
earlier autobuild package tarball.

Although the BugSplat page mentioned above says simply to run 'carthage', the
Carthage Quick Start documentation https://github.com/Carthage/Carthage says
to run 'carthage update', which I did.

This overwrote the contents of Carthage/Build/Mac/BugsplatMac.framework.
Happily, since that's what was packaged in the previous BugSplat binary
framework drops, that was exactly right. I committed that on branch 'vendor'
and merged to branch 'default'.

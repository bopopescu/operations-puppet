This is a fork of the Wikimedia Foundation's
[operations/puppet](https://gerrit.wikimedia.org/r/gitweb?p=operations/puppet.git;a=summary)
repository.  The analytics branch is where development is being
done for puppetization of the Analytics team's
[Kraken](https://www.mediawiki.org/wiki/Analytics/Kraken) data services
platform.

You probably shouldn't clone this repository from github.  Instead,
clone the WMF hosted gerrit version, and then fetch from the github
remote to get a local branch named 'analytics' that is tracking this
github upstream.

```bash
git clone ssh://<username>@gerrit.wikimedia.org:29418/operations/puppet.git
cd puppet
git remote add github git@github.com:wmf-analytics/operations-puppet.git
git fetch github
git checkout analytics
# since the analytics branch uses git submodules, initialize those now:
git submodule init
git submodule update
```

The analytics branch should stay up to date with the production branch.
If you followed the instructions above (cloning from gerrit rather than github),
then you should be able to merge production in to the analytics branch at anytime:

```bash
git checkout analytics
git merge production
git push
```


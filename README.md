This is a fork of the Wikimedia Foundation's
[operations/puppet](https://gerrit.wikimedia.org/r/gitweb?p=operations/puppet.git;a=summary)
repository.  The analytics branch is where development is being
done for puppetization of the Analytics team's
[Kraken](https://www.mediawiki.org/wiki/Analytics/Kraken) data services
platform.

You probably shouldn't clone this repository from github.  Instead,
clone the WMF hosted gerrit version, and then fetch from the github
remote to git a local branch named 'analytics' that is tracking this
github upstream.

```bash
git clone ssh://<username>@gerrit.wikimedia.org:29418/operations/puppet.git
cd puppet
git remote add github git@github.com:wmf-analytics/operations-puppet.git
git fetch github
git checkout analytics
```


See [the wiki][wiki] for more documentation. [Ask on the group][group] if you have usage questions. [Report bugs][issues] on GitHub.

# Testing Multiple Versions

To test with against past versions of Rails use:

```
BUNDLE_GEMFILE=Gemfile.rails3.2 bundle install
BUNDLE_GEMFILE=Gemfile.rails3.2 bundle exec rspec spec
```

```
BUNDLE_GEMFILE=Gemfile.rails4.0 bundle install
BUNDLE_GEMFILE=Gemfile.rails4.0 bundle exec rspec spec
```


[wiki]: https://github.com/mislav/will_paginate/wiki
[group]: http://groups.google.com/group/will_paginate "will_paginate discussion and support group"
[issues]: https://github.com/mislav/will_paginate/issues

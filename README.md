# will_paginate

A pagination library for Rails, DataMapper and Sequel.

Installation:

``` ruby
## Rails 3: Gemfile
gem 'will_paginate', '~> 3.0.pre4'

## Rails 2.1 - 2.3: environment.rb
Rails::Initializer.run do |config|
  config.gem 'will_paginate', :version => '~> 2.3.15'
end
```

See [installation instructions][install] on the wiki for more info.

Basic use:

``` ruby
# controller: perform a query
@posts = Post.paginate(:page => params[:page], :per_page => 30)

# view: render page links
<%= will_paginate @posts %>
```

That's it!

New Rails 3 features:

``` ruby
# paginate in ActiveRecord now returns a Relation
Post.where(:published => true).paginate(:page => params[:page]).order('id DESC')

# new, shorter page method
Post.page(params[:page])

# new global per_page setting
WillPaginate.per_page = 10
```

See [the wiki][wiki] for more documentation. [Ask on the group][group] if you have usage questions. [Report bugs][issues] on GitHub.


[wiki]: https://github.com/mislav/will_paginate/wiki
[install]: https://github.com/mislav/will_paginate/wiki/Installation "will_paginate installation"
[group]: http://groups.google.com/group/will_paginate "will_paginate discussion and support group"
[issues]: https://github.com/mislav/will_paginate/issues

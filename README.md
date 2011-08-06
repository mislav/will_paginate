# will_paginate

will_paginate is a pagination library that integrates with Ruby on Rails, Sinatra, Merb, DataMapper and Sequel.

Quick install:

``` ruby
## Rails 3, Sinatra, Merb: Gemfile
gem 'will_paginate', '~> 3.0.pre4'

## Sinatra app also needs:
require 'will_paginate'
require 'will_paginate/active_record'  # or "data_mapper" or "sequel"
```

Latest will_paginate doesn't support Rails older than 3.0 anymore. If you run an older version of Rails, you have to use the 2.3.x version of will_paginate:

``` ruby
## Rails 2.1 - 2.3: environment.rb
Rails::Initializer.run do |config|
  config.gem 'will_paginate', :version => '~> 2.3.15'
end

## Rails 1.2 - 2.0: environment.rb
require 'will_paginate'
```

See [installation instructions][install] on the wiki for more info.

## Basic will_paginate use

``` ruby
## perform a paginated query:
@posts = Post.paginate(:page => params[:page])

# or, use an explicit "per page" limit:
Post.paginate(:page => params[:page], :per_page => 30)

## render page links in the view:
<%= will_paginate @posts %>
```

And that's it! You're done. You just need to add some CSS styles to [make those pagination links prettier][css].

You can customize the default "per_page" value:

``` ruby
# for the Post model
class Post
  self.per_page = 10
end

# set per_page globally
WillPaginate.per_page = 10
```

New in Active Record 3:

``` ruby
# paginate in Active Record now returns a Relation
Post.where(:published => true).paginate(:page => params[:page]).order('id DESC')

# the new, shorter page() method
Post.page(params[:page]).order('created_at DESC')
```

See [the wiki][wiki] for more documentation. [Ask on the group][group] if you have usage questions. [Report bugs][issues] on GitHub.

Happy paginating.


[wiki]: https://github.com/mislav/will_paginate/wiki
[install]: https://github.com/mislav/will_paginate/wiki/Installation "will_paginate installation"
[group]: http://groups.google.com/group/will_paginate "will_paginate discussion and support group"
[issues]: https://github.com/mislav/will_paginate/issues
[css]: http://mislav.uniqpath.com/will_paginate/

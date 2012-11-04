# will_paginate

will_paginate is a pagination library that integrates with Ruby on Rails, Sinatra, Merb, DataMapper and Sequel.

Installation:

``` ruby
## Gemfile for Rails 3, Sinatra, and Merb
gem 'will_paginate', '~> 3.0'
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

## Advanced will_paginate use

The `will_paginate` view method accepts a number of optional arguments. For example:

``` ruby
<%= will_paginate @events, :previous_label => "Older events", :next_label => "Newer events" %>
```

### Full list of options:
* `:class` -- CSS class name for the generated DIV (default: "pagination")
* `:previous_label` -- default: "« Previous"
* `:next_label` -- default: "Next »"
* `:page_links` -- when false, only previous/next links are rendered (default: true)
* `:inner_window` -- how many links are shown around the current page (default: 4)
* `:outer_window` -- how many links are around the first and the last page (default: 1)
* `:link_separator` -- string separator for page HTML elements (default: single space)
* `:param_name` -- parameter name for page number in URLs (default: `:page`)
* `:params` -- additional parameters when generating pagination links 
  (eg. `:controller => "foo", :action => nil`)
* `:renderer` -- class name, class or instance of a link renderer (default in Rails:
  `WillPaginate::ActionView::LinkRenderer`)
* `:page_links` -- when false, only previous/next links are rendered (default: true)
* `:container` -- toggles rendering of the DIV container for pagination links, set to
  false only when you are rendering your own pagination markup (default: true)


All options not recognized by will_paginate will become HTML attributes on the container
element for pagination links (the DIV). For example:

``` ruby
<%= will_paginate @posts, :style => 'color:blue' %>

# Output:
<div class="pagination" style="color:blue"> ... </div>
```

Another view method is `page_entries_info`. It renders a message containing number of displayed vs. total entries.

``` ruby
<%= page_entries_info @posts %>

# Output:
Displaying posts 6 - 12 of 26 in total
```

The default output contains HTML. Add `:html => false` for plain text.

See [the wiki][wiki] for more documentation. [Ask on the group][group] if you have usage questions. [Report bugs][issues] on GitHub.

Happy paginating!


[wiki]: https://github.com/mislav/will_paginate/wiki
[install]: https://github.com/mislav/will_paginate/wiki/Installation "will_paginate installation"
[group]: http://groups.google.com/group/will_paginate "will_paginate discussion and support group"
[issues]: https://github.com/mislav/will_paginate/issues
[css]: http://mislav.uniqpath.com/will_paginate/

Gem::Specification.new do |s|
  s.name    = 'will_paginate'
  s.version = '2.3.7'
  s.date    = '2009-02-10'
  
  s.summary = "Most awesome pagination solution for Rails"
  s.description = "The will_paginate library provides a simple, yet powerful and extensible API for ActiveRecord pagination and rendering of pagination links in ActionView templates."
  
  s.authors  = ['Mislav Marohnić', 'PJ Hyett']
  s.email    = 'mislav.marohnic@gmail.com'
  s.homepage = 'http://github.com/mislav/will_paginate/wikis'
  
  s.has_rdoc = true
  s.rdoc_options = ['--main', 'README.rdoc']
  s.rdoc_options << '--inline-source' << '--charset=UTF-8'
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc']
  
  s.files = %w(CHANGELOG.rdoc LICENSE README.rdoc Rakefile examples examples/apple-circle.gif examples/index.haml examples/index.html examples/pagination.css examples/pagination.sass init.rb lib lib/will_paginate lib/will_paginate.rb lib/will_paginate/array.rb lib/will_paginate/collection.rb lib/will_paginate/core_ext.rb lib/will_paginate/finder.rb lib/will_paginate/named_scope.rb lib/will_paginate/named_scope_patch.rb lib/will_paginate/version.rb lib/will_paginate/view_helpers.rb test test/boot.rb test/collection_test.rb test/console test/database.yml test/finder_test.rb test/fixtures test/fixtures/admin.rb test/fixtures/developer.rb test/fixtures/developers_projects.yml test/fixtures/project.rb test/fixtures/projects.yml test/fixtures/replies.yml test/fixtures/reply.rb test/fixtures/schema.rb test/fixtures/topic.rb test/fixtures/topics.yml test/fixtures/user.rb test/fixtures/users.yml test/helper.rb test/lib test/lib/activerecord_test_case.rb test/lib/activerecord_test_connector.rb test/lib/load_fixtures.rb test/lib/view_test_process.rb test/tasks.rake test/view_test.rb)
  s.test_files = %w(test/boot.rb test/collection_test.rb test/console test/database.yml test/finder_test.rb test/fixtures test/fixtures/admin.rb test/fixtures/developer.rb test/fixtures/developers_projects.yml test/fixtures/project.rb test/fixtures/projects.yml test/fixtures/replies.yml test/fixtures/reply.rb test/fixtures/schema.rb test/fixtures/topic.rb test/fixtures/topics.yml test/fixtures/user.rb test/fixtures/users.yml test/helper.rb test/lib test/lib/activerecord_test_case.rb test/lib/activerecord_test_connector.rb test/lib/load_fixtures.rb test/lib/view_test_process.rb test/tasks.rake test/view_test.rb)
end

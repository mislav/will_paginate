module WillPaginate::Fixes
  def self.each(&block)
    [PaginateOnAssociations.new, SupportCount.new].each(&block)
  end
end

require 'will_paginate/fixes/support_count'
require 'will_paginate/fixes/paginate_on_associations'
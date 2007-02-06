module WillPaginate
  def will_paginate(total_count, per_page, page = @page)
    adjacents = 2
    prev_page = page - 1
    next_page = page + 1
    last_page = (total_count / per_page.to_f).ceil
    lpm1      = last_page - 1

    returning '' do |pgn|
      if last_page > 1
        pgn << %{<div class="pagination">}
  
        # not enough pages to bother breaking
        if last_page < 7 + (adjacents * 2)
          1.upto(last_page) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, :page => ctr)) }
    
        # enough pages to hide some
        elsif last_page > 5 + (adjacents * 2) 
    
          # close to beginning, only hide later pages
          if page < 1 + (adjacents * 2)
            1.upto(3 + (adjacents * 2)) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, :page => ctr)) }
            pgn << "..." + link_to(lpm1, :page => lpm1) + link_to(last_page, :page => last_page)
  
          # in middle, hide some from both sides
          elsif last_page - (adjacents * 2) > page && page > (adjacents * 2)
            pgn << link_to('1', :page => 1) + link_to('2', :page => 2) + "..."
            (page - adjacents).upto(page + adjacents) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, :page => ctr)) }
            pgn << "..." + link_to(lpm1, :page => lpm1) + link_to(last_page, :page => last_page)
  
          # close to end, only hide early pages
          else
            pgn << link_to('1', :page => 1) + link_to('2', :page => 2) + "..."
            (last_page - (2 + (adjacents * 2))).upto(last_page) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, :page => ctr)) }
          end
        end
        pgn << (page > 1 ? link_to("&laquo; Previous", :page => prev_page) : content_tag(:span, "&laquo; Previous", :class => 'disabled'))
        pgn << (page < last_page ? link_to("Next &raquo;", :page => next_page) : content_tag(:span, "Next &raquo;", :class => 'disabled'))
        pgn << '</div>'
      end
    end
  end
  
  module ActiveRecord
    module Base
      def self.included(base)
        class << base
          extend WillPaginate::ActiveRecord::Base::ClassMethods
          alias_method_chain :method_missing, :will_paginate
        end
      end
      
      module ClassMethods
        def method_missing_with_will_paginate(method_id, *args, &block)
          unless match = /^paginate/.match(method_id.to_s)
            return method_missing_without_will_paginate(method_id, *args, &block) 
          end
          
          options = args.last.is_a?(Hash) ? args.pop : {}
          page    = options[:page].to_i.zero? ? 1 : options[:page].to_i
          options.delete(:page)
          args << options
          
          with_scope :find => { :offset => (page - 1) * per_page, :limit => per_page } do
            send(method_id.to_s.sub(/^paginate/, 'find'), *args)
          end
        end
      end
    end
  end
end

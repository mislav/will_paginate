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
          1.upto(last_page) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, params.merge(:page => ctr))) }
    
        # enough pages to hide some
        elsif last_page > 5 + (adjacents * 2) 
    
          # close to beginning, only hide later pages
          if page < 1 + (adjacents * 2)
            1.upto(3 + (adjacents * 2)) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, :page => ctr)) }
            pgn << "..." + link_to(lpm1, params.merge(:page => lpm1)) + link_to(last_page, params.merge(:page => last_page))
  
          # in middle, hide some from both sides
          elsif last_page - (adjacents * 2) > page && page > (adjacents * 2)
            pgn << link_to('1', params.merge(:page => 1)) + link_to('2', params.merge(:page => 2)) + "..."
            (page - adjacents).upto(page + adjacents) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, params.merge(:page => ctr))) }
            pgn << "..." + link_to(lpm1, params.merge(:page => lpm1)) + link_to(last_page, params.merge(:page => last_page))
  
          # close to end, only hide early pages
          else
            pgn << link_to('1', params.merge(:page => 1)) + link_to('2', params.merge(:page => 2)) + "..."
            (last_page - (2 + (adjacents * 2))).upto(last_page) { |ctr| pgn << (ctr == page ? content_tag(:span, ctr, :class => 'current') : link_to(ctr, params.merge(:page => ctr))) }
          end
        end
        pgn << (page > 1 ? link_to("&laquo; Previous", params.merge(:page => prev_page)) : content_tag(:span, "&laquo; Previous", :class => 'disabled'))
        pgn << (page < last_page ? link_to("Next &raquo;", params.merge(:page => next_page)) : content_tag(:span, "Next &raquo;", :class => 'disabled'))
        pgn << '</div>'
      end
    end
  end
end

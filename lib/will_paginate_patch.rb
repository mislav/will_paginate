# author: Sudhir chauhan<chauhansudhir@gmail.com>
# patch helpful in cases where you want to save page state and if anything deleted from last page
# then instead of showing the that page will no records. Page should move to previous page automatically
# patch checks for a current_page and total_pages if current_page is greater than total_pages in DB
# calculated last_page used as a current page
module WillPaginate
  module Finder
    module ClassMethods
      class CurrentPageError < StandardError
      end

      alias_method :old_paginate, :paginate unless method_defined?(:old_paginate)

      def paginate(*args)
        args_old = args.clone
        begin
          result = old_paginate(*args) # call super method
          
          # raise exception if current_page passed is greater than total_pages in the database
          raise(CurrentPageError, "Page and total pages not matched", []) if result && result.total_pages.to_i > 0 &&
                                                                      result.current_page.to_i > result.total_pages.to_i
        rescue CurrentPageError => e
          logger.debug(e.message)
          i = (args_old[0].class == Hash) ? 0 : 1          
          args_old[i][:page] = result.total_pages.to_i
          args = args_old
          retry
        end
        result
      end

      alias_method :old_paginate_by_sql, :paginate_by_sql unless method_defined?(:old_paginate_by_sql)
      
      def paginate_by_sql(sql, options)
        options_old = options.clone        
        begin
          result = old_paginate_by_sql(sql, options) # call super method
          # raise exception if current_page passed is greater than total_pages in the database
          raise(CurrentPageError, "Page and total pages not matched", []) if result&& result.total_pages.to_i > 0 &&
                                                                            result.current_page.to_i > result.total_pages.to_i
        rescue CurrentPageError => e
          logger.debug(e.message)
          options_old[:page] = result.total_pages.to_i
          options = options_old
          retry
        end
        result
      end
    end
  end
end
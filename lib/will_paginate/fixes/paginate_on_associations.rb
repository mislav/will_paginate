# support pagination on associations
class WillPaginate::Fixes::PaginateOnAssociations
  
  def fix
    chain_paginate_for(ActiveRecord::Associations::AssociationCollection)
    chain_paginate_for(ActiveRecord::Associations::HasManyThroughAssociation) if is_rails_after_9230?
  end
  
  def chain_paginate_for(klass)
    klass.send :include, WillPaginate::Finder::ClassMethods
    klass.class_eval { alias_method_chain :method_missing, :paginate }
  end

  def is_rails_after_9230?
    ActiveRecord::Associations::HasManyThroughAssociation.superclass != ActiveRecord::Associations::HasManyAssociation
  end

end

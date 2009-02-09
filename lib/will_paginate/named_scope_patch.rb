ActiveRecord::Associations::AssociationProxy.class_eval do
  protected
  def with_scope(*args)
    @reflection.klass.send(:with_scope, *args) { |*a| yield(*a) if block_given? }
  end
end

[ ActiveRecord::Associations::AssociationCollection,
    ActiveRecord::Associations::HasManyThroughAssociation ].each do |klass|
  klass.class_eval do
    protected
    alias :method_missing_without_scopes :method_missing_without_paginate
    def method_missing_without_paginate(method, *args)
      if @reflection.klass.scopes.include?(method)
        @reflection.klass.scopes[method].call(self, *args) { |*a| yield(*a) if block_given? }
      else
        method_missing_without_scopes(method, *args) { |*a| yield(*a) if block_given? }
      end
    end
  end
end

# Rails 1.2.6
ActiveRecord::Associations::HasAndBelongsToManyAssociation.class_eval do
  protected
  def method_missing(method, *args)
    if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
      super
    elsif @reflection.klass.scopes.include?(method)
      @reflection.klass.scopes[method].call(self, *args)
    else
      @reflection.klass.with_scope(:find => { :conditions => @finder_sql, :joins => @join_sql, :readonly => false }) do
        @reflection.klass.send(method, *args) { |*a| yield(*a) if block_given? }
      end
    end
  end
end if ActiveRecord::Base.respond_to? :find_first

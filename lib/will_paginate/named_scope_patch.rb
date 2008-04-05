## based on http://dev.rubyonrails.org/changeset/9084

ActiveRecord::Associations::AssociationProxy.class_eval do
  protected
  def with_scope(*args, &block)
    @reflection.klass.send :with_scope, *args, &block
  end
end

[ ActiveRecord::Associations::AssociationCollection,
    ActiveRecord::Associations::HasManyThroughAssociation ].each do |klass|
  klass.class_eval do
    protected
    def method_missing_without_paginate(method, *args)
      if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
        if block_given?
          super { |*block_args| yield(*block_args) }
        else
          super
        end
      elsif @reflection.klass.scopes.include?(method)
        @reflection.klass.scopes[method].call(self, *args)
      else
        with_scope construct_scope do
          if block_given?
            @reflection.klass.send(method, *args) { |*block_args| yield(*block_args) }
          else
            @reflection.klass.send(method, *args)
          end
        end
      end
    end
  end
end

# Rails 1.2.6
ActiveRecord::Associations::HasAndBelongsToManyAssociation.class_eval do
  protected
  def method_missing(method, *args, &block)
    if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
      super
    elsif @reflection.klass.scopes.include?(method)
      @reflection.klass.scopes[method].call(self, *args)
    else
      @reflection.klass.with_scope(:find => { :conditions => @finder_sql, :joins => @join_sql, :readonly => false }) do
        @reflection.klass.send(method, *args, &block)
      end
    end
  end
end if ActiveRecord::VERSION::MAJOR < 2


ActiveRecord::Associations::AssociationCollection.class_eval do
  protected
  def method_missing(method, *args)
    if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
      if block_given?
        super { |*block_args| yield(*block_args) }
      else
        super
      end
    elsif @reflection.klass.scopes.include?(method)
      @reflection.klass.scopes[method].call(self, *args)
    else          
      with_scope(construct_scope) do
        if block_given?
          @reflection.klass.send(method, *args) { |*block_args| yield(*block_args) }
        else
          @reflection.klass.send(method, *args)
        end
      end
    end
  end
end


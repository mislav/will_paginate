# Makes the test suite compatible with Bundler standalone mode (used in CI)
# because Active Record uses `gem` for loading adapters.
Kernel.module_eval do
  def gem(*args)
    warn "warning: gem(#{args.map {|o| o.inspect }.join(', ')}) ignored; called from:"
    warn "  " << caller[0,5].join("\n  ")
  end
end

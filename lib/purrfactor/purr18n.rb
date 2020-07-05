class Purr18n
  include PurrTools
  attr_accessor :locale, :global, :available_locales

  def initialize(opts)
    @locale = opts[:locale]
    @global = opts[:global]
    @available_locales = available_locales
    scan_views
  end
end

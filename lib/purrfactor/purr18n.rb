class Purr18n
  include PurrTools
  attr_accessor :locale, :global, :available_locales

  def initialize(opts)
    @locale = opts[:locale]
    @global = opts[:global]
    @available_locales = get_locales
    @matches = []
    scan_views
  end
end

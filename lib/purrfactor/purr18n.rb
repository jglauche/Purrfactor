class Purr18n
  include PurrTools
  attr_accessor :locale, :global

  def initialize(opts)
    @locale = opts[:locale]
    @global = opts[:global]
    scan_views
  end
end

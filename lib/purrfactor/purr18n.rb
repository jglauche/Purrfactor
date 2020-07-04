class Purr18n
  include PurrTools
  attr_accessor :locale

  def initialize(opts)
    @locale = opts[:locale]
    scan_views
  end
end

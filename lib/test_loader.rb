class TestLoader
  include PurrTools

  attr_accessor :available_locales
  attr_accessor :test_mode, :ignored_views

  def initialize
    @test_mode = true
    @ignored_views = []
    @available_locales = get_locales
  end

  def test_feedback(file, line, i, suggestion)
    return [file, line, i, suggestion]
  end
end



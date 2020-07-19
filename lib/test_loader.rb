class TestLoader
  include PurrTools

  attr_accessor :available_locales
  attr_accessor :test_mode, :ignored_views
  attr_accessor :test_files, :test_lines, :test_i, :test_suggestions

  def initialize
    @test_mode = true
    @ignored_views = []
    @available_locales = get_locales
    @matches = {}
    @test_files = []
    @test_lines = []
    @test_i = []
    @test_suggestions = []
  end

  def test_feedback(file, line, i, suggestion)
    @test_files << file
    @test_lines << line
    @test_i << i
    @test_suggestions << suggestion
  end
end



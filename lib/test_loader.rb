class TestLoader < Purr18n
  attr_accessor :available_locales
  attr_accessor :test_mode, :ignored_views
  attr_accessor :test_files, :test_lines, :test_i, :test_suggestions
  attr_accessor :test_i18n_keys, :test_i18n_vals
  attr_accessor :matches

  def initialize
    @test_mode = true
    @ignored_views = []
    @available_locales = get_locales
    @matches = {}
    @test_files = []
    @test_lines = []
    @test_i = []
    @test_suggestions = []
    @test_i18n_keys = []
    @test_i18n_vals = []
  end

  def test_feedback(file, line, i, suggestion, matches)
    @test_files << file
    @test_lines << line
    @test_i << i
    @test_suggestions << suggestion.strip
    matches.each do |m|
      @test_i18n_keys << m.i18n_key
      @test_i18n_vals << m.i18n_val
    end
  end
end



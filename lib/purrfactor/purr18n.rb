class Purr18n
  include PurrTools
  attr_accessor :locale, :global, :available_locales

  def initialize(opts)
    @locale = opts[:locale]
    @global = opts[:global]
    @available_locales = get_locales
    @matches = {}
  end

  def fmt_i18n_key(key, s=nil)
    opts = ""
    if s
      # check if we need to put erb code in round parentheses
      # could be done more elaborate
      if s.strip.index(" ")
        opts = ", s: (#{s})"
      else
        opts = ", s: #{s}"
      end
    end

    if @global
      "t(:#{key}#{opts})"
    else
      "t('.#{key}'#{opts})"
    end
  end

  def mk_i18n_key(line)
    line.downcase.gsub(/[^a-z0-9 ]/, '').squeeze(" ").strip.gsub(" ","_")
  end

  def scan_views(dir = "app/views")
    Dir.glob("#{dir}/**/*.*").each do |f|
      @available_locales.each do |locale|
        if f.include?(".#{locale}.")
          @ignored_views << f if @test_mode
          next
        end
      end
      scan_view(f)
    end
  end

  def set_file(file)
    @file = file
    @file_i = nil
    @file_line = nil
  end

  def scan_view(file)
    set_file(file)
    case determine_file_type(file)
    when "erb"
      scan_erb(file)
    when "haml"
      scan_haml(file)
    end
    handle_matches_for_cur_file
  end

  def scan_haml(file)
    parser = HamlParser::Parser.new(filename: file)
    ast = parser.call(File.read(file))
    parse_haml_ast(ast)
  end

  def parse_haml_ast(ast, inline=false)
    @inline = inline
    if ast.respond_to? :text
      @file_i = ast.lineno
      process_line(ast.text)
    end
    if ast.respond_to? :oneline_child
      parse_haml_ast(ast.oneline_child, true)
    end
    if ast.respond_to? :children
      ast.children.each do |child|
        parse_haml_ast(child)
      end
    end
  end

  def create_match(text, key, i18n_key, i18n_val, add_inline_key=false)
    @matches[@file] ||= {}
    @matches[@file][@file_i] ||= []
    @matches[@file][@file_i] << Match.new(text, key, i18n_key, i18n_val, add_inline_key)
  end

  def process_line(text)
    match_text, key, opt_var = parse_erb_tags(text)
    i18n_key = fmt_i18n_key(key, opt_var)
    create_match(text, i18n_key, key, match_text, true)
    parse_erb_for_text(opt_var)
  end

  def check_string_context(sym, text)
    case sym.to_s
    when "class"
    when "method"
    else
      match_text, key, opt_var = parse_erb_tags(text)
      i18n_key = fmt_i18n_key(key, opt_var)
      delimiter = check_delimiter(text)
      create_match(wrap_in_delimiter(text, delimiter), i18n_key, key, match_text)
    end
  end

  def check_delimiter(text)
    raise "@file_line cannot be nil for this method" if @file_line == nil
    @file_line[@file_line.index(text)-1]
  end

  def wrap_in_delimiter(text, d)
    "#{d}#{text}#{d}"
  end

  def parse_erb_for_text(erb)
    return if erb == nil
    if erb[0..0] == "="
      erb = erb[1..-1].strip
    end
    puts erb
    @last_symbol = nil
    @file_line = erb
    parse_ast(Parser::CurrentRuby.parse(erb))
  end

  def parse_ast(node)
    case node
    when Array
      node.each_with_index do |x|
        parse_ast(x)
      end
    when Parser::AST::Node
      node.children.each_with_index do |x|
        parse_ast(x)
      end
    when Symbol
      @last_symbol = node
    when String
      check_string_context(@last_symbol, node)
    end
  end

  def parse_erb_tags(text)
    opt_var = nil
    key = ""
    erb = text.scan(/\#{.*}/)
    case erb.size
    when 0
      key = mk_i18n_key(text)
    when 1
      opt_var = erb.first[2..-2]
      key = mk_i18n_key(text.gsub(erb.first, ""))
      text = text.gsub(erb.first, "%s")
    else
      puts "cannot auto-convert this line"
    end
    return text, key, opt_var
  end

  def scan_erb(file)
    f = File.read(file)
    # since Nokogiri will ignore erb tags, gonna change them
    f = f.gsub("<%", "{erb_tag}").gsub("%>","{/erb_tag}")
    parse_nokogiri(Nokogiri::HTML(f))
  end

  def parse_nokogiri(node)
    if node.children
      node.children.each do |child|
        parse_nokogiri(child)
      end
    end
    if node.kind_of? Nokogiri::XML::Text
      @file_i = node.line
      parse_nokogiri_text(node.text)
    end
  end

  def parse_nokogiri_text(text)
    return if text == ""
    stripped_text = text.gsub(/{erb_tag}(.*){\/erb_tag}/,"{erb_inner}").gsub("\n","").gsub("{erb_inner}","").strip
    return if stripped_text == ""
    # TODO: continue to parse it here. This seems to work mostly
    # remember: need to parse the inner of ERB tags for text
    @file_line = stripped_text
    process_line(stripped_text)
  end

  def scan_tags(file)
    lines = File.readlines(file)
    lines.each_with_index do |line, i|
      l = line
      # ignore anything after common tags
      ['render', 'partial', 'autocomplete', 'if', 'content', 'id=', '_tag', 'meta', 'class', 'method', "I18n.t", "t(", "label"].each do |ignore|
        l = l.split(ignore).first
      end
      # scan for text in quotes or double quotes
      res = l.scan(/".*?"|'.*?'/).flatten
      res.each do |r|
        next if r.nil?
        # FIXME: if this is to be resurrected, re-add parse_erb_tags
  #      i18n_key = mk_i18n_key(r)
        result_line = line.gsub(r, "\e[35m" + r + "\e[37m")

        cmd_feedback(file, result_line, i, suggestion)
      end
    end
  end

  def scan_text(file)
    ft = determine_file_type(file)
    unless ["erb", "haml"].include? ft
      puts "unsupported file type: #{ft}"
      return
    end
    multiline = false

    lines = File.readlines(file)
    lines.each_with_index do |line, i|
      rline = line.gsub(/(<.*>)|(\/\*.*\*\/)/,"")
      if rline.index("<%")
        multiline = true
      end
      if rline.index("%>")
        multiline = false
        next
      end
      if multiline
        next
      end
      rline = line.gsub(/(\.|!!!|-|=|%|#).*/,"")
      unless rline.strip.empty?
        i18n_key = mk_i18n_key(rline)
        cmd_feedback(file, line, i, add_print_tag(fmt_i18n_key(i18n_key), ft))
      end
    end
  end

  def get_indent(line)
    line.split("  ").size - 1
  end

  def determine_file_type(file)
    return file.split(".").last
  end

  def add_print_tag(tag, ft)
    case ft
    when "erb"
      "<%= #{tag} %>"
    when "haml"
      "= #{tag}"
    else
      tag
    end
  end

  def handle_matches_for_cur_file
    return unless @matches[@file]
    lines = File.readlines(@file)
    ft = determine_file_type(@file)
    @matches[@file].each do |file_i, arr|
      line = lines[file_i-1].dup

      # this can probably be moved into cmd_feedback
      arr.each do |x|
        if x.add_inline_key
          # for inline haml text we need to get rid of the space after the tag
          # as it is interpreted as plain text otherwise
          # TODO: check if this breaks on erb files
          line.gsub!(" #{x.match}", add_print_tag(x.replace, ft))
        end
        line.gsub!(x.match, x.replace)
      end
      cmd_feedback(@file, lines[file_i-1], file_i, line, arr)
    end
  end

  def fmt_match(line, m)
    line.gsub(m, "\e[35m" + m + "\e[37m")
  end

  # this needs to be refactored
  def cmd_feedback(file, line, i, suggestion, matches)
    if @test_mode
      test_feedback(file, line, i, suggestion, matches)
      return
    end

    matches.each do |m|
      line = fmt_match(line, m.match)
    end

    puts "\e[0;33mFile:\e[1;33m #{file}\e[0;33m line \e[1;35m#{i}"
    puts "\e[0;31m#{line}"
    puts "\e[32m#{suggestion}"
    matches.each do |m|
      puts "\e[0;33mI18n: \e[0;36m#{m.i18n_key}: \e[1;35m#{m.i18n_val}"
    end
    puts "\e[0;37m"
    puts ""
  end




end

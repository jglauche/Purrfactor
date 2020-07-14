module PurrTools

  def get_locales
    Dir.glob("config/locales/??.yml").map{ |l|
      l.split("/").last.gsub(".yml","")
    }
  end

  def create_dirs(file)
    dir = file.split("/")[0..-2].join("/")
    FileUtils.mkdir_p(dir)
  end

  def move_file(old, new)
    check_and_create_dirs
  end

  def refactor(dir, old, new)
    matches = %x|grep -H -m 1 -w '#{old}' -r #{dir}|.split("\n").map{ |x| x.split(":",2) }

    matches.each do |file, text|
      puts "Patching file #{file}, replacing #{old} to #{new}"
      c = File.read(file)
      c.gsub!(old, new)
      f = File.open(file, "w")
      f.write(c)
      f.close
    end
  end

  def to_file(to, name, add="")
    str = ""
    ext = ".rb"
    pluralize = false

    case to
    when :model
      str << "app/models/"
    when :fixture
      str << "test/fixtures/"
      ext = ".yml"
      pluralize = true
    when :test_model
      str << "test/models/"
    else
      str << to
    end

    case name
    when Array
      n = name.map(&:underscore)
      if pluralize
        n[-1] = n[-1].pluralize
      end
      str << n.join("/")
    else
      str << name
    end
    str << add
    str << ext
    str
  end

  def load_schema
    f = File.readlines("db/schema.rb")
    db =  {}
    cur = nil
    # remove comments and empty lines
    f.map(&:strip).delete_if{|l| l[0] == "#" or l == ""}[1..-2].each do |l|
      if l[0..11] == "create_table"
        name = l.split('"')[1]
        db[name] = []
        cur = name
      elsif l[0] == "t"
        db[cur] << l.split('"')[1]
      end
    end
    db
  end

  def model_references(model)
    plural = model.pluralize
    h = {}
    load_schema.each do |table, rows|
      next if table == plural
      rows.each do |field|
        if field == "#{model}_id"
          h[table] = field
        end
      end
    end
    h
  end

  def fmt_i18n_key(key, s=nil)
    opts = ""
    if s
      opts = ", s: #{s}"
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

  def scan_view(file)
    case determine_file_type(file)
    when "erb"
      # TODO: this should be migrated to a proper erb parser
      #scan_tags(file)
      #scan_text(file)
    when "haml"
      scan_haml(file)
    end
  end

  def scan_haml(file)
    parser = HamlParser::Parser.new(filename: file)
    ast = parser.call(File.read(file))
    parse_haml_ast(ast)
  end

  def parse_haml_ast(ast)
    if ast.respond_to? :text
      process_line(ast.filename, ast.text, ast.lineno)
    end
    if ast.respond_to? :oneline_child
      parse_haml_ast(ast.oneline_child)
    end
    if ast.respond_to? :children
      ast.children.each do |child|
        parse_haml_ast(child)
      end
    end
  end

  def process_line(filename, text, line_number)
    match_text, key, opt_var = parse_erb_tags(text)
    i18n_key = fmt_i18n_key(key, opt_var)
    cmd_feedback(filename, fmt_match(text, match_text), line_number, i18n_key)
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

  def fmt_match(line, m)
    line.gsub(m, "\e[35m" + m + "\e[37m")
  end

  def cmd_feedback(file, line, i, suggestion)
    if @test_mode
      test_feedback(file, line, i, suggestion)
      return
    end

    puts "\e[33mFile: #{file}\e[37m line #{i}"
    puts "\e[31m#{line}"
    puts "\e[32m#{suggestion}"
    puts "\e[37m "
  end

end


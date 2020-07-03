module PurrTools

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


  def scan_views(dir = "app/views")
    Dir.glob("#{dir}/**/*.*").each do |f|
      scan_view(f)
    end
  end

  def scan_view(file)
    f = File.readlines(file)
    f.each_with_index do |line, i|
      l = line
      # ignore anything after common tags
      ['render', 'partial', 'autocomplete', 'if', 'content', 'id=', '_tag', 'meta', 'class', 'method', "I18n.t", "t(", "label"].each do |ignore|
        l = l.split(ignore).first
      end

      # scan for text in quotes or double quotes
      res = l.scan(/".*?"|'.*?'/).flatten
      res.each do |r|
        next if r.nil?

        i18n_key = r.downcase.gsub(/[^a-z0-9 ]/, '').squeeze.strip.gsub(" ","_")
        result_line = line.gsub(r, "\e[35m" + r + "\e[37m")

        # scan for inline erb code
        erb = r.scan(/\#{.*}/)
        case erb.size
        when 0
          suggestion = result_line.gsub(r, "t('.#{i18n_key}')")
        when 1
          suggestion = result_line.gsub(r, "t('.#{i18n_key}', s: #{erb.first[2..-2]})")
        else
          suggestion = ""
          puts "cannot auto-convert this line"
        end

        cmd_feedback(file, result_line, i, suggestion)
      end
    end
  end

  def cmd_feedback(file, line, i, suggestion)
    puts "\e[33mFile: #{file}\e[37m line #{i}"
    puts "\e[31m#{line}"
    puts "\e[32m#{suggestion}"
    puts "\e[37m "
  end

end


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

end



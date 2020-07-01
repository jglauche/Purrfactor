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

end



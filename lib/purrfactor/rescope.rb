class Rescope
  include PurrTools

  attr_accessor :old, :new, :dirs

  def initialize(file, scope, dirs = ["app", "lib"])
    puts "#{file} -> #{scope}"

    @old = file.split("::").map{|x| x.upcase_first}
    if scope == "."
      @new = [@old.last]
    else
      @new = [scope.camelize, @old.last]
    end
    @dirs = dirs

    if file.downcase.include? "controller"
      puts "rescopeing of controllers is not yet implemented"
      exit
    else
      rescope_model!
    end

  end

  private

  def to_file(name)
    "app/models/" + name.map(&:underscore).join("/") + ".rb"
  end

  def rescope_model!
    old_file = to_file(@old)
    new_file = to_file(@new)
    raise "#{old_file} not found" unless File.exists?(old_file)
    raise "#{new_file} already exists" if File.exists?(new_file)


    create_dirs(new_file)
    FileUtils.mv(old_file, new_file)

    @dirs.each do |dir|
      refactor(dir, old.join("::"), new.join("::"))
      refactor(dir, old.join.underscore, new.join.underscore)
    end
    # todo: Refactor db

  end

end

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

    old_u = old.join.underscore
    new_u = new.join.underscore
    @dirs.each do |dir|
      refactor(dir, old.join("::"), new.join("::"))
      refactor(dir, old_u, new_u)
    end

    # create a non-dangerous migration
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    filename = "db/migrate/#{timestamp}_rename_#{old_u}_to_#{new_u}.rb"
    puts "Creating migration #{filename}"

    f = File.open(filename, "w")
    f.puts "class Rename#{old_u.camelcase}To#{new_u.camelcase} < ActiveRecord::Migration"
    f.puts "  def change"
    f.puts "    rename_table :#{old_u.pluralize}, :#{new_u.pluralize}"
    f.puts "  end"
    f.puts "end"
    f.close
  end

end

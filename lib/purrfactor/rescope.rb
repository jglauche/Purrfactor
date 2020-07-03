class Rescope
  include PurrTools

  attr_accessor :old, :new, :dirs

  def initialize(file, scope, dirs = ["app", "lib", "test"])
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

  def move_file(target, add="")
    old_file = to_file(target, @old, add)
    new_file = to_file(target, @new, add)
    if target == :model # let's run sanity checks only for model
      raise "#{old_file} not found" unless File.exists?(old_file)
      raise "#{new_file} already exists" if File.exists?(new_file)
    else
      # just silently ignore if we don't have a fixture
      unless File.exists?(old_file)
        puts "Fixture not found: #{old_file} . Skipping"
        return
      end
    end

    create_dirs(new_file)
    FileUtils.mv(old_file, new_file)
  end

  def rescope_model!
    move_file(:model)
    move_file(:test_model, "_test")
    move_file(:fixture)

    old_u = @old.join.underscore
    new_u = @new.join.underscore
    @dirs.each do |dir|
      refactor(dir, old.join("::"), new.join("::"))
      refactor(dir, old_u, new_u)
    end

    # fix test names
    old_t = @old.join("::") + "Test"
    new_t = @new.join("::") + "Test"
    refactor("test", old_t, new_t)



    # create a non-dangerous migration
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    filename = "db/migrate/#{timestamp}_rename_#{old_u}_to_#{new_u}.rb"
    puts "Creating migration #{filename}"

    f = File.open(filename, "w")
    f.puts "class Rename#{old_u.camelcase}To#{new_u.camelcase} < ActiveRecord::Migration[4.2]"
    f.puts "  def change"
    f.puts "    rename_table :#{old_u.pluralize}, :#{new_u.pluralize}"
    f.puts "  end"
    f.puts "end"
    f.close
    # FIXME: need to fix columns of everything that interfaces it
  end

end

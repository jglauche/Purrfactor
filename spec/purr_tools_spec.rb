class PurrToolsLoader
  include PurrTools
end

describe PurrTools do
  before do
    Dir.chdir($exec_dir + "/spec/sample_app_rails6/")
    @loader = PurrToolsLoader.new
  end

  it 'reads schema.rb' do
    res = @loader.load_schema
    expect(res.keys).to include "inventories", "items", "pets", "users"
  end

  it 'finds model_references' do
    res = @loader.model_references('user')
    expect(res.keys).to include "inventories", "pets"
    expect(res.values.uniq).to eq ["user_id"]
  end

  it 'finds available locales' do
    expect(@loader.available_locales.sort).to eq ["de", "en"]
  end

end

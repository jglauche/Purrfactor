describe Purr18n do
  before do
    Dir.chdir($exec_dir + "/spec/sample_app_rails6/")
    @loader = TestLoader.new
  end

  it 'scans devise edit.html.haml file' do
    @loader.scan_view('app/views/devise/registrations/edit.html.haml')
    expect(@loader.test_i.size).to eq 7
    expect(@loader.test_suggestions[0]).to eq "= t('.edit', s: resource_name.to_s.humanize)"
    expect(@loader.test_suggestions[1]).to eq "= t('.currently_waiting_confirmation_for', s: resource.unconfirmed_email)"
    # TODO: check if i18n key has brackets
    expect(@loader.test_suggestions[2]).to eq "%i= t('.leave_blank_if_you_dont_want_to_change_it')"
    expect(@loader.test_suggestions[3]).to eq "= t('.characters_minimum')"

    expect(@loader.test_suggestions[4]).to eq "%i= t('.we_need_your_current_password_to_confirm_your_changes')"

    expect(@loader.test_suggestions[5]).to eq "%h3= t('.cancel_my_account')"

    expect(@loader.test_suggestions[6]).to eq "= t('.unhappy', s:(button_to t('.cancel_my_account'), registration_path(resource_name), data: { confirm: t('.are_you_sure') }, method: :delete))"


  end

end

describe Purr18n do
  before do
    Dir.chdir($exec_dir + "/spec/sample_app_rails6/")
    @loader = TestLoader.new
  end

  it 'scans devise edit.html.haml file' do
    file = "app/views/devise/registrations/edit.html.haml"
    @loader.scan_view(file)


    res = [
      "= t('.edit', s: resource_name.to_s.humanize)",
      "= t('.currently_waiting_confirmation_for', s: resource.unconfirmed_email)",
      "%i= t('.leave_blank_if_you_dont_want_to_change_it')",
      "= t('.characters_minimum')",
      "%i= t('.we_need_your_current_password_to_confirm_your_changes')",
      "%h3= t('.cancel_my_account')",
      "= t('.unhappy', s: (button_to t('.cancel_my_account'), registration_path(resource_name), data: { confirm: t('.are_you_sure') }, method: :delete))",
    ]
    cmp_array(@loader.test_suggestions, res)

  end

end

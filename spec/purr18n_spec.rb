describe Purr18n do
  before do
    Dir.chdir($exec_dir + "/spec/sample_app_rails6/")
    @loader = TestLoader.new
  end

  describe "scan devise edit.html.haml" do
    before do
      @file = "app/views/devise/registrations/edit.html.haml"
    end

    after do
      keys = [
        "edit",
        "currently_waiting_confirmation_for",
        "leave_blank_if_you_dont_want_to_change_it",
        "characters_minimum",
        "we_need_your_current_password_to_confirm_your_changes",
        "cancel_my_account",
        "unhappy",
        "cancel_my_account",
        "are_you_sure",
      ]

      vals = [
        "Edit %s",
        "Currently waiting confirmation for: %s",
        "(leave blank if you don't want to change it)",
        "characters minimum",
        "(we need your current password to confirm your changes)",
        "Cancel my account",
        "Unhappy? %s",
        "Cancel my account",
        "Are you sure?",
      ]

      cmp_array(@loader.test_i18n_keys, keys)
      cmp_array(@loader.test_i18n_vals, vals)
    end


    it 'scans devise edit.html.haml file with global i18n keys' do
      @loader.global = true
      @loader.scan_view(@file)

      res = [
        "= t(:edit, s: resource_name.to_s.humanize)",
        "= t(:currently_waiting_confirmation_for, s: resource.unconfirmed_email)",
        "%i= t(:leave_blank_if_you_dont_want_to_change_it)",
        "= t(:characters_minimum)",
        "%i= t(:we_need_your_current_password_to_confirm_your_changes)",
        "%h3= t(:cancel_my_account)",
        "= t(:unhappy, s: (button_to t(:cancel_my_account), registration_path(resource_name), data: { confirm: t(:are_you_sure) }, method: :delete))",
      ]
      cmp_array(@loader.test_suggestions, res)
    end

    it 'scans devise edit.html.haml file with local i18n keys' do
      @loader.scan_view(@file)

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

end

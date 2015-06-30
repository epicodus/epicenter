def sign_in(user)
  visit new_student_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: user.password
  click_button 'Sign in'
end

def create_hello_sign_signature
  click_on 'Got it'
  execute_script('$.fancybox.close()')
  click_on 'I agree'
  find('p', text: 'Click to sign').trigger('click')
  sleep 3
  find('a', text: 'Type it in').trigger('click')
  fill_in 'type-in-text', with: 'Epicodus Student'
  click_on 'Insert'
  execute_script("$('.m-sig-modal').css('display','none')")
  click_on 'I agree'
end

def custom_capybara_driver
  include Capybara::DSL
  Capybara.current_driver = :poltergeist_billy_custom
end

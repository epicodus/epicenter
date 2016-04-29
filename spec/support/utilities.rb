def sign_in_as(user, pair=nil)
  visit new_user_session_path
  fill_in 'user_email', with: user.email
  fill_in 'user_password', with: user.password
  if pair
    fill_in 'pair_email', with: pair.email
    fill_in 'pair_password', with: pair.password
    click_button 'Pair sign in'
  else
    click_button 'Sign in'
  end
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

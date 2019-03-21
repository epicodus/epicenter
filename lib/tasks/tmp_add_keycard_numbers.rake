desc "Add keycard numbers to Close"
task :tmp_add_keycard_numbers => [:environment] do

  # array_of_email_keycard_hashes = [{ email: "example1@example.com", keycard: "10000 | 100000-B" }, { email: "example2@example.com", keycard: "200000 | 200001-B" }]


  array_of_email_keycard_hashes.each do |email_keycard_hash|
    email = email_keycard_hash[:email].downcase
    keycard = email_keycard_hash[:keycard]
    puts "Assigning #{email} Keycard Number: #{keycard}"
    User.find_by(email: email).crm_lead.update({ 'custom.Keycard Number': keycard })
  end
end

[![Coverage status](https://coveralls.io/repos/github/epicodus/epicenter/badge.svg?branch=main)](https://coveralls.io/github/epicodus/epicenter?branch=main)
[![Code climate](https://codeclimate.com/github/epicodus/epicenter/badges/gpa.svg)](https://codeclimate.com/github/epicodus/epicenter)
# Epicenter

This app handles a few different things for Epicodus students, staff, and partner internship companies, including:

* Tuition
* Enrollment
* Attendance
* Code Reviews
* Internships

It's designed to be flexible enough that other schools can adopt it with minimal changes.

Contributions from students, alumni, and other schools are welcome! If you'd like to add a feature, please open a GitHub issue to discuss it with the project's maintainers first.


## Configuration

1. `git clone https://github.com/epicodus/epicenter.git`
1. `cd epicenter`
1. `cp .env.example .env`
1. Update the example values in `.env` as needed
1. `bundle`
1. `rails db:create && rails db:schema:load && rails db:seed`
1. `rails s` and visit [localhost:3000](http://localhost:3000)
  1. to sign in as an admin, use: `admin1@example.com` and `password`
  1. to sign in as a student, use: `student1@example.com` and `password`

## License
GPL2

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# User.create first_name: '', last_name: ''

# User.create first_name: 'Tango', last_name: 'Hoy'
# User.create first_name: 'Randall', last_name: 'Azibo'

User.create first_name: '1'
User.create first_name: '2'
User.create first_name: '3'
User.create first_name: '4'
User.create first_name: '5'
User.create first_name: '6'
User.create first_name: '7'
User.create first_name: '8'
User.create first_name: '9'
User.create first_name: '10'
User.create first_name: '11'
User.create first_name: '12'
User.create first_name: '13'
User.create first_name: '14'
User.create first_name: '15'
User.create first_name: '16'
User.create first_name: '17'
User.create first_name: '18'
User.create first_name: '19'
User.create first_name: '20'
User.create first_name: '21'
User.create first_name: '22'
User.create first_name: '23'
User.create first_name: '24'
User.create first_name: '25'
User.create first_name: '26'
User.create first_name: '27'
User.create first_name: '28'
User.create first_name: '29'
User.create first_name: '30'
User.create first_name: '31'
User.create first_name: '32'

same_date = Time.now
User.find(1).sent_invitations.create date: same_date, user: User.find(2)
User.find(1).sent_invitations.create date: same_date, user: User.find(2)

User.find(1).check_for_duplicate_invitations(Invitation.first)

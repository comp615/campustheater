CampusTheater
=============

A site to help campuses manage vibrant theater and performing arts communities

Campustheater is a centralized resource for undergraduate theater.  It supports casting, filling crews, reserving tickets, and serving as database to validate resumes.  The app enables productions to post audition slots where actors can sign up.  This also stores their contact information and facilitates communication between production teams and actors. Productions can advertise open positions on their teams which appear on one centralized page and producers can search for people by position from the database. Tickets are reserved through a simple form which can be moderated by a site administrator and is viewable by production teams. Each person also has their own page listing all the shows they have worked on, which also links back to the original individual show page.

== TODOs
- Modules need to be setup for the front-page to be layed out
- play with poster sizing more as we get experience (background-size 100%, use ratio, etc.)
- Errors and validation errors should be handled better. No messages given often! (last showtime deletion, etc.)

- Loading spinner on poster upload
- Freshmen and Playground tables need to be enhanced into Rails
- See internal code TODOs

== SETUP TIPS

- `bundle install`
- If you're on OSX, libv8 and therubyracer may give you build errors. If so, see the advice [on installing therubyracer](http://stackoverflow.com/a/20145328/1729692) and [on installing libv8](http://stackoverflow.com/a/19674065/1729692). You may need to install therubyracer before libv8, per the instructions. The following recently worked for us (on Mac OSX):
  - `gem install therubyracer -v '0.12.1'`
  - `gem install libv8 -v '3.16.14.3' -- --with-system-v8`
  - `bundle`

- Copy `config/database.yml.example` to `database.yml` and adjust db connection settings
- Copy `config/analytics.yml.example` to `analytics.yml`
- Copy `config/aws.yml.example` to `aws.yml`
- Copy `config/email.yml.example` to `email.yml` (mailer SMTP settings)
- Copy `config/ftp.yml.example` to `ftp.yml` (TODO: is this used at all?)
- `rake db:reset` to create db from schema (**not all migrations are present**)

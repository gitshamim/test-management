
# README
This is where the reports from AWS are going to be. Rails application with access to the AWS S3. 
Right now this is very bareboned. 

Setup instruction:
1. bundle install
2. rails s

Port using: 3025


Examples:

1. Update: in bdd test .travis.yml file, after test report uploading code, add this call
- curl -X PUT "http://localhost:3025/reports/update" -d ''

2. To reach the UI
simply go to http://pedmatch-int.nci.nih.gov:3025

3. To show specific bdd test report:
http://localhost:3025/report/:date/:type/:service
For example:
http://localhost:3025/report/01-31-17/critical/treatment_arm
http://localhost:3025/report/12-18-16/non-critical/ui





Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
# test-management

# README

This README would normally document whatever steps are necessary to get the
application up and running.

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

A short description of your Ruby on Rails application.

🚀 Quick Start

Prerequisites
Ruby 3.2.2

Rails 7.1.2

Node.js 16+

Yarn

PostgreSQL/MySQL

Installation
Clone and setup

bash
git clone <your-repo-url>
cd <project-directory>

bundle install

yarn install

Setup database

bash
rails db:create

rails db:migrate

rails db:seed

Start server

bash
./bin/dev
Visit: http://localhost:3000

Testing
bash
bundle exec rspec
Deployment
bash
git push origin main
🔧 Environment
Create .env file for local variables

Never commit .env or config/master.key

rails server
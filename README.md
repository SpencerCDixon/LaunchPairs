# Sinatra Omniauth Example

This is a sample app that shows how to use the
[omniauth-github](https://github.com/intridea/omniauth-github) gem for user
authentication.

## Getting Started

### Register your application with GitHub

Go to your [application settings page](https://github.com/settings/applications)
on GitHub and register a new application. The name doesn't matter but you'll
want to set your "Homepage URL" to `http://localhost:4567/` and your
"Authorization Callback URL" to `http://localhost:4567/auth/github/callback`.

Copy the `.env.example` file to `.env` and fill in the values for `GITHUB_KEY`
and `GITHUB_SECRET` that are provided on the GitHub settings page for your
application.

**Note: The `.env` file is in the `.gitignore` so your credentials will be safe.
DON'T add your keys to the `.env.example` file.**

### Setting Up the Database

Create a new PostgreSQL database named `sinatra_omniauth_dev`. You can find the
SQL to create the users table in `schema.sql`.

### Bundle Install

Don't forget to run `bundle install` to install all of the necessary
dependencies.

### Start up the app

You should start up the app with `ruby app.rb`.

**Note: If you try to run the app using shotgun, the app will be running on the
wrong port and your GitHub auth won't work.**

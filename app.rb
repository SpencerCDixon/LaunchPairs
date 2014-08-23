# This will load your environment variables from .env when your apps starts
require 'dotenv'
Dotenv.load

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'omniauth-github'
require 'pg'

set :port, 9000

## Configure Database & OmniAuth ##
configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']

  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
  end
end

configure :development do
  require 'pry'
end

# Connect to database
def db_connection
  begin
    connection = PG.connect(dbname: 'sinatra_omniauth_dev')
    yield(connection)
  ensure
    connection.close
  end
end

def user_from_omniauth(auth)
  {
    uid: auth.uid,
    provider: auth.provider,
    username: auth.info.nickname,
    name: auth.info.name,
    email: auth.info.email,
    avatar_url: auth.info.image,
  }
end

def find_or_create_user(attr)
  find_user_by_uid(attr[:uid]) || create_user(attr)
end


def find_user_by_uid(uid)
  sql = 'SELECT * FROM users WHERE uid = $1 LIMIT 1'

  user = db_connection do |db|
    db.exec_params(sql, [uid])
  end

  user.first
end

def find_user_by_id(id)
  sql = 'SELECT * FROM users WHERE id = $1 LIMIT 1'

  user = db_connection do |db|
    db.exec_params(sql, [id])
  end

  user.first
end

def create_user(attr)
  sql = %{
    INSERT INTO users (uid, provider, username, name, email, avatar_url)
    VALUES ($1, $2, $3, $4, $5, $6) RETURNING *;
  }

  status = %{
  INSERT INTO status (user_id, status, created_at)
  VALUES ($1, 'Enter Your Status', now());
}

  project = %{
    INSERT INTO projects (user_id, project, created_at)
    VALUES ($1, 'Sleeping', now());
  }

  personal_info = %{
    INSERT INTO personal_info (user_id, breakable_toy, phone_number, blog_url, twitter, linkedin, created_at) VALUES ($1, '', '', '', '', '', now())
  }

  db_connection do |db|
    result = db.exec_params(sql, attr.values)
    db.exec_params(status, [result[0]["id"].to_i])
    db.exec_params(project, [result[0]["id"].to_i])
    db.exec_params(personal_info, [result[0]["id"].to_i])
    result[0]
  end

end

def all_users
  db_connection do |db|
    db.exec('SELECT * FROM users')
  end
end

def authenticate!
  unless current_user
    flash[:negative] = 'You need to sign in before you can go there!'
    redirect '/'
  end
end

## Helpers ##

helpers do
  def signed_in?
    !current_user.nil?
  end

  def current_user
    find_user_by_id(session['user_id'])
  end

  def show_current_status(id)
    sql = "SELECT * FROM status WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
    result = db_connection do |db|
      db.exec_params(sql, [id])
    end
    result.to_a.first
  end
  def show_current_project(id)
    sql = "SELECT * FROM projects WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
    result = db_connection do |db|
      db.exec_params(sql, [id])
    end
    result.to_a.first
  end

end

#### Status Methods #####

def update_project(userid, project)
  sql = "INSERT INTO projects (user_id, project, created_at) VALUES ($1, $2, now())"
  db_connection do |db|
    db.exec(sql,[userid, project])
  end
end

def display_current_project(id)
  sql = "SELECT * FROM projects WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
  result = db_connection do |db|
    db.exec_params(sql, [id])
  end
  result.to_a.first
end


# changed "id" to "user_id"
def update_status(userid, status)
  sql = "INSERT INTO status (user_id, status, created_at) VALUES ($1, $2, now())"
  db_connection do |db|
    db.exec(sql,[userid, status])
  end
end

# changed "id" to "user_id"
def display_current_status(id)
  sql = "SELECT * FROM status WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
  result = db_connection do |db|
    db.exec_params(sql, [id])
  end
  result.to_a.first
end

def update_profile(id, breakable, phone, blog, twitter, linkedin)
  sql = 'INSERT INTO personal_info (user_id, breakable_toy, phone_number, blog_url, twitter, linkedin, created_at) VALUES ($1, $2, $3, $4, $5, $6, now())'

  db_connection do |db|
    db.exec(sql,[id, breakable, phone, blog, twitter, linkedin])
    end
end

def display_current_personal_info(id)
  sql = "SELECT * FROM personal_info WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
    result = db_connection do |db|
      db.exec_params(sql, [id])
    end
  result.to_a.first
end

#### Routes ####

get '/' do
  erb :login
end

get '/users' do
  authenticate!
  @users = all_users
  @current_status = display_current_status(session['user_id'])

  erb :index
end

####################
### Github Auth  ###
####################
get '/auth/github/callback' do
  auth = env['omniauth.auth']
  user_attributes = user_from_omniauth(auth)
  user = find_or_create_user(user_attributes)
  session['user_id'] = user['id']
  flash[:success] = 'Thanks for logging in! Don\'t forget to update your status & current project.'

  redirect '/users'
end

# Shows profile
get '/profile/:user_id' do
  authenticate!
  @current_profile = find_user_by_id(params[:user_id])
  @current_status = display_current_status(session['user_id'])
  @current_project = display_current_project(session['user_id'])
  @current_personal_info = display_current_personal_info(session['user_id'])
  erb :profile
end
# Will update status for profile
post '/profile/:user_id' do
  @users = all_users
  update_status(session['user_id'],params[:status])
  redirect '/users'
end

post '/profile/:user_id/projects' do
  @users = all_users

  update_project(session['user_id'],params[:project])
  redirect '/users'
end

####################
### Profile Info ###
####################
get '/profile/:user_id/edit' do
  erb :personal_info_form
end

post '/profile/:user_id/edit' do

  update_profile(session['user_id'],params[:breakable_toy],params[:phone_number], params[:blog_url], params[:twitter], params[:linkedin])

  redirect to("/profile/#{params[:user_id]}")
end
####################
### Signing Out  ###
####################
get '/sign_out' do
  session.clear
  flash[:notice] = 'See ya! I hope you had an enjoyable pairing experience.'
  redirect '/'
end

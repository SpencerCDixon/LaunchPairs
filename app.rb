# This will load your environment variables from .env when your apps starts
require 'dotenv'
Dotenv.load

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'omniauth-github'
require 'pg'

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
    avatar_url: auth.info.image
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
    VALUES ($1, $2, $3, $4, $5, $6);
  }

  db_connection do |db|
    db.exec_params(sql, attr.values)
  end
end

def all_users
  db_connection do |db|
    db.exec('SELECT * FROM users')
  end
end

def authenticate!
  unless current_user
    flash[:notice] = 'You need to sign in before you can go there!'
    redirect '/'
  end
end

helpers do
  def signed_in?
    !current_user.nil?
  end

  def current_user
    find_user_by_id(session['user_id'])
  end
end

get '/' do
  erb :index
end

get '/users' do
  authenticate!
  @users = all_users

  erb :'users/index'
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']
  user_attributes = user_from_omniauth(auth)
  user = find_or_create_user(user_attributes)

  session['user_id'] = user['id']
  flash[:notice] = 'Thanks for logging in!'

  redirect '/users'
end

get '/sign_out' do
  session['user_id'] = nil
  flash[:notice] = 'See ya!'
  redirect '/'
end

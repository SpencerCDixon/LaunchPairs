# This will load your environment variables from .env when your apps starts
require 'dotenv'
Dotenv.load

require 'sinatra'
require 'sinatra/flash'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'omniauth-github'
require 'pg'
require 'flowdock'

# helpers do
#   def status_tag(status)
#     status_map = {
#       'Open for Help' => 'success'
#     }
#     classes = ['button', 'somethiong', status_map[status]].join
#     h("<a href=asdasd class='#{status_map[status]}'>")
#     content_tag(:a, text: 'Something', class: 'someting else')
#   end
# end

####################
#Config DB & OAuth #
####################
configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']

  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
  end
end

def production_database_config
  db_url_parts = ENV['DATABASE_URL'].split(/\/|:|@/)
  {
    user: db_url_parts[3],
    password: db_url_parts[4],
    host: db_url_parts[5],
    dbname: db_url_parts[7]
  }
end

configure :development do
  require 'pry'
  require 'sinatra/reloader'
  set :database_config, { dbname: 'sinatra_omniauth_dev' }
end

configure :production do
  set :database_config, production_database_config
end

####################
## Connect to DB  ##
####################

def db_connection
  begin
    connection = PG.connect(settings.database_config)
    yield(connection)
  ensure
    connection.close
  end
end

##########################
## User Create/Methods  ##
##########################

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
  VALUES ($1, 'Enter Status', now());
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

####################
###   Helpers    ###
####################

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

  def paired?(person1, person2)
    sql = "SELECT * FROM pairings WHERE (user_id = $1 AND pair_id = $2) OR (user_id = $2 AND pair_id = $1)"
    result = db_connection do |db|
      db.exec_params(sql, [person1, person2])
    end

    if result.to_a.empty?
      false
    else
      true
    end
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def show_pair(all_users,pair_id)
    current_pair = []
    all_users.each do |user|
      if user['id'] == pair_id
        current_pair << user
      end
    end
    current_pair.first
  end
end

##########################
#### Project Methods #####
##########################

def update_project(userid, project)
  sql = "INSERT INTO projects (user_id, project, created_at) VALUES ($1, $2, now())"
  db_connection do |db|
    db.exec_params(sql,[userid, project])
  end
end

def display_current_project(id)
  sql = "SELECT * FROM projects WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
  result = db_connection do |db|
    db.exec_params(sql, [id])
  end
  result.to_a.first
end

def search_users_by_project(users, query)
  found_users = []
  users.each do |user|
    if display_current_project(user['id'])['project'].downcase.include?(query.downcase)
      found_users << user
    end
  end
  found_users
end

##########################
#### Status Methods  #####
##########################

def update_status(userid, status)
  sql = "INSERT INTO status (user_id, status, created_at) VALUES ($1, $2, now())"
  db_connection do |db|
    db.exec_params(sql,[userid, status])
  end
end

def display_current_status(id)
  sql = "SELECT * FROM status WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"
  result = db_connection do |db|
    db.exec_params(sql, [id])
  end
  result.to_a.first
end

def find_all_available(users)
  available_students = []
  users.each do |user|
    if display_current_status(user['id'])['status'] == "Ready To Pair"
      available_students << user
    end
  end
  available_students
end

def find_all_help(users)
  available_students = []
  users.each do |user|
    if display_current_status(user['id'])['status'] == "Open To Help"
      available_students << user
    end
  end
  available_students
end

##########################
#### Profile Methods #####
##########################

def update_profile(id, breakable, phone, blog, twitter, linkedin)
  sql = 'INSERT INTO personal_info (user_id, breakable_toy, phone_number, blog_url, twitter, linkedin, created_at) VALUES ($1, $2, $3, $4, $5, $6, now())'

  db_connection do |db|
    db.exec_params(sql,[id, breakable, phone, blog, twitter, linkedin])
  end
end

def display_current_personal_info(id)
  sql = "SELECT * FROM personal_info WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1"

  result = db_connection do |db|
    db.exec_params(sql, [id])
  end
  result.to_a.first
end

##########################
#### Pairing Methods #####
##########################

def update_pair(user_id,pair_id)
  sql = 'INSERT INTO pairings (user_id, pair_id) VALUES ($1, $2)'

  db_connection do |db|
    db.exec(sql,[user_id,pair_id])
  end
end

def display_current_pairs(id)
  sql = "SELECT * FROM pairings WHERE user_id = $1 OR pair_id = $1"
  array_of_pairs = []
  result = db_connection do |db|
    db.exec_params(sql, [id])
  end
  result.to_a.each do |pair_combo|
    if pair_combo['pair_id'] != id
      array_of_pairs << pair_combo['pair_id']
    elsif pair_combo['user_id'] != id
      array_of_pairs << pair_combo['user_id']
    end
  end
  array_of_pairs
end

def percentage_paired(users, pairs)
  percent = pairs.to_f / users.to_f
  percent.to_f.round(2)
end

############################################################
####                    Routes                          ####
############################################################

get '/' do
  erb :login, :escape_html => true
end

get '/users' do
  authenticate!
  ## Will decide what users will be based on if there is a search ##
  if params.key?("query")
    @users = search_users_by_project(all_users, params[:query])
  else
    @users = all_users
  end
  @current_status = display_current_status(session['user_id'])

  erb :index, :escape_html => true
end

get '/users/available' do
  authenticate!
  @users = find_all_available(all_users)
  erb :index, :escape_html => true
end

get '/users/help' do
  authenticate!
  @users = find_all_help(all_users)
  erb :index, :escape_html => true
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

####################
#   Shows profile  #
####################

get '/profile/:user_id' do
  authenticate!
  @users = all_users.to_a
  @current_profile = find_user_by_id(params[:user_id])
  @current_status = display_current_status(@current_profile['id'])
  @current_project = display_current_project(@current_profile['id'])
  @current_personal_info = display_current_personal_info(@current_profile['id'])
  @current_pairs = display_current_pairs(@current_profile['id'])
  @percent_paired = percentage_paired((@users.size - 1), @current_pairs.size)
  erb :profile, :escape_html => true
end

post '/profile/:user_id' do
  authenticate!
  @users = all_users

  @user = find_user_by_id(params[:user_id])
  unless (params[:status] == "Ready To Pair") || (params[:status] == "In The Zone") || (params[:status] == "Open To Help")
    flash[:notice] = "Stop trying to hack the site! ;)"
    redirect back
  else
    update_status(session['user_id'],params[:status])
  end
  flow = Flowdock::Flow.new(:api_token => ENV['FLOW_DOCK'],
  :source => "LaunchPairs", :from => {:name => @user["name"], :address => @user["email"]})
  flow.push_to_chat(:content => "/status #{params[:status]}", :external_user_name => @user['name'].gsub!(/\s/, ""))

  redirect to("/profile/#{params[:user_id]}")
end

post '/profile/:user_id/projects' do
  authenticate!
  @users = all_users
  project = params[:project]

  update_project(session['user_id'], h(project))

  respond_to do |format|
    format.html { redirect to("/profile/#{params[:user_id]}") }
    format.json { json project: project }
  end
end

####################
### Edit Profile ###
####################

get '/profile/:user_id/edit' do
  authenticate!
  erb :personal_info_form, :escape_html => true
end

post '/profile/:user_id/edit' do
  authenticate!

  update_profile(session['user_id'],params[:breakable_toy],params[:phone_number], params[:blog_url], params[:twitter], params[:linkedin])
  flash[:notice] = "Your personal information has been updated!"
  redirect to("/profile/#{params[:user_id]}")
end

####################
###   Pairing    ###
####################

post '/users/paired/:id' do
  authenticate!
  update_pair(session['user_id'],params[:id])
  flash[:notice] = "You've added a new pair!"
  redirect '/users'
end

####################
###   Flowdock   ###
####################

get '/profile/:id/message' do
  erb :message, :escape_html => true
end

post '/profile/:id/message' do
  @user = find_user_by_id(params[:id])

  flow = Flowdock::Flow.new(:api_token => ENV['FLOW_DOCK'],
  :source => "LaunchPairs", :from => {:name => @user["name"], :address => @user["email"]})

  if params[:flow_message].include?("<") || params[:flow_message].include?(">") || params[:flow_message].include?(";")
    flash[:notice] = "Stop trying to hack the site! ;)"
    redirect back
  else
    project = params[:flow_message]
  end

  flow.push_to_chat(:content => project, :external_user_name => @user['name'].gsub!(/\s/, ""))

  flash[:success] = "Your message was sent."
  redirect to("/profile/#{params[:id]}")
end

####################
### Signing Out  ###
####################

get '/sign_out' do
  session.clear
  flash[:notice] = 'Have a great day! We hope you had an enjoyable pairing experience.'
  redirect '/'
end

####################
###     404      ###
####################

not_found do
  status 404
  erb :oops, :escape_html => true
end

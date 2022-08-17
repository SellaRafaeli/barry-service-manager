require 'rubygems'
require 'bundler'
require 'sinatra/namespace'
require 'sinatra/reloader' #dev-only
require 'active_support/core_ext/hash/slice'
require 'json' 

Bundler.require

# our app files - export to separate require.rb file when grows out of hand
require './lib/mylib'
require './settings'
require './middleware/middleware_incoming'
require './middleware/middleware_outgoing'
require './middleware/error_handling.rb'
require './db/mongo'
require './users/user'
require './users/users_api'
require './current_user/current_user_api'

get '/' do 
	send_file File.join(settings.public_folder, 'index.html')
end

get '/ping' do
	{msg: 'pong from barry service manager'}
end

require 'open3'
# GET localhost:6060/exec?cmd=ls
# GET localhost:6060/exec?cmd=cat app.rb
get '/exec' do 
	cmd = params[:cmd]
	res = nil
	Open3.popen3(cmd) do |stdin, stdout, stderr|
  	res = stdout.read
	end

	{res:res}
end 
	
puts "Ready to rock".light_red


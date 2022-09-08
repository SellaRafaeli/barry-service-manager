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
	#send_file File.join(settings.public_folder, 'index.html')
	{msg: 'hello from bsm root'}
end

get '/ping' do
	{msg: 'pong from barry service manager', version: 'second version'}
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

# Script Actions API
ADMIN_TOKEN = ENV['ADMIN_TOKEN'] || 'foo'

SCRIPTS = Dir['./scripts/**/*.sh'].map {|f| f.gsub('./scripts/','').gsub('.sh','') }
SCRIPTS.each do |script|
	puts "setting up /#{script}"
	# GET http://localhost:8100/scripts/_example?token=foo&args=bar,baz
	get "/scripts/#{script}" do 
		token = params[:token]
		args  = params[:args] ? params[:args].split(',').join(' ') : ''
		halt(401, 'missing token') unless token == ADMIN_TOKEN
		{res: `sudo -E ./scripts/#{script}.sh #{args}`}
	end
end

puts "Ready to rock".light_red


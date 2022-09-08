This Service Manager allows an HTTP interface to manage servers and apps on Barry's Cloud servers.

## Installation 

$ git clone https://github.com/sellarafaeli/barry-service-manager.git

$ cd barry-service-manager

$ bundle install

$ bundle exec rackup -p 79


## SSH into app servers 

ssh -i ./barry_ssh ubuntu@<ip address>



## Usage 

$BSM = [IP]

POST $BSM/install-app?git_url=url_encode(github.com/...)&name=bla
POST $BSM/render-env

POST $BSM/restart-app


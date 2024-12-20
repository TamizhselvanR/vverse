# README

API server setup:

Download brew:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

on succesive install of brew well see these commands, we have to run them
echo >> /Users/tamizh/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/tamizh/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

Install Rbenv to install ruby

brew install rbenv

rbenv instal 3.3.0

rbenv global 3.3.0

copy below to ~bash_profile

export PATH="$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init -)"


brew install redis

brew install ffmpeg


Move to vverse repo

sudo gem install bundler

bundle i


rails active_storage:install 

rails db:migrate


Starting redis and rails server:

brew services start redis

bundle exec rails s


Troubleshooting:


In anycase when 

sudo gem install bundler or

bundle i

fails try running this below commands and chck ruby version it should be 3.3.0

export PATH="$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init -)"
* ...

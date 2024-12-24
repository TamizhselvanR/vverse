# README

## API server setup:

**Download brew:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

on succesive install of brew well see these commands, we have to run them
```bash
echo >> /Users/tamizh/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/tamizh/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Install Rbenv to install ruby

```bash
brew install rbenv
rbenv instal 3.3.0
rbenv global 3.3.0
```

Copy below to ~bash_profile

```bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```

```bash
brew install redis
brew install ffmpeg
```

Move to vverse repo

```bash
sudo gem install bundler
bundle i
```

```bash
rails active_storage:install 
rails db:migrate
```

Starting redis and rails server:

```bash
brew services start redis
bundle exec rails s
```

## Troubleshooting:

In anycase when 

```bash
sudo gem install bundler or
bundle i
```
fails try running this below commands and chck ruby version it should be 3.3.0
```bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```

## Test cases:

To run test follow the below commands:

run
```bash
bundle i
```
to install rspec-rails gem which will help in running test cases

To run the controller test file, do
```bash
bundle exec bundle exec rspec spec/controllers/videos_controller_spec.rb
```

Once tests are executed we will see a dir location like below, which will have coverage details
```bash
Coverage report generated for RSpec to /Users/tamizhselvanr/Documents/assigments/vverse/coverage.
Line Coverage: 92.36% (145 / 157)
```

## Troubleshooting tests

If you face any issues while running tests similar to below one
```bash
undefined method `fixture_path=' for class RSpec::ExampleGroups:
```
try below commands and run tests again
```bash
rm Gemfile.lock
bundle install
bundle exec bundle exec rspec spec/controllers/videos_controller_spec.rb
```


## Demo Files

I've added the Postman collection and a sample video in the `demo_files` directory. You can access them here:

- [Postman Collection and Sample Video](https://github.com/TamizhselvanR/vverse/tree/main/demo_files)


Link to the demo showcasing the feature in action :- https://drive.google.com/file/d/1RzPHk_gMc2dWvi1HdKe1yaZGG7UtkhPh/view?usp=sharing
* ...

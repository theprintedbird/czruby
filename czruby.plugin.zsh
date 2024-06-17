## Change Ruby

## This Zsh script is designed to manage different Ruby environments.
## It allows the user to switch between various Ruby versions
## and sets up environment variables for Ruby and Gem paths.


# Perform initial setup and set the Ruby environment
# to the default or specified Ruby.
czruby_setup
czruby "$RUBIES_DEFAULT"

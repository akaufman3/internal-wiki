require "sinatra"
require 'bundler/setup'
require "pg"
require "pry"
require "bcrypt"


run InternalWiki::Server
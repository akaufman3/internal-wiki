require "sinatra"
require 'bundler/setup'
require "pg"
require "pry"
require "bcrypt"

require_relative "internal_wiki"

run InternalWiki::Server
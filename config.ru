require "sinatra"
require 'bundler/setup'
require "faker"
require "pg"
require "pry"
require_relative "internal_wiki"

run InternalWiki::Server
require "sinatra"
require "pg"

class InternalWiki::Server < Sinatra::Base
	include InternalWiki

	get "/" do
		@articles = db.exec_params("SELECT * FROM article_list")
		erb :index
	end

end
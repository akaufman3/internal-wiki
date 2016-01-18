require "sinatra"
require "pg"

class InternalWiki::Server < Sinatra::Base
	include InternalWiki

	get "/" do
		@articles = db.exec_params("SELECT * FROM article_list")
		erb :index
	end

	get "/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec("SELECT * FROM article WHERE id = #{@article_id}").to_a
		erb :article
	end

	get "/edit/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec("SELECT * FROM article WHERE id = #{@article_id}").to_a
		erb :edit
	end

	get "/add/" do
		erb :add
	end

end
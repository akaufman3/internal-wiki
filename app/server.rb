require "sinatra"
require "pg"
require "active_support/all"

class InternalWiki::Server < Sinatra::Base
	include InternalWiki

	get "/" do
		@articles = db.exec_params("SELECT * FROM article_list").to_a
		erb :index
	end

	get "/article/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec("SELECT * FROM article WHERE id = #{@article_id}").to_a
		erb :article
	end

	get "/add" do
		@categories = db.exec("SELECT * FROM categories").to_a
		erb :add
	end

	post "/add" do
		title = params["title"]
    	author = params["author"]
    	copy = params["copy"]
    	article_id = params["article_id"]
    	category= params["category"]
    	date_created = DateTime.now
    	date_formatted = date_created.to_formatted_s(:long)

    	@make_article = db.exec_params(
    		"INSERT INTO article (author, title, category, date_created, copy) VALUES ($1, $2, $3, $4, $5) RETURNING id",
    		[author, title, category, date_formatted, copy]
    	)

    	@new_article_id = @make_article.to_a.first['id'].to_i

    	db.exec("INSERT INTO article_list (category, author, title, date_created, article_id) SELECT category, author, title, date_created, id FROM article WHERE id = #{@new_article_id}")

    	redirect "/article/#{@new_article_id}"

		erb :add
	end

	get "/edit/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec("SELECT * FROM article WHERE id = #{@article_id}").to_a
		@categories = db.exec("SELECT * FROM categories").to_a
		erb :edit
	end

	post "/edit/:article_id" do
		@id = params[:article_id].to_i
		binding.pry
		title = params["title"]
    	author = params["author"]
    	copy = params["copy"]
    	article_id = params["article_id"]
    	category= params["category"]
    	date_updated = DateTime.now
    	date_updated_formatted = date_updated.to_formatted_s(:long)


    	redirect "/article/#{@id}"
    	erb :edit
	end

end
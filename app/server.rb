require "sinatra"
require "pg"
require "active_support/all"
require "colorize"
require "redcarpet"

class InternalWiki::Server < Sinatra::Base
	include InternalWiki

	enable :sessions

	set :method_override, true

	def current_user
		if session["user_id"]
			@current_user ||= db.exec_params(<<-SQL, [session["user_id"]]).first
				SELECT * FROM users WHERE id = $1
			SQL
		else
			{}
		end
	end

	def markdown 
		@markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
	end

	get "/" do
		@articles = db.exec("SELECT * FROM article_list").to_a
		erb :index
	end

	get "/signup" do
		if params[:e] == "2"
			@error = "User does not exist"
		end
		erb :signup 
	end

	post "/signup" do
		encrypted_password = BCrypt::Password.create(params[:password_digest])
		new_user = db.exec_params(<<-SQL, [params[:fname], params[:lname], params[:position], params[:email], encrypted_password])
			INSERT INTO users (fname, lname, position, email, password_digest)
			VALUES ($1, $2, $3, $4, $5) RETURNING id;
		SQL
		session["user_id"] = new_user.first["id"]
		redirect "/?login=true"
	end

	get "/login" do
		if params["e"] == "1"
			@error = "Invalid Password"
		end
		erb :login
	end

	post "/login" do
		@email = params[:email]
		@password = params[:password]
		@user_info = db.exec_params("SELECT * FROM users WHERE email = $1", [@email]).first
		@user_password = @user_info["password_digest"]
		puts "LOGIN ATTEMPTED".red
		if @user_info
			if BCrypt::Password.new(@user_password) == @password
				puts "LOGIN SUCCESSFUL".red
				session["user_id"] = @user_info["id"]
				redirect "/?login=true"
			else
				puts "INCORRECT PASSWORD: ROUTE TO '/'".red
				@error = "Invalid Password"
				redirect "/login?e=1"
			end
		else
			redirect "/signup?e=2"
		end
	end

	get "/log_out" do
		session["user_id"] = nil;
		redirect "/login"
	end

	get "/add" do
		@categories = db.exec("SELECT * FROM categories").to_a
		erb :add
	end

	post "/add" do
		creator = "#{current_user['fname']} #{current_user['lname']}"
		user_id = current_user['id'].to_i
		title = params["title"]
    	author = params["author"]
    	copy = params["copy"]
    	article_id = params["article_id"]
    	category = params["category"]
    	date_created = DateTime.now
    	date_formatted = date_created.to_formatted_s(:long)

    	@make_article = db.exec_params(
    		"INSERT INTO article (creator_name, user_id, author, title, category, date_created, copy) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id",
    		[creator, user_id, author, title, category, date_formatted, copy]
    	)

    	@new_article_id = @make_article.to_a.first['id'].to_i

    	#How do you reformat this line with params?
    	db.exec("INSERT INTO article_list (category, author, title, date_created, article_id) SELECT category, author, title, date_created, id FROM article WHERE id = #{@new_article_id}")

    	redirect "/article/#{@new_article_id}"

		erb :add
	end

	get "/article/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec_params("SELECT * FROM article WHERE id = $1", [@article_id]).to_a
		article_copy = @article_info.first["copy"]
		@copy_rendered = markdown.render(article_copy)

		@all_comments = db.exec_params("SELECT * FROM comment WHERE article_id = $1", [@article_id]).to_a
		binding.pry
		erb :article
	end

	get "/edit/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec("SELECT * FROM article WHERE id = $1", [@article_id]).to_a
		@categories = db.exec("SELECT * FROM categories").to_a
		erb :edit
	end

	put "/edit/:article_id" do
		@id = params[:article_id].to_i
		title = params["title"]
    	author = params["author"]
    	copy = params["copy"]
    	category = params["category"]

    	db_title = db.exec_params("SELECT title FROM article WHERE id = $1", [@id]).to_a.first["title"]
    	db_author = db.exec("SELECT author FROM article WHERE id = $1", [@id]).to_a.first["author"]
    	db_copy = db.exec("SELECT copy FROM article WHERE id = $1", [@id]).to_a.first["copy"]
    	db_category = db.exec("SELECT category FROM article WHERE id = $1", [@id]).to_a.first["category"]
    	if title != db_title || author != db_author || copy != db_copy || category != db_category
	    	date_updated = DateTime.now
	    	date_updated_formatted = date_updated.to_formatted_s(:long)
	    	db.exec_params("UPDATE article SET author = $1, title = $2, category = $3, date_updated = $4, copy = $5 WHERE id = $6", [author, title, category, date_updated_formatted, copy, @id])
	    	db.exec_params("UPDATE article_list SET category = $1, author = $2, title = $3 WHERE article_id = $4", [category, author, title, @id])
	    end

    	redirect "/article/#{@id}"
	end

	delete '/edit/:article_id' do
		@id = params[:article_id].to_i

		# db.exec_params("DELETE FROM article WHERE id = $1",[@id]).first
    	db.exec_params("DELETE FROM article_list WHERE article_id = $1",[@id]).first

	  redirect '/'
	end

	post '/submit/:article_id' do
		@article_id = params[:article_id].to_i
		comment = params[:commentEntry]
		author = "#{current_user['fname']} #{current_user['lname']}"
		date_created = DateTime.now
    	date_formatted = date_created.to_formatted_s(:long)

    	db.exec_params(
    		"INSERT INTO comment (article_id, comment, author, date_created) VALUES ($1, $2, $3, $4)",
    		[@article_id, comment, author, date_formatted]
    	)

		redirect "/article/#{@article_id}"
	end

end
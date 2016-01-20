require "sinatra"
require "pg"
require "active_support/all"
require "colorize"

class InternalWiki::Server < Sinatra::Base
	include InternalWiki

	enable :sessions

	def current_user
		if session["user_id"]
			@current_user ||= db.exec_params(<<-SQL, [session["user_id"]]).first
				SELECT * FROM users WHERE id = $1
			SQL
		else
			{}
		end
	end

	get "/" do
		@articles = db.exec_params("SELECT * FROM article_list").to_a
		erb :index
	end

	get "/signup" do
		if params[:e] == 2
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
		if params[:e] == 1
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
    	category = params["category"]
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
		title = params["title"]
    	author = params["author"]
    	copy = params["copy"]
    	category = params["category"]
    	date_updated = DateTime.now
    	date_updated_formatted = date_updated.to_formatted_s(:long)

    	db.exec("UPDATE article SET author = '#{author}', title = '#{title}', category = '#{category}',  date_updated = '#{date_updated_formatted}', copy = '#{copy}' WHERE id = #{@id}")

    	db.exec("UPDATE article_list SET category = '#{category}', author = '#{author}', title = '#{title}' WHERE article_id = #{@id}")

    	redirect "/article/#{@id}"
	end

end
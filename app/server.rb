require "sinatra"
require "pg"
require "active_support/all"
require "colorize"
require "redcarpet"

require_relative "internal_wiki"


class InternalWiki::Server < Sinatra::Base
	# include InternalWiki

	enable :sessions

	set :method_override, true

	if ENV['RACK_ENV'] == 'production'
     	@@db = PG.connect(
        dbname: ENV['POSTGRES_DB'],
        host: ENV['POSTGRES_HOST'],
        password: ENV['POSTGRES_PASS'],
        user: ENV['POSTGRES_USER']
      )
    end

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
		@articles = db.exec("SELECT * FROM article_list ORDER BY rating LIMIT 10").to_a
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
    		"INSERT INTO article (creator_name, user_id, author, title, category, date_created, copy, rating, total_votes) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id",
    		[creator, user_id, author, title, category, date_formatted, copy, 0, 0]
    	)

    	@new_article_id = @make_article.to_a.first['id'].to_i

    	#How do you reformat this line with params?
    	db.exec("INSERT INTO article_list (category, author, title, date_created, article_id) SELECT category, author, title, date_created, id FROM article WHERE id = #{@new_article_id}")


    	db.exec_params(
    		"INSERT INTO article_rating (article_id, five, four, three, two, one) VALUES ($1, $2, $3, $4, $5, $6)",
    		[@new_article_id, 0, 0, 0, 0, 0]
    	)

    	redirect "/article/#{@new_article_id}"

		erb :add
	end

	get "/article/:article_id" do
		@article_id = params[:article_id].to_i
		@article_info = db.exec_params("SELECT * FROM article WHERE id = $1", [@article_id]).to_a
		article_copy = @article_info.first["copy"]
		@copy_rendered = markdown.render(article_copy)

		@all_comments = db.exec_params("SELECT * FROM comment WHERE article_id = $1", [@article_id]).to_a

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

	put '/rating/:article_id' do
		@article_id = params[:article_id].to_i		
		rating = params[:rating].to_i

		db_total_five = db.exec_params("SELECT * FROM article_rating WHERE article_id = $1", [@article_id]).to_a.first["five"].to_i
		db_total_four = db.exec_params("SELECT * FROM article_rating WHERE article_id = $1", [@article_id]).to_a.first["four"].to_i
		db_total_three = db.exec_params("SELECT * FROM article_rating WHERE article_id = $1", [@article_id]).to_a.first["three"].to_i
		db_total_two = db.exec_params("SELECT * FROM article_rating WHERE article_id = $1", [@article_id]).to_a.first["two"].to_i
		db_total_one = db.exec_params("SELECT * FROM article_rating WHERE article_id = $1", [@article_id]).to_a.first["one"].to_i
		db_total_votes = db.exec_params("SELECT * FROM article WHERE id = $1", [@article_id]).to_a.first["total_votes"].to_i
		db_article_rating = db.exec_params("SELECT * FROM article WHERE id = $1", [@article_id]).to_a.first["rating"].to_i
		
		if rating != 5
			new_db_total_rating_five = db_total_five
		elsif rating == 5
			new_db_total_rating_five = db_total_five + 1
			db.exec_params("UPDATE article_rating SET five = $1", [new_db_total_rating_five])
		end

		if rating != 4
			new_db_total_rating_four = db_total_four
		elsif rating == 4
			new_db_total_rating_four =  db_total_four + 1
			db.exec_params("UPDATE article_rating SET four = $1", [new_db_total_rating_four])
		end

		if rating != 3
			new_db_total_rating_three = db_total_three
		elsif rating == 3
			new_db_total_rating_three =  db_total_three + 1
			db.exec_params("UPDATE article_rating SET three = $1", [new_db_total_rating_three])
		end

		if rating != 2
			new_db_total_rating_two = db_total_two
		elsif rating == 2
			new_db_total_rating_two =  db_total_two + 1
			db.exec_params("UPDATE article_rating SET two = $1", [new_db_total_rating_two])
		end

		if rating != 1
			new_db_total_rating_one = db_total_one
		elsif rating == 1
			new_db_total_rating_one = db_total_one + 1
			db.exec_params("UPDATE article_rating SET one = $1", [new_db_total_rating_one])
		end

		if new_db_total_rating_five != 0
			total_five = new_db_total_rating_five * 5
		else
			total_five = 0
		end

		if new_db_total_rating_four != 0
			total_four = new_db_total_rating_four * 4
		else
			total_four = 0
		end

		if new_db_total_rating_three != 0
			total_three = new_db_total_rating_three * 3
		else
			total_three = 0
		end

		if new_db_total_rating_two != 0
			total_two = new_db_total_rating_two * 2
		else
			total_two = 0
		end

		if new_db_total_rating_one != 0
			total_one = new_db_total_rating_one * 1
		else 
			total_one = 0
		end

		total_vote_value = total_five + total_four + total_three + total_two + total_one
		new_number_votes = db_total_votes + 1
		new_rating = (total_vote_value) / new_number_votes

		db.exec_params("UPDATE article SET rating = $1, total_votes = $2 WHERE id = $3", [new_rating, new_number_votes, @article_id])

		db.exec_params("UPDATE article_list SET rating = $1 WHERE article_id = $2", [new_rating, @article_id])

		redirect "/article/#{@article_id}"
	end

end
require "sinatra/base"
require "pg"

module Internal_Wiki
	class Server < Sinatra::Base

		get "/" do
			erb :index
		end

	end
end
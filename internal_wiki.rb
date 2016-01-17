require "pg"

module InternalWiki
	DBNAME = "internal_wiki"
	require_relative "app/server"

	def db
		@db ||= PG.connect(dbname: DBNAME)
	end
end
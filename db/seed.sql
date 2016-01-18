DROP TABLE IF EXISTS article CASCADE;
DROP TABLE IF EXISTS article_list CASCADE;

CREATE TABLE article (
	author_id		INTEGER NOT NULL,
	user_id			INTEGER NOT NULL,
	author			VARCHAR NOT NULL,
	title			VARCHAR NOT NULL,
	category		VARCHAR NOT NULL,
	article_log_id  INTEGER NOT NULL,
	comments_id		INTEGER NOT NULL,
	date_created	VARCHAR NOT NULL,
	copy			VARCHAR NOT NULL,
	rating			INTEGER,
	id 				SERIAL PRIMARY KEY
);

CREATE TABLE article_list (
	category	 VARCHAR NOT NULL,
	author		 VARCHAR NOT NULL,
	title		 VARCHAR NOT NULL,
	rating		 INTEGER,
	date_created VARCHAR NOT NULL,
	article_id 	 INTEGER REFERENCES article(id)
);

INSERT INTO article
	(author_id, user_id, author, title, category, article_log_id, comments_id, date_created, copy, rating, id)
VALUES
(1, 1, 'Amelia Kaufman', 'Food, eat it all', 'food', 1, 1, 'January 1, 2016', 'hello', '5', 1),
(1, 1, 'Amelia Kaufman', 'Drink, eat it all', 'drink', 1, 1, 'January 1, 2016', 'yo', '4', 2);

INSERT INTO article_list
	(category, author, title, rating, date_created, article_id)
VALUES
('food', 'Amelia Kaufman', 'Food, eat it all', '5', 'January 1, 2016', 1 ),
('drink', 'Amelia Kaufman', 'Drink, eat it all', '4', 'January 2, 2016', 2 );

DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS article CASCADE;
DROP TABLE IF EXISTS article_list CASCADE;

CREATE TABLE categories (
	id 	 	 SERIAL PRIMARY KEY,
	category VARCHAR
);

CREATE TABLE article (
	author_id		INTEGER,
	user_id			INTEGER,
	author			VARCHAR,
	title			VARCHAR,
	category		VARCHAR,
	article_log_id  INTEGER,
	comments_id		INTEGER,
	date_created	VARCHAR,
	copy			VARCHAR,
	rating			INTEGER,
	id 				SERIAL PRIMARY KEY
);

CREATE TABLE article_list (
	category		VARCHAR,
	author		 	VARCHAR,
	title		 	VARCHAR,
	rating		 	INTEGER,
	date_created 	VARCHAR,
	article_id 	 	INTEGER REFERENCES article(id)
);

-- create categories
INSERT INTO categories
  (category)
VALUES
  ('Easy'),
  ('Healthy'),
  ('Dinner'),
  ('Gluten-free'),
  ('Vegetarian'),
  ('Drink'),
  ('Breakfast'),
  ('Lunch');


-- INSERT INTO article
-- 	(author_id, user_id, author, title, category, article_log_id, comments_id, date_created, copy, rating, id)
-- VALUES
-- (1, 1, 'Amelia Kaufman', 'Food, eat it all', 'food', 1, 1, 'January 1, 2016', 'hello', '5', 1),
-- (1, 1, 'Amelia Kaufman', 'Drink, eat it all', 'drink', 1, 1, 'January 1, 2016', 'yo', '4', 2);

-- INSERT INTO article_list
-- 	(category, author, title, rating, date_created, article_id)
-- VALUES
-- ('food', 'Amelia Kaufman', 'Food, eat it all', '5', 'January 1, 2016', 1 ),
-- ('drink', 'Amelia Kaufman', 'Drink, eat it all', '4', 'January 2, 2016', 2 );

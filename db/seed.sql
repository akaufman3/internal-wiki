DROP TABLE IF EXISTS article_list CASCADE;

CREATE TABLE article_list (
	category	VARCHAR NOT NULL,
	author		VARCHAR NOT NULL,
	title		VARCHAR NOT NULL,
	rating		INTEGER NOT NULL,
	date_created VARCHAR NOT NULL
);

INSERT INTO article_list
	(category, author, title, rating, date_created)
VALUES
('food', 'Amelia Kaufman', 'Food, eat it all', '4', 'January 1, 2016' ),
('drink', 'Samuel Erickson', 'Drink, drink it all', '5', 'January 2, 2016' );


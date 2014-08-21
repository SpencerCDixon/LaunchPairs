CREATE TABLE users(
  id serial PRIMARY KEY,
  uid varchar(255) NOT NULL,
  provider varchar(255) NOT NULL,
  username varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  avatar_url varchar(255) NOT NULL
);

CREATE TABLE profiles (
  id integer references users(id),
  blog varchar(255) ,
  status varchar(255) 
);

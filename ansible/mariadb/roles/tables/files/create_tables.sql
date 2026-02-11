DROP TABLE IF EXISTS mydb.mytable;
CREATE TABLE mydb.mytable (
  id INTEGER PRIMARY KEY,
  name TEXT,
  val  TEXT
) DEFAULT CHARSET=utf8mb4;

INSERT INTO mydb.mytable VALUES ( 1, 'hoge', 'foo' );





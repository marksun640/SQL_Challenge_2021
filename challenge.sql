-- You may optionally include a second le, challenge_setup.sql, containing any one-time setup
-- steps. For example, this le may contain stored procedure, view, or function denitions, add any
-- indices, etc. This le will be run once before evaluating your query on many dierent test cases.
-- DELIMITER $$
-- DROP FUNCTION IF EXISTS LEVENSHTEIN $$
-- CREATE FUNCTION LEVENSHTEIN(s1 VARCHAR(255) CHARACTER SET utf8, s2 VARCHAR(255) CHARACTER SET utf8)
-- RETURNS INT
-- DETERMINISTIC
-- BEGIN
-- DECLARE s1_len, s2_len, i, j, c, c_temp, cost INT;
-- DECLARE s1_char CHAR CHARACTER SET utf8;
-- -- max strlen=255 for this function
-- DECLARE cv0, cv1 VARBINARY(256);
-- SET s1_len = CHAR_LENGTH(s1),
-- s2_len = CHAR_LENGTH(s2),
-- cv1 = 0x00,
-- j = 1,
-- i = 1,
-- c = 0;
-- IF (s1 = s2) THEN
-- RETURN (0);
-- ELSEIF (s1_len = 0) THEN
-- RETURN (s2_len);
-- ELSEIF (s2_len = 0) THEN
-- RETURN (s1_len);
-- END IF;
-- WHILE (j <= s2_len) DO
-- SET cv1 = CONCAT(cv1, CHAR(j)),
-- j = j + 1;
-- END WHILE;
-- WHILE (i <= s1_len) DO
-- SET s1_char = SUBSTRING(s1, i, 1),
-- c = i,
-- cv0 = CHAR(i),
-- j = 1;
-- WHILE (j <= s2_len) DO
-- SET c = c + 1,
-- cost = IF(s1_char = SUBSTRING(s2, j, 1), 0, 1);
-- SET c_temp = ORD(SUBSTRING(cv1, j, 1)) + cost;
-- IF (c > c_temp) THEN
-- SET c = c_temp;
-- END IF;
-- SET c_temp = ORD(SUBSTRING(cv1, j+1, 1)) + 1;
-- IF (c > c_temp) THEN
-- SET c = c_temp;
-- END IF;
-- SET cv0 = CONCAT(cv0, CHAR(c)),
-- j = j + 1;
-- END WHILE;
-- SET cv1 = cv0,
-- i = i + 1;
-- END WHILE;
-- RETURN (c);
-- END $$
-- DELIMITER ;

-- You will find a dump of a sample database (misspellings.sql) in our
-- shared data folder. This is essentially the same list of misspellings
-- we used in our Python lab, so you can use that source data file to 
-- check your accuracy.
-- 
-- We will use a more extensive database on our server
-- for official scoring. You can assume the table and column names
-- remain the same.


-- You can uncomment this for testing, but leave it commented out
-- when you submit your script.
-- USE misspellings;


-- You can uncomment this for testing, but leave it commented out
-- when you submit your script. The system will set this variable to 
-- various target words when scoring your query.
-- SET @word = 'immediately';


-- Here is a very basic approach (removing double m's) that returns
-- 2 of the 6 variants in the sample database when searching for 
-- 'immediately'.
-- SELECT id, misspelled_word
--   FROM word 
--  WHERE REPLACE(misspelled_word, 'mm', 'm') = REPLACE(@word, 'mm', 'm');
 
 -- Your query only needs to return the id column. Any additional 
 -- columns returned by your query will be ignored.

-- -- version 1
--  SELECT id, misspelled_word 
--  FROM word
--  WHERE SOUNDEX(misspelled_word) =SOUNDEX(@word);
--  and misspelled_word <> @word;

-- v2
-- SELECT id, misspelled_word 
-- FROM word
-- WHERE SOUNDEX(misspelled_word) =SOUNDEX(@word) and levenshtein(misspelled_word, @word)<=2;

-- SELECT id, misspelled_word 
-- FROM word
-- WHERE SOUNDEX(misspelled_word) =SOUNDEX(@word)
-- OR levenshtein(misspelled_word, @word)<=2;


-- v3
CREATE FUNCTION edit_distance(@s1 nvarchar(3999), @s2 nvarchar(3999))
RETURNS int
AS
BEGIN
 DECLARE @s1_len int, @s2_len int
 DECLARE @i int, @j int, @s1_char nchar, @c int, @c_temp int
 DECLARE @cv0 varbinary(8000), @cv1 varbinary(8000)

 SELECT
  @s1_len = LEN(@s1),
  @s2_len = LEN(@s2),
  @cv1 = 0x0000,
  @j = 1, @i = 1, @c = 0

 WHILE @j <= @s2_len
  SELECT @cv1 = @cv1 + CAST(@j AS binary(2)), @j = @j + 1

 WHILE @i <= @s1_len
 BEGIN
  SELECT
   @s1_char = SUBSTRING(@s1, @i, 1),
   @c = @i,
   @cv0 = CAST(@i AS binary(2)),
   @j = 1

  WHILE @j <= @s2_len
  BEGIN
   SET @c = @c + 1
   SET @c_temp = CAST(SUBSTRING(@cv1, @j+@j-1, 2) AS int) +
    CASE WHEN @s1_char = SUBSTRING(@s2, @j, 1) THEN 0 ELSE 1 END
   IF @c > @c_temp SET @c = @c_temp
   SET @c_temp = CAST(SUBSTRING(@cv1, @j+@j+1, 2) AS int)+1
   IF @c > @c_temp SET @c = @c_temp
   SELECT @cv0 = @cv0 + CAST(@c AS binary(2)), @j = @j + 1
 END

 SELECT @cv1 = @cv0, @i = @i + 1
 END

 RETURN @c
END
;

-- SELECT id, misspelled_word 
-- FROM word
-- WHERE SOUNDEX(misspelled_word) =SOUNDEX(@word)
-- OR edit_distance(misspelled_word, @word)<=2;

-- v4 

SELECT id, misspelled_word 
FROM word
WHERE SOUNDEX(misspelled_word) =SOUNDEX(@word)
OR DamerauLevenschtein(misspelled_word, @word)<=2;


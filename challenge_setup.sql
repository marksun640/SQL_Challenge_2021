-- You may optionally include a second le, challenge_setup.sql, containing any one-time setup
-- steps. For example, this le may contain stored procedure, view, or function denitions, add any
-- indices, etc. This le will be run once before evaluating your query on many dierent test cases.
DELIMITER $$
DROP FUNCTION IF EXISTS LEVENSHTEIN $$
CREATE FUNCTION LEVENSHTEIN(s1 VARCHAR(255) CHARACTER SET utf8, s2 VARCHAR(255) CHARACTER SET utf8)
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE s1_len, s2_len, i, j, c, c_temp, cost INT;
DECLARE s1_char CHAR CHARACTER SET utf8;
-- max strlen=255 for this function
DECLARE cv0, cv1 VARBINARY(256);
SET s1_len = CHAR_LENGTH(s1),
s2_len = CHAR_LENGTH(s2),
cv1 = 0x00,
j = 1,
i = 1,
c = 0;
IF (s1 = s2) THEN
RETURN (0);
ELSEIF (s1_len = 0) THEN
RETURN (s2_len);
ELSEIF (s2_len = 0) THEN
RETURN (s1_len);
END IF;
WHILE (j <= s2_len) DO
SET cv1 = CONCAT(cv1, CHAR(j)),
j = j + 1;
END WHILE;
WHILE (i <= s1_len) DO
SET s1_char = SUBSTRING(s1, i, 1),
c = i,
cv0 = CHAR(i),
j = 1;
WHILE (j <= s2_len) DO
SET c = c + 1,
cost = IF(s1_char = SUBSTRING(s2, j, 1), 0, 1);
SET c_temp = ORD(SUBSTRING(cv1, j, 1)) + cost;
IF (c > c_temp) THEN
SET c = c_temp;
END IF;
SET c_temp = ORD(SUBSTRING(cv1, j+1, 1)) + 1;
IF (c > c_temp) THEN
SET c = c_temp;
END IF;
SET cv0 = CONCAT(cv0, CHAR(c)),
j = j + 1;
END WHILE;
SET cv1 = cv0,
i = i + 1;
END WHILE;
RETURN (c);
END $$
DELIMITER ;

-- v4
CREATE function DamerauLevenschtein ( SourceString nvarchar(100), TargetString nvarchar(100) ) 
-- Returns the Damerau Levenshtein Distance between SourceString string and TargetString
-- Updated by Phil Factor to add transposition as an edit
returns int

BEGIN
-- DECLARE  SourceString nvarchar(100)='achieve', TargetString nvarchar(100)='acheive'
DECLARE Matrix Nvarchar(4000), LD int, TargetStringLength int, SourceStringLength int,
ii int, jj int, CurrentSourceChar nchar(1), CurrentTargetChar nchar(1),Cost int, 
Above int,AboveAndToLeft int,ToTheLeft int, MinimumValueOfCells INT, previous INT
 
-- Step 1: Set n to be the length of s. Set m to be the length of t. 
  SELECT SourceString=RTRIM(LTRIM(COALESCE(sourceString,''))),
         TargetString=RTRIM(LTRIM(COALESCE(TargetString,''))),
		 SourceStringLength=LEN(SourceString), 
         TargetStringLength=LEN(TargetString)
 
  -- remove matches at the beginning and end
  IF SUBSTRING(sourceString,1,1)=SUBSTRING(targetString,1,1)
  BEGIN
  SET ii=1
  WHILE SUBSTRING(sourceString+'!!',ii+1,1)=SUBSTRING(targetString+'??',ii+1,1)
    BEGIN
    SELECT ii=ii+1 
    END
  SELECT sourceString=STUFF(sourceString,1,ii,''),
         targetString=STUFF(targetString,1,ii,'')
  END
 
 SELECT SourceStringLength =LEN(sourceString), TargetStringLength =LEN(TargetString) 
 IF SUBSTRING(sourceString,SourceStringLength,1)=SUBSTRING(targetString,TargetStringLength,1)
  BEGIN
  WHILE SUBSTRING(sourceString,SourceStringLength-1,1)=SUBSTRING(targetString,TargetStringLength-1,1) 
	AND SourceStringLength>0 AND TargetStringLength>0
    BEGIN
    SELECT SourceStringLength=SourceStringLength-1,
	       TargetStringLength=TargetStringLength-1
	END
  SELECT sourceString=LEFT(sourceString,SourceStringLength)
  SELECT targetString=LEFT(targetString,TargetStringLength)
  END
--    If n = 0, return m and exit.
--    If m = 0, return n and exit.
If SourceStringLength = 0 return TargetStringLength
If TargetStringLength = 0 return SourceStringLength
if (TargetStringLength+1)*(SourceStringLength+1)> 4000 return -1
  IF SourceStringLength=1 
    RETURN TargetStringLength
          -CASE WHEN CHARINDEX(SourceString,TargetString)>0 THEN 1 ELSE 0 end
  IF TargetStringLength=1 
    RETURN SourceStringLength
          -CASE WHEN CHARINDEX(TargetString,SourceString)>0 THEN 1 ELSE 0 end
--    Construct a matrix containing 0..m rows and 0..n columns.
SELECT Matrix=replicate(nchar(0),(SourceStringLength+1)*(TargetStringLength+1))
--Step 2: Initialize the first row to 0..n.
--     Initialize the first column to 0..m.
SET ii=0
WHILE ii<=SourceStringLength
    BEGIN
    SET Matrix=STUFF(Matrix,ii+1,1,nchar(ii))--d(i, 0) = i
    SET ii=ii+1
    END
SET ii=0
WHILE ii<=TargetStringLength
    BEGIN
    SET Matrix=STUFF(Matrix,ii*(SourceStringLength+1)+1,1,nchar(ii))--d(0, j) = j
    SET ii=ii+1
    END
--Step 3 Examine each character of s (i from 1 to n).
SET ii=1
WHILE ii<=SourceStringLength
    BEGIN
--Step 4   Examine each character of t (j from 1 to m).
    SET jj=1
    WHILE jj<=TargetStringLength
        BEGIN
--Step 5 and 6
        Select 
        --Set cell d[i,j] of the matrix equal to the minimum of:
        --a. The cell immediately above plus 1: d[i-1,j] + 1.
        --b. The cell immediately to the left plus 1: d[i,j-1] + 1.
        --c. The cell diagonally above and to the left plus the cost: d[i-1,j-1] + cost 
		Cost=case when (substring(SourceString,ii,1)) = (substring(TargetString,jj,1)) 
            then 0 else 1 END,--the cost
        -- If s[i] equals t[j], the cost is 0.
        -- If s[i] doesn't equal t[j], the cost is 1. 
        Above         =unicode(substring(Matrix, jj *  (SourceStringLength+1)+ii-1+1,1))+1,
        ToTheLeft     =unicode(substring(Matrix,(jj-1)*(SourceStringLength+1)+ii+1  ,1))+1,
        AboveAndToLeft=unicode(substring(Matrix,(jj-1)*(SourceStringLength+1)+ii-1+1,1))+cost,
        previous      =unicode(substring(Matrix,(jj-2)*(SourceStringLength+1)+ii-2+1,1))+cost
        -- now calculate the minimum value of the three
        if (Above < ToTheLeft) AND (Above < AboveAndToLeft) 
            select MinimumValueOfCells=Above
      else if (ToTheLeft < Above) AND (ToTheLeft < AboveAndToLeft)
            select MinimumValueOfCells=ToTheLeft
        else
            select MinimumValueOfCells=AboveAndToLeft
        IF (substring(SourceString,ii,1) = substring(TargetString,jj-1,1) 
              and substring(TargetString,jj,1) = substring(SourceString,ii-1,1))
            begin
			SELECT MinimumValueOfCells = 
			  CASE WHEN MinimumValueOfCells< previous 
				THEN MinimumValueOfCells ELSE previous END 
			  end  
			  --write it to the matrix
		SELECT Matrix=STUFF(Matrix,
                   jj*(SourceStringLength+1)+ii+1,1,
                   nchar(MinimumValueOfCells)),
           jj=jj+1
        END
    SET ii=ii+1
    END    
--Step 7 After iteration steps (3, 4, 5, 6) are complete, distance is found in cell d[n,m]
return unicode(substring(
   Matrix,SourceStringLength*(TargetStringLength+1)+TargetStringLength+1,1
   ))
end

--Social@Panther
--subroutine tests
--tps23

--Tests in this file will print errors upon failure
set serveroutput on;

declare
	ALL_ERRORS integer := 0;
	
	-- General usage tests that should always pass and will print errors if they do not
	function GENERAL_TEST
		return integer
	is
		TEST_ERRORS integer := 0;
		TEST_USERID VARCHAR2 (20);
		TEST_FRIEND_ID varchar2 (20);
		TEST_FRIEND_ID2 varchar2 (20);
		TEST_FRIEND_ID3 varchar2 (20);
		TEST_FRIENDSHIP SUBROUTINES.FRIENDSHIP_DEGREE;
		TEST_NAME VARCHAR2 (50) := 'SirAstral';
		TEST_PASSWORD VARCHAR2 (50);
		TEST_EMAIL VARCHAR2 (64) := 'astral@granseal.dom';
		TEST_DOB DATE := TO_DATE('01-OCT-1993');
		TEST_LOGGED_IN boolean;
		TEST_BOOL_RESULT boolean;
		TEST_LOGOUT_TIME timestamp;
	begin
		--CREATE_USER
		TEST_USERID := CREATE_USER(TEST_NAME, TEST_EMAIL, TEST_DOB);
		TEST_PASSWORD := TEST_USERID;
		
		TEST_FRIEND_ID := CREATE_USER(TEST_NAME, TEST_EMAIL, TEST_DOB);
		TEST_FRIEND_ID2 := CREATE_USER(TEST_NAME, TEST_EMAIL, TEST_DOB);
		TEST_FRIEND_ID3 := CREATE_USER(TEST_NAME, TEST_EMAIL, TEST_DOB);
		
		if TEST_USERID is null then
			dbms_output.put_line('Error: GENERAL_TEST Failed CREATE_USER(' || TEST_NAME || ', ' || TEST_EMAIL || ', ' || TEST_DOB || ')');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		
		--LOGIN
		TEST_LOGGED_IN := LOGIN(TEST_USERID, TEST_PASSWORD);
		
		if TEST_LOGGED_IN = false then
			dbms_output.put_line('Error: GENERAL_TEST Failed LOGIN(' || TEST_USERID || ', ' || TEST_PASSWORD || ')');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		
		--make friends with TEST_FRIEND_ID
		--INITIATE_FRIENDSHIP
		TEST_BOOL_RESULT := INITIATE_FRIENDSHIP(TEST_USERID, TEST_FRIEND_ID, 'Dead men tell no tales.');
		
		if TEST_BOOL_RESULT = false then
			dbms_output.put_line('Error: GENERAL_TEST Failed INITIATE_FRIENDSHIP(' || TEST_USERID || ', ' || TEST_FRIEND_ID || ', Dead men tell no tales.)');
			TEST_ERRORS := TEST_ERRORS + 1;
		else
			--CONFIRM_FRIENDSHIP
			TEST_BOOL_RESULT := CONFIRM_FRIENDSHIP(TEST_FRIEND_ID, TEST_USERID);
			if TEST_BOOL_RESULT = false then
				dbms_output.put_line('Error: GENERAL_TEST Failed CONFIRM_FRIENDSHIP(' || TEST_FRIEND_ID || ', ' || TEST_USERID || ')');
				TEST_ERRORS := TEST_ERRORS + 1;
			end if;
		end if;
		
		--THREE_DEGREES direct friendship
		TEST_FRIENDSHIP := THREE_DEGREES(TEST_USERID, TEST_FRIEND_ID);
		
		if TEST_FRIENDSHIP.USER1 is null then
			dbms_output.put_line('Error: GENERAL_TEST Failed THREE_DEGREES(' || TEST_USERID || ', ' || TEST_FRIEND_ID || ') for false negative on direct friendship');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		--THREE_DEGREES no relationship
		delete from FRIENDS where (USERID1 = TEST_USERID and USERID2 = TEST_FRIEND_ID);
		TEST_FRIENDSHIP := THREE_DEGREES(TEST_USERID, TEST_FRIEND_ID);
		
		if (TEST_FRIENDSHIP.USER1 is null) = false then
			dbms_output.put_line('Error: GENERAL_TEST Failed THREE_DEGREES(' || TEST_USERID || ', ' || TEST_FRIEND_ID || ') for false positive');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		--THREE_DEGREES common friend
		TEST_BOOL_RESULT := INITIATE_FRIENDSHIP(TEST_USERID, TEST_FRIEND_ID2, '...');
		TEST_BOOL_RESULT := CONFIRM_FRIENDSHIP(TEST_FRIEND_ID2, TEST_USERID);
		TEST_BOOL_RESULT := INITIATE_FRIENDSHIP(TEST_FRIEND_ID, TEST_FRIEND_ID2, '...');
		TEST_BOOL_RESULT := CONFIRM_FRIENDSHIP(TEST_FRIEND_ID2, TEST_FRIEND_ID);
		
		TEST_FRIENDSHIP := THREE_DEGREES(TEST_USERID, TEST_FRIEND_ID);
		
		--TODO! FIX THREE_DEGREES for 2nd degree friendship
		if ((TEST_FRIENDSHIP.USER1 is null) or (TEST_FRIENDSHIP.USER2 is null)) then
			dbms_output.put_line('Error: GENERAL_TEST Failed THREE_DEGREES(' || TEST_USERID || ', ' || TEST_FRIEND_ID || ') for false negative on 2nd degree friendship');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		--THREE_DEGREES friends are friends
		delete from FRIENDS where USERID1 = TEST_FRIEND_ID and USERID2 = TEST_FRIEND_ID2;
		TEST_BOOL_RESULT := INITIATE_FRIENDSHIP(TEST_FRIEND_ID, TEST_FRIEND_ID3, '...');
		TEST_BOOL_RESULT := CONFIRM_FRIENDSHIP(TEST_FRIEND_ID3, TEST_FRIEND_ID);
		TEST_BOOL_RESULT := INITIATE_FRIENDSHIP(TEST_FRIEND_ID2, TEST_FRIEND_ID3, '...');
		TEST_BOOL_RESULT := CONFIRM_FRIENDSHIP(TEST_FRIEND_ID3, TEST_FRIEND_ID2);
		
		TEST_FRIENDSHIP := THREE_DEGREES(TEST_USERID, TEST_FRIEND_ID);
		delete from FRIENDS where (USERID1 = TEST_FRIEND_ID or USERID2 = TEST_FRIEND_ID);
		delete from FRIENDS where (USERID1 = TEST_FRIEND_ID2 or USERID2 = TEST_FRIEND_ID2);
		delete from FRIENDS where (USERID1 = TEST_FRIEND_ID3 or USERID2 = TEST_FRIEND_ID3);
		
		--TODO! FIX THREE_DEGREES for 3rd degree friendship
		if ((TEST_FRIENDSHIP.USER1 is null) or (TEST_FRIENDSHIP.USER2 is null) or (TEST_FRIENDSHIP.USER1_FRIEND is null) or (TEST_FRIENDSHIP.USER2_FRIEND is null)) then
			dbms_output.put_line('Error: GENERAL_TEST Failed THREE_DEGREES(' || TEST_USERID || ', ' || TEST_FRIEND_ID || ') for false negative on 3rd degree friendship');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		--LOGOUT
		if TEST_LOGGED_IN = true then
			TEST_LOGOUT_TIME := LOG_OUT(TEST_USERID);
			
			if TEST_LOGOUT_TIME = NULL then
				dbms_output.put_line('Error: GENERAL_TEST Failed LOG_OUT(' || TEST_USERID || ')');
				TEST_ERRORS := TEST_ERRORS + 1;
			end if;
		end if;
		
		
		--DROP USER
		TEST_BOOL_RESULT := DROP_USER(TEST_USERID);
		
		if TEST_BOOL_RESULT = false then
			dbms_output.put_line('Error: GENERAL_TEST Failed DROP_USER(' || TEST_USERID || ')');
			TEST_ERRORS := TEST_ERRORS + 1;
		end if;
		
		return TEST_ERRORS;
	exception
		when others then
			raise;
	end;

--TODO: make REJECTION_TEST
	--Rejection tests that should always fail (prints errors if they succeed)
	function REJECTION_TEST
		return integer
	is
		TEST_ERRORS integer := 0;
	begin
		return 0;
	end;

begin
	savepoint PRETEST;
	
	ALL_ERRORS := ALL_ERRORS + GENERAL_TEST();
	ALL_ERRORS := ALL_ERRORS + REJECTION_TEST();
	
	--Print summary
	if ALL_ERRORS > 0 then
		dbms_output.put_line('Tests had '|| ALL_ERRORS ||' error(s)!!');
	else
		dbms_output.put_line('All tests passed with no errors =)');
	end if;
	
	rollback to PRETEST;
end;
/

-- Social@Panther
-- tps23
-- Subroutines

create or replace package SUBROUTINES AS
	type FRIENDSHIP_DEGREE is record (
		USER1 varchar2(20) default null,
		USER1_FRIEND varchar2(20) default null,
		USER2 varchar2(20) default null,
		USER2_FRIEND varchar2(20) default null
	);
	
end SUBROUTINES;
/

-- Given a name, email address, and date of birth, add a new user to the system by inserting as new entry in the profile relation.
create or replace function
CREATE_USER(USERNAME IN varchar2, USER_EMAIL IN varchar2, USER_DATE_OF_BIRTH IN date)
	return varchar2
IS
	ENTRY_ID integer := -1;
	USER_PASSWORD varchar2 (50);
	USER_ID varchar2 (20);
begin
	select COUNT(USERID) INTO ENTRY_ID FROM PROFILE;
	ENTRY_ID := ENTRY_ID + 1;
	USER_ID := USERNAME || ENTRY_ID;
	USER_PASSWORD := USER_ID;
	
	INSERT INTO PROFILE(USERID, NAME, EMAIL, PASSWORD, DATE_OF_BIRTH)
		VALUES(USER_ID, USERNAME, USER_EMAIL, USER_PASSWORD, USER_DATE_OF_BIRTH);
	
	return USER_ID;
exception
	when OTHERS then
		return null;
END CREATE_USER;
/


-- Given userID and password, login as the user in the system when an appropriate match is found.
create or replace function
LOGIN(USER_ID IN varchar2, USER_PASSWORD IN varchar2)
	return integer
IS
	login_matches integer := 0;
begin
	select count(USERID) into login_matches from PROFILE
		where (USERID = USER_ID) and (PASSWORD = USER_PASSWORD);
	
	return login_matches;
END LOGIN;
/


-- This option should cleanly shut down and exit the program after marking the time of the user's logout in the profile relation
create or replace function
LOG_OUT(USER_ID in varchar2)
	return timestamp
IS
	UPDATED timestamp;
begin
	update PROFILE
		set LASTLOGIN = CURRENT_TIMESTAMP
		where USERID = USER_ID;
	
	select LASTLOGIN into UPDATED from PROFILE where USERID = USER_ID;
	
	return UPDATED;
END LOG_OUT;
/


-- Remove a user and all of their information from the system.
-- When a user is removed, the system should delete the user from the groups he or she was a member of using a trigger.
-- Note: messages require special handling because they are owned by both sender and receiver.
-- Therefore, a message is deleted only when both he sender and all receivers are deleted.
-- Attention should be paid handling integrity constraints.
create or replace function
DROP_USER(USER_ID in varchar2)
	return integer
IS
begin
	delete from PROFILE where USERID = USER_ID;
	--write trigger to handle all information owned solely by user on delete
	
	return 1;
exception
	when others then
		return 0;
END DROP_USER;
/


-- Given two users (A and B), find a path, if one exists, between A and B with at most 3 hop between them. A hop is defined as a friendship between any two users.
create or replace function
THREE_DEGREES(USER_A in varchar2, USER_B in varchar2)
	return SUBROUTINES.FRIENDSHIP_DEGREE
IS
	FRIENDSHIP SUBROUTINES.FRIENDSHIP_DEGREE;
	RELATION_FOUND integer := 1;
begin
	begin
		--Check Direct Friendship
		select USERID1, USERID2 into FRIENDSHIP.USER1, FRIENDSHIP.USER2 from FRIENDS
			where (USERID1 = USER_A and USERID2 = USER_B) or (USERID1 = USER_B and USERID2 = USER_A);
	exception
		when NO_DATA_FOUND then
			FRIENDSHIP.USER1 := null;
	end;
	
	if (FRIENDSHIP.USER1 is null) = false then
		return FRIENDSHIP;
	end if;
	
	/*
	begin
		--TODO! This is broken and doesn't work.
		--Search for Friend-in-common
		select * into RELATIONSHIP
			from
				((select USER from FRIENDS where (USERID1 = USER_A or USERID2 = USER_A) as A_FRIENDS)
				inner join
				(select * from FRIENDS where (USERID1 = USER_B or USERID2 = USER_B) as B_FRIENDS)
					on A_FRIENDS.USERID2 = B_FRIENDS.USERID2);
	exception
		when NO_DATA_FOUND then
			RELATION_FOUND := false;
	end;
	
	if RELATION_FOUND then
		FRIENDSHIP.USER1 := USER_A;
		FRIENDSHIP.USER2 := USER_B;
		FRIENDSHIP.USER1_FRIEND := ...;
		
		return FRIENDSHIP;
	end if;
	*/
	
	--Search for Friends who are Friends with Friend's Friends
	
	
	return FRIENDSHIP;
END THREE_DEGREES;
/


/* --------------------------------------- */
/* THIS STUFF NEEDS TO BE IN THE JAVA APP! */
/* --------------------------------------- */

-- Create a pending friendship from the (logged in) user to another user based on userID.
-- The application should display the name of the person that will be sent a friends request and the user should be prompted to enter a message to be sent along with the request.
-- A last confirmation should be requested of the user before an entry is inserted into the pendingFriends relation, and success or failure feedback is displayed for the user.
create or replace function
INITIATE_FRIENDSHIP(SENDER in varchar2, RECEIVER in varchar2, MESSAGE in varchar2)
	return integer
IS
	FRIENDSHIP varchar2(20);
	SUCCESS integer := 0;
begin
	savepoint PRE_BEFRIEND;
	
	begin
		--cannot send request when requester already sent to sender
		select TOID into FRIENDSHIP from PENDING_FRIENDS where (TOID = SENDER and FROMID = RECEIVER);
	exception
		when NO_DATA_FOUND then
		FRIENDSHIP := null;
	end;
	
	if (FRIENDSHIP is null) = false then
		return 0;
	end if;
	
	begin
		insert into PENDING_FRIENDS(FROMID, TOID, MESSAGE) values (SENDER, RECEIVER, MESSAGE);
		SUCCESS := 1;
	exception
		when OTHERS then
			rollback to PRE_BEFRIEND;
	end;
	
	return success;
END INITIATE_FRIENDSHIP;
/


-- This task should first display a formatted, numbered list of all outstanding friends and group requests with an associated messages.
-- Then, the user should be prompted for a number of the request he or she would like to confirm or given the option to confirm them all.
-- The application should move the request from the appropriate pendingFriends or pendingGroupmembers relation to the friends or groupMembership relation.
-- The remaining requests which were not selected are declined and removed from pendingFriends and pendingGroupmembers relations.
create or replace function
CONFIRM_FRIENDSHIP(USERID in varchar2, REQUESTER in varchar2)
	return integer
IS
	REQUEST_MESSAGE varchar2(200);
	CONFIRMED integer := 0;
begin
	savepoint PRECONFIRM;
	
	begin
		select MESSAGE into REQUEST_MESSAGE from PENDING_FRIENDS where (FROMID = REQUESTER and TOID = USERID);
		insert into FRIENDS(USERID1, USERID2, JDATE, MESSAGE) values(REQUESTER, USERID, CURRENT_DATE, REQUEST_MESSAGE);
		delete from PENDING_FRIENDS where fromID = REQUESTER and TOID = USERID;
		
		CONFIRMED := 1;
	exception
		when OTHERS then
			rollback to PRECONFIRM;
	end;
	
	return CONFIRMED;
END CONFIRM_FRIENDSHIP;
/


-- This task supports the browsing of the user's friends and of their friends' profiles.
-- It first displays each of the user's friends' names and userIDs and those of any friend of those friends.
-- Then it allows the user to either retrieve a friend's entire profile by entering the appropriate userID or exit browsing and return to the main menu by entering 0 as a userID.
-- When selected, a friend's profile should be displayed in a nicely formatted way,
-- after which the user should be prompted to either select to retrieve another friend's profile or return to the main menu.
create or replace procedure
DISPLAY_FRIENDS
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END DISPLAY_FRIENDS;
/


-- Given a name, description, and membership limit, add a new group to the system, add the user as its first member with the role manager.
create or replace procedure
CREATE_GROUP(NAME IN varchar2, DESCRIPTION IN varchar2, MEMBER_LIMIT IN integer)
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END CREATE_GROUP;
/


-- Given a user and a group, create a pending request of adding to group (if not violate the group's membership limit).
-- The user should be prompted to enter a message to be sent along with the request and inserted in the pendingGroupmembers relation.
create or replace procedure
INITIATE_ADDING_GROUP(USER_ID IN varchar2, GROUP_ID IN varchar2)
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END INITIATE_ADDING_GROUP;
/


-- With this the user can send a message to one friend given his userID.
-- The application should display the name of the recipient and the user should be prompted to enter the text of the message, which could be multi-lined.
-- Once entered, the message should be \sent" to the user by adding appropriate entries into the messages and message Recipients relations by creating a trigger.
-- The user should lastly be shown success or failure feedback.
create or replace procedure
SEND_MESSAGE_TO_USER(FRIEND_ID IN varchar2)
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END SEND_MESSAGE_TO_USER;
/


-- With this the user can send a message to a recipient group, if the user is within the group.
-- Every member of this group should receive the message.
-- The user should be prompted to enter the text of the message, which could be multi-lined.
-- Then the created new message should be \sent" to the user by adding appropriate entries into the messages and messageRecipients relations by creating a trigger.
-- The user should lastly be shown success or failure feedback.
-- Note that if the user sends a message to one friend, you only need to put the friend's userID to ToUserID in the table of messages.
-- If the user wants to send a message to a group, you need to put the group ID to ToGroupID in the table of messages
-- and use a trigger to populate the messageRecipient table with proper user ID information as defined by the groupMembership relation.
create or replace procedure
SEND_MESSAGE_TO_GROUP(GROUP_ID IN varchar2, MESSAGE IN varchar2)
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END SEND_MESSAGE_TO_GROUP;
/


-- When the user selects this option, the entire contents of every message sent to the user should be displayed in a nicely formatted way.
create or replace procedure
DISPLAY_MESSAGES
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END DISPLAY_MESSAGES;
/


-- This should display messages in the same fashion as the previous task except that only those messages sent since the last time the user logged into the system should be displayed.
create or replace procedure
DISPLAY_NEW_MESSAGES
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END DISPLAY_NEW_MESSAGES;
/


-- Given a string on which to match any user in the system, any item in this string must be matched against any significant field of a user's profile.
-- That is if the user searches for \xyz abc", the results should be the set of all profiles that match \xyz" union the set of all profiles that matches \abc"
create or replace procedure
SEARCH_FOR_USER(SEARCH_STRING IN varchar2)
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	--select * FROM PROFILE where ;
	
	dbms_output.put_line(OUTPUT_STRING);
END SEARCH_FOR_USER;
/


-- Display top K who have sent to or received the highest number of messages during for the past x months. x and K are input parameters to this function.
create or replace procedure
TOP_MESSAGES
IS
	OUTPUT_STRING varchar2 (255) := 'IMPLEMENT ME!';
begin
	dbms_output.put_line(OUTPUT_STRING);
END TOP_MESSAGES;
/

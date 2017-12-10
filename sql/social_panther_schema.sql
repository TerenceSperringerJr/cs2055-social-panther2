--Social@Panther
--Terence Sperringer (tps23)
--Sizhe Sun (sis61)

--Schema for Social@Panther

---DROP ALL TABLES TO MAKE SURE THE SCHEMA IS CLEAR
DROP TABLE PROFILE CASCADE CONSTRAINTS;
DROP TABLE FRIENDS CASCADE CONSTRAINTS;
DROP TABLE PENDING_FRIENDS CASCADE CONSTRAINTS;
DROP TABLE MESSAGES CASCADE CONSTRAINTS;
DROP TABLE MESSAGE_RECIPIENT CASCADE CONSTRAINTS;
DROP TABLE GROUPS CASCADE CONSTRAINTS;
DROP TABLE GROUP_MEMBERSHIP CASCADE CONSTRAINTS;
DROP TABLE PENDING_GROUP_MEMBERS CASCADE CONSTRAINTS;

--profile (userID, name, email, password, date_of_birth, lastlogin)
--Stores the profile and login information for each user registered in the system.
CREATE TABLE PROFILE(
	userID        varchar2(20) NOT NULL,
	name          varchar2(50) NOT NULL,
	email         varchar2(64),
	password      varchar2(50) NOT NULL,
	date_of_birth date,
	lastlogin     timestamp,
		CONSTRAINT PROFILE_PK PRIMARY KEY (userID) INITIALLY IMMEDIATE DEFERRABLE
);
/*
notes: lastlogin will be updated by LOG_OUT()
	on delete should cause a trigger to help maintain things under multiple ownership
*/


--friends (userID1, userID2, JDate, message)
--Stores the friends lists for every user in the system. The JDate is when they became friends, and the message is the message of friend request.
CREATE TABLE FRIENDS(
	userID1 varchar2(20) NOT NULL,
	userID2 varchar2(20) NOT NULL,
	JDate   date NOT NULL,
	message varchar2(200),
		CONSTRAINT FRIENDS_C CHECK(userID1<>userID2),
		CONSTRAINT FRIENDS_PK PRIMARY KEY(userID1,userID2) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT FRIENDS_FK1 FOREIGN KEY (userID1) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT FRIENDS_FK2 FOREIGN KEY (userID2) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE
);
/*
notes: JDate should get the current date after a FRIENDS entry is created
	On insert removes row from PENDING_FRIENDS that matches userID1 and userID2
*/


--pendingFriends (fromID, toID, message)
--Stores pending friends requests that have yet to be confirmed by the recipient of the request.
CREATE TABLE PENDING_FRIENDS(
	fromID  varchar2(20) NOT NULL,
	toID    varchar2(20) NOT NULL,
	message varchar2(200) DEFAULT 'I would like to befriend you.',
		CONSTRAINT PENDING_FRIENDS_PK PRIMARY KEY(fromID,toID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT PENDING_FRIENDS_FK1 FOREIGN KEY (fromID) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT PENDING_FRIENDS_FK2 FOREIGN KEY (toID) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE
);
--notes:


--groups (gID, name, description)
--Stores information for each group in the system.
CREATE TABLE GROUPS(
	gID         varchar2(20) NOT NULL,
	name        varchar2(50),
	description varchar2(200),
	member_limit integer,
		CONSTRAINT GROUPS_PK PRIMARY KEY (gID) INITIALLY IMMEDIATE DEFERRABLE
);
--notes: GROUPS are assumed to exist independently as it is possible for all members to leave them


--messages (msgID, fromID, message, toUserID, toGroupID, dateSent)
--Stores every message sent by users in the system. Note that the default values of ToUserID and ToGroupID should be NULL.
CREATE TABLE MESSAGES(
	msgID     varchar2(20) NOT NULL,
	fromID    varchar2(20) NOT NULL,
	message   varchar2(200),
	toUserID  varchar2(20) default NULL,
	toGroupID varchar2(20) default NULL,
	dateSent  date,
		CONSTRAINT MESSAGES_PK PRIMARY KEY (msgID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT MESSAGES_FK1 FOREIGN KEY (fromID) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT MESSAGES_FK2 FOREIGN KEY (toGroupID) REFERENCES GROUPS(gID) INITIALLY IMMEDIATE DEFERRABLE
);
--notes: TODO! create trigger so that either toUserID or toGroupID is populated after create
--CONSTRAINT CHECK(fromID <> toUserID),


--messageRecipient (msgID, userID)
--Stores the recipients of each message stored in the system.
CREATE TABLE MESSAGE_RECIPIENT(
	msgID  varchar2(20) NOT NULL,
	userID varchar2(20) NOT NULL,
		CONSTRAINT MESSAGE_RECIPIENT_PK PRIMARY KEY (msgID)  INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT MESSAGE_RECIPIENT_FK1 FOREIGN KEY (msgID) REFERENCES MESSAGES(msgID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT MESSAGE_RECIPIENT_FK2 FOREIGN KEY (userID) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE
);
--notes: 


--groupMembership (gID, userID, role)
--Stores the users who are members of each group in the system.The 'role' indicate whether a user is a manager of a group (who can accept joining group request) or not.
CREATE TABLE GROUP_MEMBERSHIP(
	gID    varchar2(20) NOT NULL,
	userID varchar2(20) NOT NULL,
	role   varchar2(20),
		CONSTRAINT GROUP_MEMBERSHIP_PK PRIMARY KEY (gID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT GROUP_MEMBERSHIP_FK1 FOREIGN KEY (userID) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE
);
--notes: TODO! The first member should have their role changed to manager.


--pendingGroupmembers (gID, userID, message)
--Stores pending joining group requests that have yet to be accept/reject by the manager of the group.
CREATE TABLE PENDING_GROUP_MEMBERS(
	gID     varchar2(20) NOT NULL,
	userID  varchar2(20) NOT NULL,
	message varchar2(200),
		CONSTRAINT PENDING_GROUP_MEMBERS_PK PRIMARY KEY(gID,userID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT PENDING_GROUP_MEMBERS_FK1 FOREIGN KEY (gID) REFERENCES GROUPS(gID) INITIALLY IMMEDIATE DEFERRABLE,
		CONSTRAINT PENDING_GROUP_MEMBERS_FK2 FOREIGN KEY (userID) REFERENCES PROFILE(userID) INITIALLY IMMEDIATE DEFERRABLE
);
--notes: 


--TRIGGERS

--TODO! create trigger before insert on pending_friends to reject insert when pending_friend already sent request to sender

--TODO! create trigger after insert on friends to remove row from pending_friends that matches userID1 and userID2
/*
create or replace trigger BEFRIEND
	after insert on FRIENDS referencing NEW as NEW_FRIENDSHIP
	for each ROW
		when(NEW_FRIENDSHIP.USERID1 = ROW.USERID1)
begin
	delete from PENDING_FRIENDS where (FROMID = :NEW_FRIENDSHIP.USERID1 and TOID = :NEW_FRIENDSHIP.USERID2);
end;
*/
/

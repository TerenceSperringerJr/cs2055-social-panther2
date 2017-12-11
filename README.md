# cs2055-social-panther2 #
CS 2055 Project: A New & Improved Social Networking System for the University of Pittsburgh

old groupID = 22

Now it's just me: tps23

## Instructions: ##
1. Add `config.txt` into java directory

	a. add the following to `config.txt` (no brackets):

		name: (pitt ID)
		pass: (database password)


2. Run `'source /afs/.../1555/bash.env.unixs'` to set the appropriate environment variables
3. Run `@reset_all_data.sql` in `sqlplus` to generate tables and populate with generated data
4. Run `@subroutines.sql` to create the pl/sql functions & procedures used by the test and client
5. Run `@subroutine_tests.sql` to test the functions/procedures currently implemented
6. Run `javac SocialPantherClient.java`
7. Run `java SocialPantherClient`

The schema, subroutines, data insertion, and subroutine testing scripts are located in sql.
The java client, SocialPantherClient is located in java.

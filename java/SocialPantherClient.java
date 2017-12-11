/*
Social@Panther
tps23
*/

/*
	Here is an example of connecting to a database using jdbc

	The table we will use in the example is
	Table Test(
		 name	 varchar(30),
		 ssn		number(10),
		 bday	 date
	);
	
	For demostratration purpose, insert two records into this table:
	( 'Mike', 123456789, '09/Nov/03' )
	( 'Amy', 987654321, '10/Nov/03' )

	Written by: Jonathan Beaver, modified by Thao Pham
	Purpose: Demo JDBC for CS1555 Class

	IMPORTANT (otherwise, your code may not compile)	
	Same as using sqlplus, you need to set oracle environment variables by 
	sourcing bash.env or tcsh.env
*/

import java.io.Console;

import java.io.FileReader; //for File IO
import java.io.FileNotFoundException;
import java.io.IOException;

//import the files containing definitions for the parts needed by java for database connection and manipulation
import java.sql.*;
import oracle.jdbc.*;

public class SocialPantherClient {
	private Connection connection; //used to hold the jdbc connection to the DB
	private Statement statement; //used to create an instance of the connection
	private ResultSet resultSet; //used to hold the result of your query (if one exists)
	private String query; //this will hold the query we are using
	private String clientLoginName;
	private String clientPassword;
	private String userID;
	private boolean loggedIn;
	private int appState;
	private Console console;
	
	public SocialPantherClient() {
		clientLoginName = "pitt01"; //This is your clientLoginName in oracle
		clientPassword = "clientPassword"; //This is your clientPassword in oracle
		
		//Read the login information from config.txt
		readConfig();
		openConnection();
		console = System.console();
		
		return;
	}
	
	private void demoTest() {
		int counter = 1;
		// We will now perform a simple query to the database, asking it for all the records it has.
		// For your project, performing queries will be similar
		try {
			statement = connection.createStatement(); //create an instance
			query = "SELECT * FROM Test"; //sample query one
			
			resultSet = statement.executeQuery(query); //run the query on the DB table
			// the results in resultSet have an odd quality. The first row in result
			// set is not relevant data, but rather a place holder. This enables us to
			// use a while loop to go through all the records. We must move the pointer
			// forward once using resultSet.next() or you will get errors
			
			while(resultSet.next()) //this not only keeps track of if another record exists but moves us forward to the first record
			{
				// since the first item was of type string, we use getString of the resultSet class to access it.
				// Notice the one, that is the position of the answer in the resulting table since second item was number(10),
				// we use getLong to access it since type date, getDate.
				System.out.println("Record " + counter + ": " +
					resultSet.getString(1) + ", " +
					resultSet.getLong(2) + ", " +
					resultSet.getDate(3));
				counter++;
			}
			
			// Now, we show an insert, using preparedStatement.
			// Of course for this you can also write the query directly as the above case with select,
			// and vice versa.
			
			String name = "tester 2";
			long ssn = 111111113;
			
			java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("yyyy-MM-dd");
			java.sql.Date bday = new java.sql.Date (df.parse("1990-01-20").getTime());
			query = "insert into Test values (?,?,?)";
			
			PreparedStatement updateStatement = connection.prepareStatement(query);
			updateStatement.setString(1, name);
			updateStatement.setLong(2,ssn);
			updateStatement.setDate(3,bday);
			updateStatement.executeUpdate();
			
			// We can also so the insert statement directly as follows:
			// query = "INSERT INTO Test VALUES ('Tester', 111111112, '1/Nov/03')";
			// int result = statement.executeUpdate(query); //executing update returns
			// either the row count for INSERT, UPDATE or DELETE or 0
			// for SQL statements that return nothing
			
			//I will show the insert worked by selecting the content of the table again
			//statement = connection.createStatement();
			query = "SELECT * FROM Test";
			resultSet = statement.executeQuery(query);
			System.out.println("\nAfter the insert, data is...\n");
			counter=1;
			
			while(resultSet.next())
			{
				System.out.println("Record " + counter + ": " +
					resultSet.getString(1) + ", " +
					resultSet.getLong(2) + ", " +
					resultSet.getDate(3));
				counter ++;
			}
			connection.close();
		}
		catch(Exception Ex) {
			System.out.println("Error running the sample queries.	Machine Error: " + Ex.toString());
		}
		
		System.out.println("Good Luck");
		
		return;
	}
	
	private void createUser() {
		String name;
		String email;
		String dateOfBirth;
		String jobQuery = "begin ? := CREATE_USER(?, ?, TO_DATE(?)); end;";
		String userID;
		
		try {
			CallableStatement callStatement = connection.prepareCall(jobQuery);
			
			System.out.println("Please enter the following: ");
			System.out.print("Name: ");
			name = console.readLine();
			System.out.print("Email: ");
			email = console.readLine();
			System.out.print("Date of Birth (DD-MON-YYYY, ie 31-DEC-1999): ");
			dateOfBirth = console.readLine();
			
			System.out.println("\nRegistering account...");
			
			callStatement.registerOutParameter(1, Types.CHAR);
			callStatement.setString(2, name);
			callStatement.setString(3, email);
			callStatement.setString(4, dateOfBirth);
			callStatement.execute();
			userID = callStatement.getString(1);
			callStatement.close();
			
			System.out.println("Created acount. User ID is " + userID);
			System.out.println("Please login with your new ID.");
		}
		catch(SQLException exception) {
			while(exception != null) {
				System.out.println("Error[" + exception.getErrorCode() + "]: " + exception.getSQLState());
				System.out.println(exception);
				exception = exception.getNextException();
			}
		}
		
		return;
	}
	
	private void login() {
		String userPassword;
		String jobQuery = "begin ? := LOGIN(?, ?); end;";
		
		try {
			CallableStatement callStatement = connection.prepareCall(jobQuery);
			
			System.out.println("Please enter the following: ");
			System.out.print("User ID: ");
			userID = console.readLine();
			System.out.print("Password: ");
			userPassword = new String(console.readPassword());
			
			System.out.println("\nLogging in...");
			
			callStatement.registerOutParameter(1, Types.INTEGER);
			callStatement.setString(2, userID);
			callStatement.setString(3, userPassword);
			callStatement.execute();
			
			loggedIn = (callStatement.getInt(1) == 1);
			callStatement.close();
			
			if(!loggedIn) {
				System.out.println("User ID & Password do not match any accounts. Access DENIED.");
			}
		}
		catch(SQLException exception) {
			while(exception != null) {
				System.out.println("Error[" + exception.getErrorCode() + "]: " + exception.getSQLState());
				System.out.println(exception);
				exception = exception.getNextException();
			}
		}
		
		return;
	}
	
	private void logout() {
		Timestamp timestamp;
		String jobQuery = "begin ? := LOG_OUT(?); end;";
		
		try {
			CallableStatement callStatement = connection.prepareCall(jobQuery);
			
			System.out.println("\nLogging out...");
			
			callStatement.registerOutParameter(1, Types.TIMESTAMP);
			callStatement.setString(2, userID);
			callStatement.execute();
			timestamp = callStatement.getTimestamp(1);
			callStatement.close();
			
			if(timestamp != null) {
				System.out.println("Logged out @" + timestamp);
				loggedIn = false;
			}
		}
		catch(SQLException exception) {
			while(exception != null) {
				System.out.println("Error[" + exception.getErrorCode() + "]: " + exception.getSQLState());
				System.out.println(exception);
				exception = exception.getNextException();
			}
		}
		
		return;
	}
	
	private void welcomeScreen() {
		String command = "";
		
		System.out.println("Welcome to Social@Panther, the hip, new social app for Pitt.");
		System.out.println("Please enter a number from the following list to perform the corresponding operation:");
		System.out.println("[1] Create new account");
		System.out.println("[2] Login");
		System.out.println("[3] Quit\n");
		System.out.print("@ ");
		
		command = console.readLine();
		
		if(command.contentEquals("1")) {
			createUser();
		}
		else if(command.contentEquals("2")) {
			login();
		}
		else if(command.contentEquals("3")) {
			appState= -1;
		}
		
		return;
	}
	
	private void profileScreen() {
		String command = "";
		
		System.out.println("\nWelcome back, " + userID);
		System.out.println("Please enter a number from the following list to perform the corresponding operation:");
		System.out.println("[1] ...");
		System.out.println("[2] ...");
		System.out.println("[3] Logout\n");
		System.out.print("@ ");
		
		command = console.readLine();
		
		if(command.contentEquals("1")) {
			//todo
		}
		else if(command.contentEquals("2")) {
			//todo
		}
		else if(command.contentEquals("3")) {
			logout();
		}
		
		return;
	}
	
	private void openConnection() {
		/*
		Making a connection to a DB causes certain exceptions.
		In order to handle these you either put the DB stuff in a try block,
		or have your function throw the Execptions and handle them later.
		For this app I will use the try blocks
		*/
		
		try {
			System.out.println("Connecting to the database...");
			
			//Register the oracle driver. This needs the oracle files provided
			//in the oracle.zip file, unzipped into the local directory and 
			//the class path set to include the local directory
			DriverManager.registerDriver (new oracle.jdbc.driver.OracleDriver());
			//This is the location of the database.	This is the database in oracle
			//provided to the class
			String url = "jdbc:oracle:thin:@class3.cs.pitt.edu:1521:dbclass"; 
			
			connection = DriverManager.getConnection(url, clientLoginName, clientPassword); 
			//create a connection to DB on class3.cs.pitt.edu
		}
		catch(Exception Ex) //What to do with any exceptions
		{
			System.out.println("Error connecting to database.	Machine Error: " +
				Ex.toString());
			Ex.printStackTrace();
		}
		
		return;
	}
	
	private void closeConnection() {
		try {
			connection.close();
		}
		catch(Exception ex) {
			System.out.println("Error running the sample queries.	Machine Error: " + ex.toString());
		}
		
		return;
	}
	
	/* Read login variables from config.txt */
	private void readConfig() {
		FileReader reader = null;
		String line = "";
		char ch;
		
		try {
			System.out.println("Reading config.txt...");
			
			//open config.txt
			reader = new FileReader("config.txt");
		}
		catch (FileNotFoundException x) {
			System.err.format("FileNotFoundException: %s%n", x);
		}
		
		try {
			//read the first line into this.clientLoginName;
			while((ch = ((char)reader.read())) != '\n') {
				line += ch;
			}
			
			this.clientLoginName = line.substring(6).trim();
			
			//read the second line into this.clientPassword;
			line = "";
			while((ch = ((char)reader.read())) != '\n') {
				line += ch;
			}
			clientPassword = line.substring(6).trim();
			
			//close config.txt
			reader.close();
		}
		catch(IOException x) {
			System.err.format("IOException: %s%n", x);
		}
		
		return;
	}
	
	public void runClient() {
		appState = 0;
		boolean runApp = true;
		
		while(runApp) {
			if(!loggedIn) {
				switch(appState) {
					case 0:
						welcomeScreen();
					break;
					
					default:
						runApp = false;
					break;
				}
			}
			else {
				switch(appState) {
					case 0:
						profileScreen();
					break;
					
					default:
					break;
				}
			}
		}
		
		closeConnection();
		
		return;
	}
	
	public static void main(String args[]) {
		SocialPantherClient socialPantherClient = new SocialPantherClient();
		
		socialPantherClient.runClient();
		
		return;
	}
}

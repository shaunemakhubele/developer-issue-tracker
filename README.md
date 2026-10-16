
@'
# Developer Issue Tracker

A Java web application for tracking software development issues, bugs, and tasks. Built with Spring Boot, Thymeleaf, Spring Data JPA, and PostgreSQL.

## Features

- Create, view, edit, and delete issues
- Search issues by title, description, and assignee
- Filter issues by status and priority
- Assign issues to developers
- Validate required fields and input lengths
- Display a dedicated not-found page for missing issues
- Persist issue data in PostgreSQL
- Responsive HTML interface

## Technology Stack

- Java 21
- Spring Boot 4.0.8
- Maven
- Spring MVC
- Thymeleaf
- Spring Data JPA / Hibernate
- PostgreSQL
- Jakarta Bean Validation
- JUnit and Spring MockMvc

## Requirements

- Java Development Kit (JDK) 21
- PostgreSQL
- Git (optional, for cloning the repository)

## Getting Started

### 1. Clone the repository

```powershell
git clone https://github.com/shaunemakhubele/developer-issue-tracker.git
cd developer-issue-tracker
```

### 2. Create the database

Using pgAdmin or the PostgreSQL command line, create a database named:

`issue_tracker`

The application is configured to connect to PostgreSQL on `localhost:5432` using the `postgres` username by default.

### 3. Configure the database password

In PowerShell, set the environment variable to your own PostgreSQL password:

```powershell
$env:DB_PASSWORD = "YOUR_POSTGRES_PASSWORD"
```

Replace the placeholder with your actual local password. Do not commit passwords or other secrets to Git.

### 4. Run the tests

Ensure PostgreSQL is running and the database credentials are configured in the current terminal.

```powershell
.\mvnw.cmd clean test
```

### 5. Start the application

```powershell
.\mvnw.cmd spring-boot:run
```

Open the application in your browser:

http://localhost:8080

## Testing

The automated test suite currently covers:

- Application context startup
- Dashboard rendering
- New issue form rendering
- Validation of blank titles and descriptions
- Handling of requests for missing issues

The current verified test run completed with **5 tests passed, 0 failures, and 0 errors**.

## Configuration

Database connection settings are stored in `src/main/resources/application.properties`. The database password is read from the `DB_PASSWORD` environment variable rather than being stored in the repository.

The application uses Hibernate schema updates during development. For production deployments, use a deliberate database migration strategy and review schema changes before applying them.

## Project Structure

```text
developer-issue-tracker/
├── src/
│   ├── main/
│   │   ├── java/com/shaune/developer_issue_tracker/
│   │   │   ├── controller/
│   │   │   ├── model/
│   │   │   ├── repository/
│   │   │   └── service/
│   │   └── resources/
│   │       ├── templates/
│   │       └── application.properties
│   └── test/
├── .gitignore
├── pom.xml
├── mvnw
└── mvnw.cmd
```

## Future Improvements

- Add pagination and configurable sorting
- Add user authentication and role-based access
- Expand automated CRUD and repository tests
- Add issue comments, deadlines, and activity history
- Add screenshots and a deployment guide

## Author

Shaune Makhubele

GitHub: https://github.com/shaunemakhubele
'@ | Set-Content README.md -Encoding utf8

git add README.md
git diff --cached --check
git commit -m "Add project README and setup instructions"
git push

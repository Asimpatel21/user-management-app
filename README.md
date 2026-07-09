# User Management (Spring Boot + Thymeleaf + MS SQL Server)

A simple CRUD web app: Create, Read, Update, Delete users, backed by SQL Server.

## 1. Set up the database (SSMS)
1. Open SSMS, connect to your SQL Server instance.
2. Open `sql/setup.sql` and execute it (F5). This creates the `UserManagementDB`
   database, a `users` table (with 2 sample rows), and an `accounts` table (for login/signup).

## 2. Configure the app
Open `src/main/resources/application.properties` and update:
```
spring.datasource.url=jdbc:sqlserver://<YOUR_SERVER>:1433;databaseName=UserManagementDB;encrypt=true;trustServerCertificate=true
spring.datasource.username=<YOUR_USERNAME>
spring.datasource.password=<YOUR_PASSWORD>
```
- If using a named instance (e.g. `localhost\SQLEXPRESS`), you may need to enable
  the SQL Server Browser service, or specify the port directly instead of the instance name.
- Make sure **TCP/IP** is enabled in SQL Server Configuration Manager, and that
  **SQL Server and Windows Authentication mode** is enabled if you're using a SQL login (not Windows auth).

## 3. Run the app
Requires Java 17+ and Maven.

```bash
mvn spring-boot:run
```

Then open: **http://localhost:8080**

## 4. What you can do
- **Sign up** for an account, choosing a role: **User** or **Admin** (`/signup`)
- **Log in** (`/login`)
- View all users (`/users`) -- only visible once logged in
- Add a new user (`/users/new`)
- Edit a user (`/users/edit/{id}`)
- Delete a user (`/users/delete/{id}`)
- **Admins only:** Bulk-upload users from a `.csv`, `.txt`, or `.xlsx` file (`/users/upload`)
- **Log out** (`/logout`)

Note: "accounts" (login credentials, with a role) are separate from "users" (the people being managed in the CRUD screens) -- two different tables, two different purposes.

### Bulk upload file format
Only Admin accounts see the "Bulk Upload" button. The uploaded file must have a header row, then rows with exactly these 4 columns in order:
```
fullName, email, phoneNumber, address
```
Example:
```
fullName,email,phoneNumber,address
Ravi Kumar,ravi.kumar@example.com,9998887777,Delhi India
Sneha Rao,sneha.rao@example.com,9112233445,Bengaluru India
```

## Project structure
```
usermanagement/
├── sql/setup.sql                     -> run in SSMS first
├── pom.xml                           -> Maven dependencies
├── src/main/resources/
│   ├── application.properties        -> DB connection config
│   └── templates/
│       ├── list-users.html           -> user table (Read)
│       └── user-form.html            -> add/edit form (Create/Update)
└── src/main/java/com/example/usermanagement/
    ├── UserManagementApplication.java -> app entry point
    ├── model/User.java                -> maps to "users" table
    ├── repository/UserRepository.java -> DB access (Spring Data JPA)
    ├── service/UserService.java       -> business logic
    └── controller/
        ├── UserController.java        -> handles /users routes
        └── HomeController.java        -> redirects / to /users
```

## How a request flows through the app
1. Browser hits a URL, e.g. `GET /users`
2. `UserController` receives it, calls `UserService`
3. `UserService` calls `UserRepository`, which runs the actual SQL against SQL Server
4. Controller puts the result into the `Model` and picks a template (e.g. `list-users.html`)
5. Thymeleaf renders that template into HTML, filling in `${...}` and `th:*` placeholders
6. Browser receives and displays the final HTML page

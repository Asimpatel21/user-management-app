package com.example.usermanagement;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * The entry point of the application.
 * @SpringBootApplication is shorthand for 3 annotations:
 *  - @Configuration: this class can define beans
 *  - @EnableAutoConfiguration: Spring Boot auto-configures the web server, JPA, etc.
 *  - @ComponentScan: Spring scans this package (and sub-packages) for @Controller, @Service, etc.
 */
@SpringBootApplication
public class UserManagementApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserManagementApplication.class, args);
    }
}

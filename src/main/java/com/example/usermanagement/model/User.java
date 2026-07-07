package com.example.usermanagement.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * This class represents ONE ROW in the "users" table.
 * @Entity tells Hibernate/JPA: "map this class to a database table."
 * Each field below = one column.
 */
@Entity
@Table(name = "users")
public class User {

    @Id // marks this field as the primary key
    @GeneratedValue(strategy = GenerationType.IDENTITY) // matches SQL Server's IDENTITY(1,1) auto-increment
    @Column(name = "id")
    private Long id;

    @NotBlank(message = "Full name is required")
    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;

    @NotBlank(message = "Email is required")
    @Email(message = "Enter a valid email address")
    @Column(name = "email", nullable = false, unique = true, length = 150)
    private String email;

    @Column(name = "phone_number", length = 20)
    private String phoneNumber;

    @Column(name = "address", length = 255)
    private String address;

    // ---- Constructors ----
    public User() {
        // JPA requires a no-argument constructor
    }

    public User(String fullName, String email, String phoneNumber, String address) {
        this.fullName = fullName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.address = address;
    }

    // ---- Getters and Setters ----
    // Spring/Thymeleaf/Hibernate all rely on these to read and write field values

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }
}

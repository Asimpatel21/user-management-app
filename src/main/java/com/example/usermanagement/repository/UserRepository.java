package com.example.usermanagement.repository;

import com.example.usermanagement.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * This interface gives us CRUD database operations for free -- no SQL needed.
 * By extending JpaRepository<User, Long>, Spring Data JPA automatically implements
 * methods like: save(), findAll(), findById(), deleteById(), etc. at runtime.
 *
 * <User, Long> means: this repository manages User entities, whose primary key (id) is a Long.
 */
public interface UserRepository extends JpaRepository<User, Long> {
    // You can add custom queries here later if needed, e.g.:
    // Optional<User> findByEmail(String email);
}

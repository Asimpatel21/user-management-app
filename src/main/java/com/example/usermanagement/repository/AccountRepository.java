package com.example.usermanagement.repository;

import com.example.usermanagement.model.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Long> {

    // Custom finder methods -- Spring Data JPA writes the SQL for these automatically
    // just from the method name (findByUsername -> "WHERE username = ?")
    Optional<Account> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}

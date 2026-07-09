package com.example.usermanagement.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * @Configuration classes are where we define "beans" -- reusable objects
 * that Spring creates once and hands out wherever they're needed (via @Autowired).
 *
 * Here we create ONE PasswordEncoder that the whole app shares, so signup and
 * login always use the exact same hashing method to create/check passwords.
 */
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt automatically adds random "salt" and is intentionally slow,
        // which makes it resistant to brute-force password-guessing attacks.
        return new BCryptPasswordEncoder();
    }
}

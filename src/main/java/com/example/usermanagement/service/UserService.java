package com.example.usermanagement.service;

import com.example.usermanagement.model.User;
import com.example.usermanagement.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * The Service layer holds "business logic" -- the rules of what the app does.
 * Controllers should NOT talk to the Repository directly; they go through the Service.
 * This keeps things organized: Controller (handles web requests) -> Service (logic) -> Repository (database).
 */
@Service
public class UserService {

    private final UserRepository userRepository;

    // Constructor injection: Spring automatically supplies a UserRepository instance here
    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // CREATE + UPDATE (JPA's save() does both: inserts if id is null, updates if id exists)
    public User saveUser(User user) {
        return userRepository.save(user);
    }

    // READ all users
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // READ one user by id (used when opening the "edit" form)
    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
    }

    // DELETE
    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
}

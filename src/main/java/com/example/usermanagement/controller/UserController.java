package com.example.usermanagement.controller;

import com.example.usermanagement.model.User;
import com.example.usermanagement.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

/**
 * @Controller (not @RestController) means these methods return the NAME of an HTML
 * template (Thymeleaf resolves it from src/main/resources/templates/) rather than raw JSON/text.
 */
@Controller
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    // ---------- READ (list all users) ----------
    // Visiting GET /users shows the table of all users
    @GetMapping
    public String listUsers(Model model) {
        model.addAttribute("users", userService.getAllUsers());
        return "list-users"; // renders templates/list-users.html
    }

    // ---------- CREATE (show empty form) ----------
    @GetMapping("/new")
    public String showCreateForm(Model model) {
        model.addAttribute("user", new User()); // empty object for the form to bind to
        return "user-form"; // renders templates/user-form.html
    }

    // ---------- CREATE (handle form submission) ----------
    @PostMapping
    public String saveUser(@Valid @ModelAttribute("user") User user,
                            BindingResult result) {
        // @Valid triggers the @NotBlank/@Email checks from User.java.
        // If any fail, BindingResult holds the errors and we re-show the form.
        if (result.hasErrors()) {
            return "user-form";
        }
        userService.saveUser(user);
        return "redirect:/users"; // after saving, redirect back to the list page
    }

    // ---------- UPDATE (show pre-filled form) ----------
    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable Long id, Model model) {
        model.addAttribute("user", userService.getUserById(id));
        return "user-form"; // same template as "create" -- it adapts based on whether id is null
    }

    // ---------- DELETE ----------
    @GetMapping("/delete/{id}")
    public String deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return "redirect:/users";
    }
}

package com.example.usermanagement.controller;

import com.example.usermanagement.model.Account;
import com.example.usermanagement.repository.AccountRepository;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

/**
 * Handles everything related to "who is using the app": signup, login, logout.
 *
 * We use HttpSession to remember that someone is logged in. Here's the idea:
 * - When a browser logs in successfully, we store their username in the session.
 * - The session is tied to a cookie the browser automatically sends with every
 *   request, so the server can recognize "oh, this is the same browser that logged in".
 * - Logging out just erases that session data.
 */
@Controller
public class AuthController {

    private final AccountRepository accountRepository;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    public AuthController(AccountRepository accountRepository, PasswordEncoder passwordEncoder) {
        this.accountRepository = accountRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // ---------- SIGNUP ----------

    @GetMapping("/signup")
    public String showSignupForm(Model model) {
        model.addAttribute("account", new Account());
        return "signup"; // renders templates/signup.html
    }

    @PostMapping("/signup")
    public String processSignup(@Valid @ModelAttribute("account") Account account,
                                 BindingResult result,
                                 Model model) {
        if (result.hasErrors()) {
            return "signup";
        }

        // Check for duplicates before saving
        if (accountRepository.existsByUsername(account.getUsername())) {
            model.addAttribute("error", "That username is already taken.");
            return "signup";
        }
        if (accountRepository.existsByEmail(account.getEmail())) {
            model.addAttribute("error", "That email is already registered.");
            return "signup";
        }

        // IMPORTANT: hash the password before saving -- never save the raw text
        account.setPassword(passwordEncoder.encode(account.getPassword()));
        accountRepository.save(account);

        // Send them to the login page with a success message
        return "redirect:/login?signupSuccess";
    }

    // ---------- LOGIN ----------

    @GetMapping("/login")
    public String showLoginForm() {
        return "login"; // renders templates/login.html
    }

    @PostMapping("/login")
    public String processLogin(@RequestParam String username,
                                @RequestParam String password,
                                HttpSession session,
                                Model model) {
        var accountOpt = accountRepository.findByUsername(username);

        // matches() compares the typed password (hashed on the fly) against the
        // stored hash -- this is how we verify a password without ever storing it in plain text
        if (accountOpt.isEmpty() || !passwordEncoder.matches(password, accountOpt.get().getPassword())) {
            model.addAttribute("error", "Invalid username or password.");
            return "login";
        }

        // Login successful: remember this user for future requests in this browser session
        session.setAttribute("loggedInUser", accountOpt.get().getUsername());
        return "redirect:/users";
    }

    // ---------- LOGOUT ----------

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate(); // wipes all session data -- effectively "forgets" this browser was logged in
        return "redirect:/login?loggedOut";
    }
}

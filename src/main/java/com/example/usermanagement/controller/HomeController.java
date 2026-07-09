package com.example.usermanagement.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Just a convenience: so visiting http://localhost:8080/ takes you straight
 * to the user list instead of showing a blank "Whitelabel Error Page".
 */
@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "redirect:/login";
    }
}

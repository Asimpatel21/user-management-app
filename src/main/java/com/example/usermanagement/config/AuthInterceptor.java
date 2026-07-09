package com.example.usermanagement.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * A "gatekeeper" that runs BEFORE every request to a protected page.
 * If there's no "loggedInUser" in the session, it redirects to /login instead
 * of letting the request through to the controller.
 */
public class AuthInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {

        Object loggedInUser = request.getSession().getAttribute("loggedInUser");

        if (loggedInUser == null) {
            response.sendRedirect("/login");
            return false; // stops the request here -- controller method never runs
        }

        return true; // logged in -- let the request continue as normal
    }
}

package com.example.usermanagement.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Registers our AuthInterceptor and tells it WHICH urls to guard.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new AuthInterceptor())
                .addPathPatterns("/users/**")       // protect everything under /users
                .excludePathPatterns("/login", "/signup", "/", "/css/**", "/js/**"); // but never block these
    }
}

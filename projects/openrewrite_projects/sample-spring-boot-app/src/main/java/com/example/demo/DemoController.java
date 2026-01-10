package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;

@RestController
public class DemoController {

    @GetMapping("/hello")
    public String hello(HttpServletRequest request) {
        String userAgent = request.getHeader("User-Agent");
        return "Hello from legacy Spring Boot! Your User-Agent is: " + userAgent;
    }
}

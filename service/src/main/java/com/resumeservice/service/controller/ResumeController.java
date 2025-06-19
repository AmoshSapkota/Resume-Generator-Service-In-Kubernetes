package com.resumeservice.service.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ResumeController {

    @GetMapping("/")
    public ResponseEntity<String> home() {
        return ResponseEntity.ok("Hello! Welcome to resume generator. This application is under development.");
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Application is healthy and running!");
    }

    @GetMapping("/api/resume")
    public ResponseEntity<String> getResume() {
        return ResponseEntity.ok("Resume service endpoint - Coming soon!");
    }
}

package com.resumeservice.service;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.http.ResponseEntity;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ResumeController {

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Resume Service");
        response.put("version", "1.0.0");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/resume")
    public ResponseEntity<Map<String, Object>> getResume() {
        Map<String, Object> resume = new HashMap<>();
        resume.put("name", "Sample Resume Service");
        resume.put("description", "A Spring Boot microservice for resume management");
        resume.put("technology", "Java Spring Boot");
        resume.put("features", new String[]{"REST API", "Health Checks", "Docker Support", "Kubernetes Ready"});
        return ResponseEntity.ok(resume);
    }

    @GetMapping("/")
    public ResponseEntity<Map<String, String>> root() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Welcome to Resume Service");
        response.put("endpoints", "/api/health, /api/resume");
        return ResponseEntity.ok(response);
    }
}

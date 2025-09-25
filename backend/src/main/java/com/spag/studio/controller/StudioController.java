package com.spag.studio.controller;

import com.spag.studio.dto.StudioResponse;
import com.spag.studio.model.Studio;
import com.spag.studio.service.StudioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*") // Allow Flutter app to access the API
public class StudioController {
    
    private final StudioService studioService;
    
    public StudioController(StudioService studioService) {
        this.studioService = studioService;
    }
    
    @GetMapping("/studios")
    public ResponseEntity<List<StudioResponse>> getAllStudios(
            @RequestParam(required = false) String location,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String search,
            @RequestParam(required = false, defaultValue = "false") boolean availableOnly) {
        
        // Use service method that handles all filters together for better performance
        List<StudioResponse> studios = studioService.getStudiosWithFilters(
            location, maxPrice, search, availableOnly);
        
        return ResponseEntity.ok(studios);
    }
    
    @GetMapping("/studios/{id}")
    public ResponseEntity<StudioResponse> getStudioById(@PathVariable Long id) {
        Optional<StudioResponse> studio = studioService.getStudioById(id);
        return studio.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping("/studios")
    public ResponseEntity<StudioResponse> createStudio(@Valid @RequestBody Studio studio) {
        StudioResponse createdStudio = studioService.createStudio(studio);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdStudio);
    }
    
    @PutMapping("/studios/{id}")
    public ResponseEntity<StudioResponse> updateStudio(@PathVariable Long id, 
                                                      @Valid @RequestBody Studio studioDetails) {
        Optional<StudioResponse> updatedStudio = studioService.updateStudio(id, studioDetails);
        return updatedStudio.map(ResponseEntity::ok)
                           .orElse(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/studios/{id}")
    public ResponseEntity<Void> deleteStudio(@PathVariable Long id) {
        boolean deleted = studioService.deleteStudio(id);
        return deleted ? ResponseEntity.noContent().build() 
                      : ResponseEntity.notFound().build();
    }
    
    // Health check endpoint
    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Studio API is running!");
    }
}

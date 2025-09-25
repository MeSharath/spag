package com.spag.studio.service;

import com.spag.studio.dto.StudioResponse;
import com.spag.studio.model.Studio;
import com.spag.studio.repository.StudioRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class StudioService {
    
    private final StudioRepository studioRepository;
    
    public StudioService(StudioRepository studioRepository) {
        this.studioRepository = studioRepository;
    }
    
    public List<StudioResponse> getAllStudios() {
        return studioRepository.findAll()
                .stream()
                .map(StudioResponse::new)
                .collect(Collectors.toList());
    }
    
    public List<StudioResponse> getAvailableStudios() {
        return studioRepository.findByIsAvailableTrue()
                .stream()
                .map(StudioResponse::new)
                .collect(Collectors.toList());
    }
    
    public Optional<StudioResponse> getStudioById(Long id) {
        return studioRepository.findById(id)
                .map(StudioResponse::new);
    }
    
    public List<StudioResponse> getStudiosByLocation(String location) {
        return studioRepository.findByLocationContainingIgnoreCase(location)
                .stream()
                .map(StudioResponse::new)
                .collect(Collectors.toList());
    }
    
    public List<StudioResponse> getStudiosByMaxPrice(Double maxPrice) {
        return studioRepository.findAvailableStudiosByMaxPrice(maxPrice)
                .stream()
                .map(StudioResponse::new)
                .collect(Collectors.toList());
    }
    
    public List<StudioResponse> searchStudios(String keyword) {
        return studioRepository.findByKeyword(keyword)
                .stream()
                .map(StudioResponse::new)
                .collect(Collectors.toList());
    }
    
    public List<StudioResponse> getStudiosWithFilters(String location, Double maxPrice, 
                                                     String search, boolean availableOnly) {
        List<Studio> studios;
        
        // Priority: search > location > maxPrice > availableOnly > all
        if (search != null && !search.trim().isEmpty()) {
            studios = studioRepository.findByKeyword(search.trim());
        } else if (location != null && !location.trim().isEmpty()) {
            studios = studioRepository.findByLocationContainingIgnoreCase(location.trim());
        } else if (maxPrice != null) {
            studios = studioRepository.findAvailableStudiosByMaxPrice(maxPrice);
        } else if (availableOnly) {
            studios = studioRepository.findByIsAvailableTrue();
        } else {
            studios = studioRepository.findAll();
        }
        
        return studios.stream()
                .map(StudioResponse::new)
                .collect(Collectors.toList());
    }
    
    public StudioResponse createStudio(Studio studio) {
        Studio savedStudio = studioRepository.save(studio);
        return new StudioResponse(savedStudio);
    }
    
    public Optional<StudioResponse> updateStudio(Long id, Studio studioDetails) {
        return studioRepository.findById(id)
                .map(studio -> {
                    studio.setName(studioDetails.getName());
                    studio.setDescription(studioDetails.getDescription());
                    studio.setLocation(studioDetails.getLocation());
                    studio.setPricePerHour(studioDetails.getPricePerHour());
                    studio.setImageUrl(studioDetails.getImageUrl());
                    studio.setContactEmail(studioDetails.getContactEmail());
                    studio.setContactPhone(studioDetails.getContactPhone());
                    studio.setIsAvailable(studioDetails.getIsAvailable());
                    
                    Studio updatedStudio = studioRepository.save(studio);
                    return new StudioResponse(updatedStudio);
                });
    }
    
    public boolean deleteStudio(Long id) {
        return studioRepository.findById(id)
                .map(studio -> {
                    studioRepository.delete(studio);
                    return true;
                })
                .orElse(false);
    }
}

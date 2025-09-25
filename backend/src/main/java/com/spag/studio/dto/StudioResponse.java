package com.spag.studio.dto;

import com.spag.studio.model.Studio;

import java.time.LocalDateTime;

public class StudioResponse {
    private Long id;
    private String name;
    private String description;
    private String location;
    private Double pricePerHour;
    private String imageUrl;
    private String contactEmail;
    private String contactPhone;
    private Boolean isAvailable;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Constructors
    public StudioResponse() {}
    
    public StudioResponse(Studio studio) {
        this.id = studio.getId();
        this.name = studio.getName();
        this.description = studio.getDescription();
        this.location = studio.getLocation();
        this.pricePerHour = studio.getPricePerHour();
        this.imageUrl = studio.getImageUrl();
        this.contactEmail = studio.getContactEmail();
        this.contactPhone = studio.getContactPhone();
        this.isAvailable = studio.getIsAvailable();
        this.createdAt = studio.getCreatedAt();
        this.updatedAt = studio.getUpdatedAt();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getLocation() {
        return location;
    }
    
    public void setLocation(String location) {
        this.location = location;
    }
    
    public Double getPricePerHour() {
        return pricePerHour;
    }
    
    public void setPricePerHour(Double pricePerHour) {
        this.pricePerHour = pricePerHour;
    }
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    
    public String getContactEmail() {
        return contactEmail;
    }
    
    public void setContactEmail(String contactEmail) {
        this.contactEmail = contactEmail;
    }
    
    public String getContactPhone() {
        return contactPhone;
    }
    
    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
    }
    
    public Boolean getIsAvailable() {
        return isAvailable;
    }
    
    public void setIsAvailable(Boolean isAvailable) {
        this.isAvailable = isAvailable;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}

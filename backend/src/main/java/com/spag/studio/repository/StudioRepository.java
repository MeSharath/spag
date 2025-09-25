package com.spag.studio.repository;

import com.spag.studio.model.Studio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudioRepository extends JpaRepository<Studio, Long> {
    
    List<Studio> findByIsAvailableTrue();
    
    List<Studio> findByLocationContainingIgnoreCase(String location);
    
    @Query("SELECT s FROM Studio s WHERE s.pricePerHour <= :maxPrice AND s.isAvailable = true")
    List<Studio> findAvailableStudiosByMaxPrice(Double maxPrice);
    
    @Query("SELECT s FROM Studio s WHERE LOWER(s.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "OR LOWER(s.description) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Studio> findByKeyword(String keyword);
}

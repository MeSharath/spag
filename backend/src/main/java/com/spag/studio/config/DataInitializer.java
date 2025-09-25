package com.spag.studio.config;

import com.spag.studio.model.Studio;
import com.spag.studio.repository.StudioRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class DataInitializer implements CommandLineRunner {
    
    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);
    private final StudioRepository studioRepository;
    
    public DataInitializer(StudioRepository studioRepository) {
        this.studioRepository = studioRepository;
    }
    
    @Override
    public void run(String... args) throws Exception {
        // Only initialize data if the database is empty
        if (studioRepository.count() == 0) {
            initializeSampleData();
        }
    }
    
    private void initializeSampleData() {
        Studio studio1 = new Studio(
            "Creative Sound Studio",
            "Professional recording studio with state-of-the-art equipment. Perfect for music production, podcasts, and voice-overs.",
            "Mumbai, Maharashtra",
            2500.0
        );
        studio1.setImageUrl("https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500");
        studio1.setContactEmail("info@creativesound.com");
        studio1.setContactPhone("+91-9876543210");
        
        Studio studio2 = new Studio(
            "Harmony Music Hub",
            "Spacious studio with excellent acoustics and professional mixing capabilities. Ideal for bands and solo artists.",
            "Bangalore, Karnataka",
            3000.0
        );
        studio2.setImageUrl("https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500");
        studio2.setContactEmail("contact@harmonymusic.com");
        studio2.setContactPhone("+91-9876543211");
        
        Studio studio3 = new Studio(
            "Digital Dreams Studio",
            "Modern digital recording facility with the latest software and hardware. Specializing in electronic music production.",
            "Delhi, NCR",
            2200.0
        );
        studio3.setImageUrl("https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=500");
        studio3.setContactEmail("hello@digitaldreams.com");
        studio3.setContactPhone("+91-9876543212");
        
        Studio studio4 = new Studio(
            "Acoustic Vibes Studio",
            "Intimate studio perfect for acoustic recordings and singer-songwriter sessions. Warm and cozy atmosphere.",
            "Chennai, Tamil Nadu",
            1800.0
        );
        studio4.setImageUrl("https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=500");
        studio4.setContactEmail("info@acousticvibes.com");
        studio4.setContactPhone("+91-9876543213");
        
        Studio studio5 = new Studio(
            "Pro Audio Labs",
            "High-end professional studio with Grammy-winning engineers. Full production services available.",
            "Pune, Maharashtra",
            4500.0
        );
        studio5.setImageUrl("https://images.unsplash.com/photo-1598653222000-6b7b7a552625?w=500");
        studio5.setContactEmail("bookings@proaudiolabs.com");
        studio5.setContactPhone("+91-9876543214");
        
        studioRepository.save(studio1);
        studioRepository.save(studio2);
        studioRepository.save(studio3);
        studioRepository.save(studio4);
        studioRepository.save(studio5);
        
        logger.info("Sample studio data initialized successfully! Created {} studios.", 5);
    }
}

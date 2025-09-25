# Security Policy

## Overview

The Studio Finder application takes security seriously. This document outlines our security practices, how to report vulnerabilities, and guidelines for secure usage.

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

### How to Report

1. **Email**: Send details to security@studio-finder.com
2. **Subject**: Include "SECURITY" in the subject line
3. **Details**: Provide as much information as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Status Updates**: Weekly until resolved
- **Resolution**: Critical issues within 30 days

### Responsible Disclosure

- Do not publicly disclose the vulnerability until we've had a chance to address it
- Do not access or modify data that doesn't belong to you
- Do not perform actions that could harm our systems or users

## Security Measures

### Backend Security

#### Authentication & Authorization
```java
// Future implementation - JWT-based authentication
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/health", "/api/studios").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/studios").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/studios/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/studios/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .build();
    }
}
```

#### Input Validation
```java
@Entity
@Table(name = "studios")
public class Studio {
    
    @NotBlank(message = "Studio name is required")
    @Size(max = 255, message = "Studio name must not exceed 255 characters")
    private String name;
    
    @NotBlank(message = "Description is required")
    @Size(max = 2000, message = "Description must not exceed 2000 characters")
    private String description;
    
    @Email(message = "Invalid email format")
    @Size(max = 255, message = "Email must not exceed 255 characters")
    private String contactEmail;
    
    @Pattern(regexp = "^\\+?[1-9]\\d{1,14}$", message = "Invalid phone number format")
    private String contactPhone;
}
```

#### SQL Injection Prevention
```java
// Using JPA/Hibernate with parameterized queries
@Repository
public interface StudioRepository extends JpaRepository<Studio, Long> {
    
    @Query("SELECT s FROM Studio s WHERE LOWER(s.name) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Studio> findByKeyword(@Param("keyword") String keyword);
    
    // Avoid raw SQL queries, use JPA methods instead
}
```

#### CORS Configuration
```java
@Configuration
public class CorsConfig {
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // Production: Restrict to specific domains
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "https://yourdomain.com",
            "https://*.yourdomain.com",
            "http://localhost:*" // Development only
        ));
        
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}
```

### Database Security

#### Connection Security
```yaml
# Use SSL connections in production
spring:
  datasource:
    url: jdbc:postgresql://db.xxx.supabase.co:5432/postgres?sslmode=require
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 10
      connection-timeout: 20000
      leak-detection-threshold: 60000
```

#### Row Level Security (RLS)
```sql
-- Enable RLS on studios table
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;

-- Policy for public read access
CREATE POLICY "Allow public read access" ON studios
    FOR SELECT USING (true);

-- Policy for authenticated users to modify
CREATE POLICY "Allow authenticated users to insert" ON studios
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow owners to update their studios" ON studios
    FOR UPDATE USING (auth.uid() = owner_id);
```

### Frontend Security

#### API Communication
```dart
class ApiService {
  static const String baseUrl = 'https://api.yourdomain.com';
  
  static Future<List<Studio>> getStudios() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/studios'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authentication header when implemented
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Validate response structure
        final jsonData = json.decode(response.body);
        if (jsonData is List) {
          return jsonData.map((json) => Studio.fromJson(json)).toList();
        } else {
          throw ApiException('Invalid response format', response.statusCode);
        }
      } else {
        throw ApiException('HTTP ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      // Log error securely (don't expose sensitive information)
      print('API Error: ${e.toString()}');
      rethrow;
    }
  }
}
```

#### Input Sanitization
```dart
class StudioValidator {
  static String? validateStudioName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Studio name is required';
    }
    if (value.length > 255) {
      return 'Studio name must not exceed 255 characters';
    }
    // Remove potentially harmful characters
    final sanitized = value.replaceAll(RegExp(r'[<>"\']'), '');
    if (sanitized != value) {
      return 'Studio name contains invalid characters';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
}
```

## Environment Security

### Environment Variables

#### Secure Storage
```bash
# Never commit these to version control
# Use .env files (add to .gitignore)

# Database credentials
SUPABASE_DB_URL=jdbc:postgresql://db.xxx.supabase.co:5432/postgres
SUPABASE_DB_USERNAME=postgres
SUPABASE_DB_PASSWORD=your-secure-password

# JWT configuration (future)
JWT_SECRET=your-256-bit-secret-key
JWT_EXPIRATION=86400000

# API keys (future)
GOOGLE_MAPS_API_KEY=your-api-key
STRIPE_SECRET_KEY=sk_live_your-stripe-key
```

#### Production Secrets Management
```yaml
# Use cloud provider secret management
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id studio-finder/db-credentials

# Google Secret Manager
gcloud secrets versions access latest --secret="db-password"

# Azure Key Vault
az keyvault secret show --name "db-password" --vault-name "studio-finder-vault"
```

### Docker Security

#### Secure Dockerfile
```dockerfile
# Use specific version tags, not 'latest'
FROM openjdk:17-jdk-slim

# Create non-root user
RUN groupadd -r studioapp && useradd -r -g studioapp studioapp

# Set working directory
WORKDIR /app

# Copy and build application
COPY --chown=studioapp:studioapp . .
RUN ./mvnw clean package -DskipTests

# Switch to non-root user
USER studioapp

# Expose port
EXPOSE 8080

# Run application
CMD ["java", "-jar", "target/studio-backend-0.0.1-SNAPSHOT.jar"]
```

#### Container Security Scanning
```bash
# Scan for vulnerabilities
docker scan studio-backend:latest

# Use security-focused base images
FROM gcr.io/distroless/java17-debian11
```

## Network Security

### HTTPS Configuration

#### Nginx SSL Configuration
```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    # SSL certificate
    ssl_certificate /etc/ssl/certs/yourdomain.crt;
    ssl_certificate_key /etc/ssl/private/yourdomain.key;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # CSP header
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://api.yourdomain.com;";
    
    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Security headers for proxied requests
        proxy_hide_header X-Powered-By;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

### Firewall Configuration
```bash
# Allow only necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw deny 8080/tcp   # Block direct access to backend
ufw enable
```

## Monitoring and Logging

### Security Logging
```java
@Component
public class SecurityEventLogger {
    
    private static final Logger securityLogger = LoggerFactory.getLogger("SECURITY");
    
    public void logFailedLogin(String username, String ipAddress) {
        securityLogger.warn("Failed login attempt - Username: {}, IP: {}", 
            sanitize(username), sanitize(ipAddress));
    }
    
    public void logSuspiciousActivity(String activity, String details) {
        securityLogger.error("Suspicious activity detected - Activity: {}, Details: {}", 
            sanitize(activity), sanitize(details));
    }
    
    private String sanitize(String input) {
        if (input == null) return "null";
        return input.replaceAll("[\r\n\t]", "_");
    }
}
```

### Rate Limiting
```java
@Component
public class RateLimitingFilter implements Filter {
    
    private final Map<String, List<Long>> requestCounts = new ConcurrentHashMap<>();
    private static final int MAX_REQUESTS = 100;
    private static final long TIME_WINDOW = 60000; // 1 minute
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, 
                        FilterChain chain) throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String clientIp = getClientIp(httpRequest);
        
        if (isRateLimited(clientIp)) {
            HttpServletResponse httpResponse = (HttpServletResponse) response;
            httpResponse.setStatus(429); // Too Many Requests
            httpResponse.getWriter().write("Rate limit exceeded");
            return;
        }
        
        chain.doFilter(request, response);
    }
    
    private boolean isRateLimited(String clientIp) {
        long now = System.currentTimeMillis();
        List<Long> requests = requestCounts.computeIfAbsent(clientIp, k -> new ArrayList<>());
        
        // Remove old requests
        requests.removeIf(time -> now - time > TIME_WINDOW);
        
        if (requests.size() >= MAX_REQUESTS) {
            return true;
        }
        
        requests.add(now);
        return false;
    }
}
```

## Security Checklist

### Development
- [ ] Input validation on all user inputs
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection enabled
- [ ] Secure password hashing (when authentication is added)
- [ ] Environment variables for sensitive data
- [ ] Error messages don't expose sensitive information

### Deployment
- [ ] HTTPS enabled with valid SSL certificate
- [ ] Security headers configured
- [ ] Database connections encrypted
- [ ] Firewall rules configured
- [ ] Non-root user for application processes
- [ ] Regular security updates applied
- [ ] Monitoring and logging enabled

### Production
- [ ] Regular security audits
- [ ] Dependency vulnerability scanning
- [ ] Penetration testing
- [ ] Incident response plan
- [ ] Backup and recovery procedures
- [ ] Access control reviews
- [ ] Security training for team members

## Incident Response

### Security Incident Procedure

1. **Detection**: Monitor logs and alerts for suspicious activity
2. **Assessment**: Determine severity and potential impact
3. **Containment**: Isolate affected systems
4. **Investigation**: Analyze the incident and gather evidence
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Document and improve security measures

### Emergency Contacts

- **Security Team**: security@studio-finder.com
- **DevOps Team**: devops@studio-finder.com
- **Management**: management@studio-finder.com

## Compliance

### Data Protection
- Follow GDPR guidelines for user data
- Implement data retention policies
- Provide data export/deletion capabilities
- Maintain audit logs

### Industry Standards
- Follow OWASP Top 10 guidelines
- Implement secure coding practices
- Regular security assessments
- Compliance with local data protection laws

---

**Last Updated**: January 2024  
**Version**: 1.0  
**Contact**: security@studio-finder.com

# Deployment Guide - Studio Finder Application

## Overview

This guide covers deployment strategies for the Studio Finder application, including local development, containerized deployment, and cloud deployment options.

## Table of Contents

1. [Local Development Setup](#local-development-setup)
2. [Docker Deployment](#docker-deployment)
3. [Cloud Deployment Options](#cloud-deployment-options)
4. [Environment Configuration](#environment-configuration)
5. [Monitoring and Logging](#monitoring-and-logging)
6. [Security Considerations](#security-considerations)
7. [Troubleshooting](#troubleshooting)

## Local Development Setup

### Prerequisites

- **Java 17+** (OpenJDK recommended)
- **Maven 3.6+** (or use included Maven wrapper)
- **Flutter 3.0+**
- **PostgreSQL 12+** (or use Docker)
- **Git**

### Backend Setup

```bash
# Clone the repository
git clone <repository-url>
cd spag/backend

# Run with Maven wrapper (recommended)
./mvnw spring-boot:run

# Or with system Maven
mvn spring-boot:run

# The backend will be available at http://localhost:8080
```

### Frontend Setup

```bash
# Navigate to frontend directory
cd spag/frontend

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or build for specific platform
flutter build apk          # Android
flutter build ios          # iOS (macOS only)
flutter build web          # Web
```

### Database Setup

#### Option 1: Local PostgreSQL
```bash
# Install PostgreSQL
# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# macOS
brew install postgresql

# Windows
# Download from https://www.postgresql.org/download/windows/

# Create database
sudo -u postgres createdb studio_db

# Create user (optional)
sudo -u postgres createuser --interactive
```

#### Option 2: Docker PostgreSQL
```bash
docker run --name studio-postgres \
  -e POSTGRES_DB=studio_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  -d postgres:15-alpine
```

## Docker Deployment

### Single Container Deployment

#### Backend Only
```bash
# Build the backend image
cd backend
docker build -t studio-backend .

# Run with environment variables
docker run -d \
  --name studio-backend \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SUPABASE_DB_URL=jdbc:postgresql://your-db-host:5432/postgres \
  -e SUPABASE_DB_USERNAME=postgres \
  -e SUPABASE_DB_PASSWORD=your-password \
  studio-backend
```

### Multi-Container Deployment

#### Using Docker Compose
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and start
docker-compose up --build -d
```

#### Production Docker Compose
Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: studio-backend-prod
    environment:
      SPRING_PROFILES_ACTIVE: prod
      SUPABASE_DB_URL: ${SUPABASE_DB_URL}
      SUPABASE_DB_USERNAME: ${SUPABASE_DB_USERNAME}
      SUPABASE_DB_PASSWORD: ${SUPABASE_DB_PASSWORD}
    ports:
      - "8080:8080"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - studio-network

  nginx:
    image: nginx:alpine
    container_name: studio-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - studio-network

networks:
  studio-network:
    driver: bridge
```

## Cloud Deployment Options

### 1. Heroku Deployment

#### Backend Deployment
```bash
# Install Heroku CLI
# Create Heroku app
heroku create studio-finder-backend

# Set environment variables
heroku config:set SPRING_PROFILES_ACTIVE=prod
heroku config:set SUPABASE_DB_URL=your-db-url
heroku config:set SUPABASE_DB_USERNAME=postgres
heroku config:set SUPABASE_DB_PASSWORD=your-password

# Deploy
git subtree push --prefix=backend heroku main

# Or create Procfile in backend directory
echo "web: java -jar target/studio-backend-0.0.1-SNAPSHOT.jar" > backend/Procfile
```

#### Heroku Configuration Files

**backend/system.properties**
```properties
java.runtime.version=17
```

**backend/Procfile**
```
web: java -Dserver.port=$PORT -jar target/studio-backend-0.0.1-SNAPSHOT.jar
```

### 2. AWS Deployment

#### Using AWS Elastic Beanstalk
```bash
# Install EB CLI
pip install awsebcli

# Initialize EB application
cd backend
eb init studio-finder-backend

# Create environment
eb create production

# Deploy
eb deploy

# Set environment variables
eb setenv SPRING_PROFILES_ACTIVE=prod
eb setenv SUPABASE_DB_URL=your-db-url
eb setenv SUPABASE_DB_USERNAME=postgres
eb setenv SUPABASE_DB_PASSWORD=your-password
```

#### Using AWS ECS with Fargate
```yaml
# task-definition.json
{
  "family": "studio-finder-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "studio-backend",
      "image": "your-account.dkr.ecr.region.amazonaws.com/studio-backend:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "prod"
        }
      ],
      "secrets": [
        {
          "name": "SUPABASE_DB_URL",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:studio-finder/db-url"
        }
      ]
    }
  ]
}
```

### 3. Google Cloud Platform

#### Using Cloud Run
```bash
# Build and push to Container Registry
gcloud builds submit --tag gcr.io/PROJECT-ID/studio-backend backend/

# Deploy to Cloud Run
gcloud run deploy studio-backend \
  --image gcr.io/PROJECT-ID/studio-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars SPRING_PROFILES_ACTIVE=prod \
  --set-env-vars SUPABASE_DB_URL=your-db-url
```

### 4. DigitalOcean App Platform

**app.yaml**
```yaml
name: studio-finder
services:
- name: backend
  source_dir: backend
  github:
    repo: your-username/studio-finder
    branch: main
  run_command: java -jar target/studio-backend-0.0.1-SNAPSHOT.jar
  environment_slug: java
  instance_count: 1
  instance_size_slug: basic-xxs
  envs:
  - key: SPRING_PROFILES_ACTIVE
    value: prod
  - key: SUPABASE_DB_URL
    value: your-db-url
    type: SECRET
  - key: SUPABASE_DB_USERNAME
    value: postgres
    type: SECRET
  - key: SUPABASE_DB_PASSWORD
    value: your-password
    type: SECRET
```

## Environment Configuration

### Development Environment
```yaml
# application-dev.yml
spring:
  profiles:
    active: dev
  datasource:
    url: jdbc:postgresql://localhost:5432/studio_db
    username: postgres
    password: password
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: update

logging:
  level:
    com.spag.studio: DEBUG
```

### Production Environment
```yaml
# application-prod.yml
spring:
  profiles:
    active: prod
  datasource:
    url: ${SUPABASE_DB_URL}
    username: ${SUPABASE_DB_USERNAME}
    password: ${SUPABASE_DB_PASSWORD}
  jpa:
    show-sql: false
    hibernate:
      ddl-auto: validate

logging:
  level:
    com.spag.studio: INFO
    org.springframework.web: WARN
```

### Environment Variables Template

Create `.env.template`:
```bash
# Database Configuration
SUPABASE_DB_URL=jdbc:postgresql://db.xxx.supabase.co:5432/postgres
SUPABASE_DB_USERNAME=postgres
SUPABASE_DB_PASSWORD=your-secure-password

# Application Configuration
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080

# Optional: JWT Configuration (for future authentication)
JWT_SECRET=your-jwt-secret-key
JWT_EXPIRATION=86400000

# Optional: External API Keys
GOOGLE_MAPS_API_KEY=your-google-maps-key
STRIPE_SECRET_KEY=your-stripe-secret-key
```

## Monitoring and Logging

### Application Monitoring

#### Health Check Endpoint
```bash
# Check application health
curl http://your-domain/api/health

# Expected response
Studio API is running!
```

#### Custom Health Indicators
```java
@Component
public class DatabaseHealthIndicator implements HealthIndicator {
    
    @Autowired
    private StudioRepository studioRepository;
    
    @Override
    public Health health() {
        try {
            long count = studioRepository.count();
            return Health.up()
                .withDetail("database", "Available")
                .withDetail("studio_count", count)
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("database", "Unavailable")
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

### Logging Configuration

#### Logback Configuration
```xml
<!-- logback-spring.xml -->
<configuration>
    <springProfile name="dev">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="DEBUG">
            <appender-ref ref="CONSOLE" />
        </root>
    </springProfile>
    
    <springProfile name="prod">
        <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <file>logs/studio-finder.log</file>
            <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
                <fileNamePattern>logs/studio-finder.%d{yyyy-MM-dd}.log</fileNamePattern>
                <maxHistory>30</maxHistory>
            </rollingPolicy>
            <encoder>
                <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="FILE" />
        </root>
    </springProfile>
</configuration>
```

### External Monitoring Services

#### New Relic Integration
```yaml
# Add to pom.xml
<dependency>
    <groupId>com.newrelic.agent.java</groupId>
    <artifactId>newrelic-java</artifactId>
    <version>8.7.0</version>
    <scope>provided</scope>
</dependency>
```

#### Datadog Integration
```yaml
# Add JVM arguments
-javaagent:dd-java-agent.jar
-Ddd.service=studio-finder-backend
-Ddd.env=production
```

## Security Considerations

### SSL/TLS Configuration

#### Nginx SSL Configuration
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### Security Headers
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .headers(headers -> headers
                .frameOptions().deny()
                .contentTypeOptions().and()
                .httpStrictTransportSecurity(hstsConfig -> hstsConfig
                    .maxAgeInSeconds(31536000)
                    .includeSubdomains(true)
                )
            )
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable());
        
        return http.build();
    }
}
```

## Troubleshooting

### Common Deployment Issues

#### 1. Port Binding Issues
```bash
# Check if port is in use
netstat -tulpn | grep :8080

# Kill process using port
sudo kill -9 $(sudo lsof -t -i:8080)
```

#### 2. Memory Issues
```bash
# Increase JVM memory
export JAVA_OPTS="-Xmx512m -Xms256m"

# Or in Dockerfile
ENV JAVA_OPTS="-Xmx512m -Xms256m"
```

#### 3. Database Connection Issues
```bash
# Test database connectivity
telnet db.xxx.supabase.co 5432

# Check connection string format
echo $SUPABASE_DB_URL
```

#### 4. SSL Certificate Issues
```bash
# Test SSL certificate
openssl s_client -connect your-domain.com:443

# Check certificate expiration
openssl x509 -in cert.pem -text -noout | grep "Not After"
```

### Performance Optimization

#### JVM Tuning
```bash
# Production JVM arguments
-Xms512m -Xmx1024m
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/tmp/heapdump.hprof
```

#### Database Connection Pooling
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 20000
      idle-timeout: 300000
      max-lifetime: 1200000
```

### Rollback Procedures

#### Docker Rollback
```bash
# Tag current version
docker tag studio-backend:latest studio-backend:backup

# Pull previous version
docker pull studio-backend:previous-version

# Stop current container
docker stop studio-backend

# Start with previous version
docker run -d --name studio-backend studio-backend:previous-version
```

#### Database Rollback
```sql
-- Create backup before deployment
pg_dump -h db.xxx.supabase.co -U postgres -d postgres > backup.sql

-- Restore if needed
psql -h db.xxx.supabase.co -U postgres -d postgres < backup.sql
```

## Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed and tested
- [ ] Environment variables configured
- [ ] Database migrations prepared
- [ ] SSL certificates valid
- [ ] Backup procedures tested
- [ ] Monitoring configured

### Deployment
- [ ] Deploy to staging environment
- [ ] Run integration tests
- [ ] Verify health checks
- [ ] Deploy to production
- [ ] Verify application functionality
- [ ] Monitor logs and metrics

### Post-Deployment
- [ ] Verify all endpoints working
- [ ] Check database connectivity
- [ ] Monitor application performance
- [ ] Verify SSL certificate
- [ ] Test mobile app connectivity
- [ ] Update documentation

---

**Last Updated**: January 2024  
**Version**: 1.0  
**Contact**: devops-team@studio-finder.com

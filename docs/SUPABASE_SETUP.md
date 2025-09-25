# Supabase Setup Guide

## Overview

This guide walks you through setting up Supabase as the database backend for the Studio Finder application. Supabase provides a PostgreSQL database with a REST API, real-time subscriptions, and authentication.

## Prerequisites

- Supabase account (free tier available)
- Basic understanding of SQL
- Access to the Studio Finder backend code

## Step 1: Create Supabase Project

### 1.1 Sign Up / Log In
1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up with GitHub, Google, or email
4. Verify your email if required

### 1.2 Create New Project
1. Click "New Project"
2. Choose your organization (or create one)
3. Fill in project details:
   - **Project Name**: `studio-finder-dev` (for development)
   - **Database Password**: Generate a strong password (save this!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is sufficient for development

4. Click "Create new project"
5. Wait for project initialization (2-3 minutes)

## Step 2: Database Schema Setup

### 2.1 Access SQL Editor
1. In your Supabase dashboard, go to "SQL Editor"
2. Click "New query"

### 2.2 Create Studios Table
Run the following SQL to create the studios table:

```sql
-- Create studios table
CREATE TABLE IF NOT EXISTS studios (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    image_url VARCHAR(500),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_studios_updated_at 
    BEFORE UPDATE ON studios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_studios_location ON studios(location);
CREATE INDEX IF NOT EXISTS idx_studios_price ON studios(price_per_hour);
CREATE INDEX IF NOT EXISTS idx_studios_available ON studios(is_available);
CREATE INDEX IF NOT EXISTS idx_studios_created_at ON studios(created_at);

-- Add comments for documentation
COMMENT ON TABLE studios IS 'Recording studios available for booking';
COMMENT ON COLUMN studios.name IS 'Studio name';
COMMENT ON COLUMN studios.description IS 'Detailed studio description';
COMMENT ON COLUMN studios.location IS 'Studio location (city, state)';
COMMENT ON COLUMN studios.price_per_hour IS 'Hourly rental price in INR';
COMMENT ON COLUMN studios.image_url IS 'URL to studio image';
COMMENT ON COLUMN studios.contact_email IS 'Studio contact email';
COMMENT ON COLUMN studios.contact_phone IS 'Studio contact phone';
COMMENT ON COLUMN studios.is_available IS 'Studio availability status';
```

### 2.3 Insert Sample Data
Add some sample studios for testing:

```sql
-- Insert sample studio data
INSERT INTO studios (name, description, location, price_per_hour, image_url, contact_email, contact_phone) VALUES
(
    'Creative Sound Studio',
    'Professional recording studio with state-of-the-art equipment. Perfect for music production, podcasts, and voice-overs. Features include SSL console, Pro Tools HDX, Neumann microphones, and acoustically treated rooms.',
    'Mumbai, Maharashtra',
    2500.00,
    'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500',
    'info@creativesound.com',
    '+91-9876543210'
),
(
    'Harmony Music Hub',
    'Spacious studio with excellent acoustics and professional mixing capabilities. Ideal for bands and solo artists. Equipment includes Yamaha DM2000, Logic Pro X, vintage analog gear, and a live room for 8+ musicians.',
    'Bangalore, Karnataka',
    3000.00,
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
    'contact@harmonymusic.com',
    '+91-9876543211'
),
(
    'Digital Dreams Studio',
    'Modern digital recording facility with the latest software and hardware. Specializing in electronic music production, hip-hop, and contemporary genres. Features Ableton Live, Native Instruments, and custom controllers.',
    'Delhi, NCR',
    2200.00,
    'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=500',
    'hello@digitaldreams.com',
    '+91-9876543212'
),
(
    'Acoustic Vibes Studio',
    'Intimate studio perfect for acoustic recordings and singer-songwriter sessions. Warm and cozy atmosphere with vintage microphones, tube preamps, and natural reverb chambers. Ideal for folk, jazz, and classical music.',
    'Chennai, Tamil Nadu',
    1800.00,
    'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=500',
    'info@acousticvibes.com',
    '+91-9876543213'
),
(
    'Pro Audio Labs',
    'High-end professional studio with Grammy-winning engineers. Full production services available including mixing, mastering, and post-production. Features Neve console, Studer tape machines, and world-class monitoring.',
    'Pune, Maharashtra',
    4500.00,
    'https://images.unsplash.com/photo-1598653222000-6b7b7a552625?w=500',
    'bookings@proaudiolabs.com',
    '+91-9876543214'
);
```

## Step 3: Configure Database Access

### 3.1 Get Connection Details
1. Go to "Settings" → "Database"
2. Note down the connection details:
   - **Host**: `db.xxx.supabase.co`
   - **Database name**: `postgres`
   - **Port**: `5432`
   - **User**: `postgres`
   - **Password**: (the one you set during project creation)

### 3.2 Connection String Format
Your JDBC URL will be:
```
jdbc:postgresql://db.xxx.supabase.co:5432/postgres
```

Replace `xxx` with your actual project reference.

## Step 4: Configure Row Level Security (RLS)

### 4.1 Enable RLS (Optional for Development)
For production, enable Row Level Security:

```sql
-- Enable RLS on studios table
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access
CREATE POLICY "Allow public read access" ON studios
    FOR SELECT USING (true);

-- Create policy for authenticated users to insert/update
CREATE POLICY "Allow authenticated users to insert" ON studios
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update" ON studios
    FOR UPDATE USING (auth.role() = 'authenticated');
```

### 4.2 Disable RLS for Development
For easier development, you can disable RLS:

```sql
-- Disable RLS for development
ALTER TABLE studios DISABLE ROW LEVEL SECURITY;
```

## Step 5: Backend Configuration

### 5.1 Update Application Properties
Update your `application.yml` with Supabase credentials:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://db.xxx.supabase.co:5432/postgres
    username: postgres
    password: your-database-password
    driver-class-name: org.postgresql.Driver
```

### 5.2 Environment Variables
For production, use environment variables:

```bash
export SUPABASE_DB_URL="jdbc:postgresql://db.xxx.supabase.co:5432/postgres"
export SUPABASE_DB_USERNAME="postgres"
export SUPABASE_DB_PASSWORD="your-password"
```

### 5.3 Docker Environment
For Docker deployment:

```yaml
environment:
  SUPABASE_DB_URL: jdbc:postgresql://db.xxx.supabase.co:5432/postgres
  SUPABASE_DB_USERNAME: postgres
  SUPABASE_DB_PASSWORD: your-password
```

## Step 6: Test Connection

### 6.1 Test from Backend
1. Start your Spring Boot application
2. Check logs for successful database connection
3. Test the `/api/health` endpoint
4. Test the `/api/studios` endpoint

### 6.2 Test from Supabase Dashboard
1. Go to "Table Editor" in Supabase
2. Select the `studios` table
3. Verify sample data is present
4. Try adding/editing records

## Step 7: Production Setup

### 7.1 Create Production Project
1. Create a separate Supabase project for production
2. Use naming convention: `studio-finder-prod`
3. Choose appropriate region for your users
4. Consider upgrading to Pro plan for production

### 7.2 Production Configuration
```yaml
# Production application.yml
spring:
  profiles:
    active: prod
  datasource:
    url: ${SUPABASE_DB_URL}
    username: ${SUPABASE_DB_USERNAME}
    password: ${SUPABASE_DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate  # Don't auto-create tables in production
```

### 7.3 Database Migration
For production, use proper database migrations:

```sql
-- Create migration scripts
-- V1__Create_studios_table.sql
-- V2__Add_indexes.sql
-- V3__Insert_initial_data.sql
```

## Step 8: Monitoring and Maintenance

### 8.1 Database Monitoring
1. Monitor database usage in Supabase dashboard
2. Set up alerts for high CPU/memory usage
3. Monitor connection count
4. Track query performance

### 8.2 Backup Strategy
1. Supabase automatically backs up your database
2. For critical data, consider additional backups
3. Test restore procedures regularly

### 8.3 Performance Optimization
```sql
-- Monitor slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Add indexes for common queries
CREATE INDEX CONCURRENTLY idx_studios_name_search 
ON studios USING gin(to_tsvector('english', name || ' ' || description));
```

## Troubleshooting

### Common Issues

#### Connection Refused
- Check if your IP is whitelisted in Supabase
- Verify connection string format
- Ensure database is not paused (free tier limitation)

#### Authentication Failed
- Double-check username and password
- Ensure password doesn't contain special characters that need escaping
- Try resetting the database password

#### SSL Connection Issues
Add SSL parameters to connection string:
```
jdbc:postgresql://db.xxx.supabase.co:5432/postgres?sslmode=require
```

#### Performance Issues
- Add appropriate indexes
- Monitor query execution plans
- Consider connection pooling
- Upgrade to higher tier if needed

### Getting Help

1. **Supabase Documentation**: [docs.supabase.com](https://docs.supabase.com)
2. **Community Support**: [github.com/supabase/supabase/discussions](https://github.com/supabase/supabase/discussions)
3. **Discord Community**: [discord.supabase.com](https://discord.supabase.com)

## Security Best Practices

### 1. Environment Variables
Never commit database credentials to version control:

```bash
# .env file (add to .gitignore)
SUPABASE_DB_URL=jdbc:postgresql://db.xxx.supabase.co:5432/postgres
SUPABASE_DB_USERNAME=postgres
SUPABASE_DB_PASSWORD=your-secure-password
```

### 2. Network Security
- Use SSL connections in production
- Restrict database access to known IPs
- Use VPC if available in your deployment

### 3. Database Security
- Enable RLS for production
- Use least-privilege access
- Regular security updates
- Monitor access logs

## Cost Optimization

### Free Tier Limits
- 500MB database storage
- 2GB bandwidth per month
- 50MB file storage
- 2 concurrent connections

### Optimization Tips
1. **Efficient Queries**: Use indexes and avoid N+1 queries
2. **Connection Pooling**: Reuse database connections
3. **Data Cleanup**: Remove unnecessary data regularly
4. **Monitoring**: Track usage to avoid overages

---

**Last Updated**: January 2024  
**Supabase Version**: Latest  
**Contact**: development-team@studio-finder.com

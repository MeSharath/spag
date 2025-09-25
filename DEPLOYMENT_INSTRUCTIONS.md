# 🚀 Studio Finder - Complete Deployment Instructions

## 📋 **Your Server & Database Configuration**

### **🖥️ Server Details**
✅ **IP Address**: `10.0.0.156`  
✅ **OS**: Ubuntu 22.04.5 LTS  
✅ **Architecture**: ARM64 (Neoverse-N1)  
✅ **RAM**: 11GB  
✅ **CPU**: 2 cores  
✅ **Disk**: 45GB (40GB available)  

### **🗄️ Supabase Configuration**
✅ **Project URL**: `https://schsrcjdukkduduueytz.supabase.co`  
✅ **Project Reference**: `schsrcjdukkduduueytz`  
✅ **Database**: PostgreSQL (Free Tier - 500MB)  
✅ **Region**: Auto-selected by Supabase  

## 🔒 **Security Setup Complete**

- ✅ Credentials secured in `.env` files (not committed to git)
- ✅ `.gitignore` properly configured
- ✅ Production-ready environment variables
- ✅ Secure file permissions (600)

## 🚀 **Quick Deployment (3 Steps)**

### **Step 1: Upload to Your Ubuntu Server**
```bash
# Upload your project to Ubuntu server
scp -r . user@10.0.0.156:/home/user/studio-finder/

# SSH into your server
ssh user@10.0.0.156
cd studio-finder
```

### **Step 2: Run Automated Setup**
```bash
# Make scripts executable
chmod +x deploy/*.sh

# 1. Setup server dependencies
./deploy/setup-server.sh

# 2. Configure server for ARM64 optimization
./deploy/server-config.sh

# 3. Configure Supabase (creates database tables and sample data)
./deploy/setup-supabase.sh

# 4. Deploy application
./deploy/deploy-app.sh
```

### **Step 3: Verify Deployment**
```bash
# Check application health
curl http://10.0.0.156/api/health

# Test studios API
curl http://10.0.0.156/api/studios

# View application status
./deploy/manage-app.sh status
```

## 📱 **Flutter App Configuration**

Your Flutter app is already configured for local development. For production:

```dart
// In frontend/lib/services/api_service.dart
static const String baseUrl = 'http://10.0.0.156/api';
// Or with domain: 'https://yourdomain.com/api'
```

## 🔧 **Manual Configuration (If Needed)**

### **Backend Environment Variables**
Already configured in `setup-supabase.sh`, but if you need to manually create `.env`:

```bash
# Create /opt/studio-finder/backend/.env
SPRING_PROFILES_ACTIVE=prod
DATABASE_URL=jdbc:postgresql://db.schsrcjdukkduduueytz.supabase.co:5432/postgres
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=Ghazi@1234567890
SERVER_PORT=8080
JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC
```

### **Database Schema**
The `setup-supabase.sh` script automatically creates:
- ✅ `studios` table with all required fields
- ✅ Indexes for performance (location, price, availability)
- ✅ Auto-update triggers for timestamps
- ✅ Sample data (5 studios)

## 🎯 **Available Management Commands**

```bash
# Application Management
./deploy/manage-app.sh status      # Check status
./deploy/manage-app.sh restart     # Restart app
./deploy/manage-app.sh logs-live   # View live logs
./deploy/manage-app.sh health      # Full health check
./deploy/manage-app.sh update      # Update from git

# Database Management
./deploy/backup/db-backup.sh backup    # Create backup
./deploy/backup/db-backup.sh list      # List backups
./deploy/backup/db-backup.sh info      # Show DB info

# Monitoring
./deploy/monitoring/performance-dashboard.sh  # Real-time dashboard
./deploy/monitoring/health-monitor.sh         # Advanced monitoring

# Configuration
./deploy/config/config-manager.sh show        # Show current config
./deploy/config/config-manager.sh validate    # Validate setup
```

## 🔒 **SSL Setup (Optional)**

If you have a domain name:

```bash
# Setup SSL certificate
./deploy/ssl-setup.sh

# Update Flutter app to use HTTPS
# Change API URL to: https://yourdomain.com/api
```

## 📊 **Monitoring & Alerts**

### **Real-time Dashboard**
```bash
./deploy/monitoring/performance-dashboard.sh
```
- System resources (CPU, memory, disk)
- Application metrics (response times, errors)
- Live log monitoring
- Interactive controls

### **Automated Monitoring**
```bash
./deploy/monitoring/health-monitor.sh
```
- Health checks every 5 minutes
- Email/Slack alerts on issues
- Automatic service restart
- SSL certificate monitoring

## 🔍 **Verification Checklist**

After deployment, verify:

- [ ] **Service Running**: `systemctl status studio-finder`
- [ ] **API Health**: `curl http://your-server/api/health`
- [ ] **Database**: `curl http://your-server/api/studios`
- [ ] **Nginx Proxy**: Check port 80 access
- [ ] **Logs**: `./deploy/manage-app.sh logs`
- [ ] **Flutter App**: Update API URL and test

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Service won't start**:
   ```bash
   ./deploy/manage-app.sh logs
   # Check Java version: java -version
   # Verify environment: cat /opt/studio-finder/backend/.env
   ```

2. **Database connection failed**:
   ```bash
   ./deploy/backup/db-backup.sh test
   # Verify Supabase credentials
   # Check network connectivity
   ```

3. **API not accessible**:
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   # Check firewall: sudo firewall-cmd --list-ports
   ```

## 📈 **Performance Optimization**

Your setup includes:
- ✅ **JVM Tuning**: G1GC, optimized heap sizes
- ✅ **Database Indexes**: Fast queries on location, price
- ✅ **Nginx Caching**: Static content optimization
- ✅ **Connection Pooling**: Efficient database connections
- ✅ **Log Rotation**: Prevents disk space issues

## 💰 **Cost Monitoring**

**Supabase Free Tier Limits**:
- Database: 500MB storage
- Bandwidth: 2GB/month
- API Requests: Unlimited

Monitor usage in Supabase dashboard to avoid hitting limits.

## 🔄 **Updates & Maintenance**

### **Regular Updates**
```bash
# Weekly
./deploy/manage-app.sh update      # Update application
./deploy/manage-app.sh cleanup     # Clean old files

# Monthly
./deploy/backup/db-backup.sh backup  # Create backup
./deploy/config/config-manager.sh validate  # Validate config
```

### **Security Updates**
```bash
# Update system packages
sudo yum update -y  # Oracle Linux/RHEL
# OR
sudo apt update && sudo apt upgrade -y  # Ubuntu

# Update SSL certificates (automatic with Let's Encrypt)
sudo certbot renew --dry-run
```

---

## 🎉 **You're All Set!**

Your Studio Finder application is now configured with:
- ✅ **Secure Supabase integration**
- ✅ **Production-ready deployment scripts**
- ✅ **Comprehensive monitoring**
- ✅ **Automated backups**
- ✅ **SSL support**
- ✅ **Performance optimization**

**Next Steps**: Upload to your Oracle server and run the 3-step deployment process above!

---

**Need Help?** Check logs first: `./deploy/manage-app.sh logs-live`

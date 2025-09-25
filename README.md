# Studio Finder - Complete End-to-End Application

A full-stack application for browsing and booking recording studios, built with Spring Boot backend, Flutter frontend, and Supabase database integration.

## 🏗️ Architecture Overview

```
┌─────────────────┐    HTTP/REST    ┌─────────────────┐    JDBC    ┌─────────────────┐
│                 │ ◄──────────────► │                 │ ◄─────────► │                 │
│  Flutter App    │                 │  Spring Boot    │             │   Supabase      │
│  (Frontend)     │                 │   (Backend)     │             │  (Database)     │
│                 │                 │                 │             │                 │
└─────────────────┘                 └─────────────────┘             └─────────────────┘
```

## 📋 Project Structure

```
spag/
├── backend/                    # Spring Boot API
│   ├── src/main/java/com/spag/studio/
│   │   ├── StudioBackendApplication.java
│   │   ├── controller/         # REST Controllers
│   │   ├── service/           # Business Logic
│   │   ├── repository/        # Data Access Layer
│   │   ├── model/            # Entity Models
│   │   ├── dto/              # Data Transfer Objects
│   │   └── config/           # Configuration Classes
│   ├── src/main/resources/
│   │   └── application.yml    # Application Configuration
│   ├── Dockerfile
│   └── pom.xml               # Maven Dependencies
├── frontend/                  # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart         # App Entry Point
│   │   ├── models/           # Data Models
│   │   ├── services/         # API Services
│   │   ├── providers/        # State Management
│   │   ├── screens/          # UI Screens
│   │   └── widgets/          # Reusable UI Components
│   └── pubspec.yaml          # Flutter Dependencies
├── docker-compose.yml        # Multi-container Setup
└── docs/                     # Documentation
```

## 🚀 Quick Start

### Prerequisites

- **Java 17+** (for Spring Boot backend)
- **Flutter 3.0+** (for mobile app)
- **Docker & Docker Compose** (for containerized deployment)
- **Supabase Account** (for database)

### 1. Backend Setup (Spring Boot)

#### Option A: Local Development
```bash
cd backend
./mvnw spring-boot:run
```

#### Option B: Docker
```bash
docker-compose up --build
```

The backend will be available at `http://localhost:8080`

### 2. Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

### 3. Database Setup (Supabase)

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Copy your database URL and credentials
3. Update the environment variables (see Configuration section)

## ⚙️ Configuration

### Backend Configuration

Create environment variables or update `application.yml`:

```yaml
# Development
SUPABASE_DB_URL=jdbc:postgresql://your-project.supabase.co:5432/postgres
SUPABASE_DB_USERNAME=postgres
SUPABASE_DB_PASSWORD=your-password

# Production
SPRING_PROFILES_ACTIVE=prod
```

### Frontend Configuration

Update `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://your-backend-url:8080/api';
```

## 📊 Database Schema

The application uses the following main entity:

### Studios Table
```sql
CREATE TABLE studios (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    image_url VARCHAR(500),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔌 API Endpoints

### Studios API

| Method | Endpoint | Description | Parameters |
|--------|----------|-------------|------------|
| GET | `/api/studios` | Get all studios | `location`, `maxPrice`, `search`, `availableOnly` |
| GET | `/api/studios/{id}` | Get studio by ID | - |
| POST | `/api/studios` | Create new studio | Studio JSON |
| PUT | `/api/studios/{id}` | Update studio | Studio JSON |
| DELETE | `/api/studios/{id}` | Delete studio | - |
| GET | `/api/health` | Health check | - |

### Example API Response

```json
{
  "id": 1,
  "name": "Creative Sound Studio",
  "description": "Professional recording studio with state-of-the-art equipment.",
  "location": "Mumbai, Maharashtra",
  "pricePerHour": 2500.0,
  "imageUrl": "https://example.com/image.jpg",
  "contactEmail": "info@creativesound.com",
  "contactPhone": "+91-9876543210",
  "isAvailable": true,
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:30:00"
}
```

## 🎯 Features

### Backend Features
- ✅ RESTful API with Spring Boot
- ✅ PostgreSQL database integration
- ✅ JPA/Hibernate ORM
- ✅ Data validation
- ✅ CORS configuration for Flutter
- ✅ Sample data initialization
- ✅ Docker support

### Frontend Features
- ✅ Modern Flutter UI with Material 3
- ✅ Studio listing with search and filters
- ✅ Detailed studio view
- ✅ State management with Provider
- ✅ HTTP API integration
- ✅ Error handling and loading states
- ✅ Responsive design

### Filtering & Search
- Search by studio name or description
- Filter by location
- Filter by maximum price
- Filter by availability status

## 🧪 Testing the End-to-End Flow

### 1. Start the Backend
```bash
cd backend
./mvnw spring-boot:run
```

### 2. Verify API Health
```bash
curl http://localhost:8080/api/health
```

### 3. Test Studios Endpoint
```bash
curl http://localhost:8080/api/studios
```

### 4. Run Flutter App
```bash
cd frontend
flutter run
```

### 5. Verify Complete Flow
1. Open the Flutter app
2. Verify studios are loaded from the backend
3. Test search functionality
4. Test filters
5. View studio details

## 🐳 Docker Deployment

### Development Environment
```bash
docker-compose up --build
```

### Production Deployment
```bash
# Build and push images
docker build -t studio-backend ./backend
docker push your-registry/studio-backend

# Deploy with environment variables
docker run -d \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SUPABASE_DB_URL=your-db-url \
  -e SUPABASE_DB_USERNAME=your-username \
  -e SUPABASE_DB_PASSWORD=your-password \
  studio-backend
```

## 🔐 Security Considerations

### Environment Variables
Never commit sensitive information. Use environment variables for:
- Database credentials
- API keys
- Production URLs

### CORS Configuration
The backend is configured to allow all origins for development. In production, restrict to your Flutter app's domain.

## 📱 User Stories

### As a Studio Seeker
1. **Browse Studios**: I want to see a list of available recording studios
2. **Search Studios**: I want to search for studios by name or description
3. **Filter Results**: I want to filter studios by location, price, and availability
4. **View Details**: I want to see detailed information about each studio
5. **Contact Studio**: I want to easily access studio contact information

### As a Studio Owner (Future Enhancement)
1. **List Studio**: I want to add my studio to the platform
2. **Manage Bookings**: I want to manage my studio's availability
3. **Update Information**: I want to update my studio's details and pricing

## 🚧 Development Roadmap

### Phase 1 (Current) ✅
- [x] Basic CRUD API for studios
- [x] Flutter app with studio listing
- [x] Search and filter functionality
- [x] Docker containerization

### Phase 2 (Next)
- [ ] User authentication
- [ ] Booking system
- [ ] Payment integration
- [ ] Push notifications

### Phase 3 (Future)
- [ ] Studio owner dashboard
- [ ] Reviews and ratings
- [ ] Advanced search with maps
- [ ] Mobile app for studio owners

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

#### Backend won't start
- Verify Java 17+ is installed
- Check database connection settings
- Ensure port 8080 is not in use

#### Flutter app can't connect to backend
- Verify backend is running on `http://localhost:8080`
- Check `api_service.dart` baseUrl configuration
- Ensure CORS is properly configured

#### Database connection issues
- Verify Supabase credentials
- Check network connectivity
- Ensure database URL format is correct

### Getting Help

1. Check the [Issues](https://github.com/your-repo/issues) page
2. Review the API documentation
3. Verify your environment configuration
4. Check the application logs

---

**Built with ❤️ using Spring Boot, Flutter, and Supabase**

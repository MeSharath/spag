# API Contract Documentation

## Overview

This document defines the API contract between the Flutter frontend and Spring Boot backend for the Studio Finder application.

## Base URL

- **Development**: `http://localhost:8080/api`
- **Production**: `https://your-domain.com/api`

## Authentication

Currently, the API does not require authentication. Future versions will implement JWT-based authentication.

## Common Response Format

### Success Response
```json
{
  "data": { ... },
  "status": "success",
  "message": "Operation completed successfully"
}
```

### Error Response
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": "Additional error details"
  },
  "status": "error"
}
```

## Endpoints

### 1. Health Check

**GET** `/health`

Check if the API is running and healthy.

**Response:**
```
Status: 200 OK
Content-Type: text/plain

Studio API is running!
```

### 2. Get All Studios

**GET** `/studios`

Retrieve a list of studios with optional filtering.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | string | No | Filter by location (case-insensitive partial match) |
| `maxPrice` | number | No | Filter by maximum price per hour |
| `search` | string | No | Search in studio name and description |
| `availableOnly` | boolean | No | Show only available studios (default: false) |

**Example Request:**
```
GET /api/studios?location=mumbai&maxPrice=3000&availableOnly=true
```

**Response:**
```json
Status: 200 OK
Content-Type: application/json

[
  {
    "id": 1,
    "name": "Creative Sound Studio",
    "description": "Professional recording studio with state-of-the-art equipment. Perfect for music production, podcasts, and voice-overs.",
    "location": "Mumbai, Maharashtra",
    "pricePerHour": 2500.0,
    "imageUrl": "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500",
    "contactEmail": "info@creativesound.com",
    "contactPhone": "+91-9876543210",
    "isAvailable": true,
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:30:00"
  }
]
```

### 3. Get Studio by ID

**GET** `/studios/{id}`

Retrieve a specific studio by its ID.

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Studio ID |

**Example Request:**
```
GET /api/studios/1
```

**Response:**
```json
Status: 200 OK
Content-Type: application/json

{
  "id": 1,
  "name": "Creative Sound Studio",
  "description": "Professional recording studio with state-of-the-art equipment. Perfect for music production, podcasts, and voice-overs.",
  "location": "Mumbai, Maharashtra",
  "pricePerHour": 2500.0,
  "imageUrl": "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500",
  "contactEmail": "info@creativesound.com",
  "contactPhone": "+91-9876543210",
  "isAvailable": true,
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:30:00"
}
```

**Error Response:**
```json
Status: 404 Not Found
Content-Type: application/json

{
  "error": "Studio not found",
  "status": 404
}
```

### 4. Create Studio

**POST** `/studios`

Create a new studio listing.

**Request Body:**
```json
{
  "name": "New Studio Name",
  "description": "Studio description",
  "location": "City, State",
  "pricePerHour": 2000.0,
  "imageUrl": "https://example.com/image.jpg",
  "contactEmail": "contact@studio.com",
  "contactPhone": "+91-1234567890",
  "isAvailable": true
}
```

**Response:**
```json
Status: 201 Created
Content-Type: application/json

{
  "id": 6,
  "name": "New Studio Name",
  "description": "Studio description",
  "location": "City, State",
  "pricePerHour": 2000.0,
  "imageUrl": "https://example.com/image.jpg",
  "contactEmail": "contact@studio.com",
  "contactPhone": "+91-1234567890",
  "isAvailable": true,
  "createdAt": "2024-01-15T15:30:00",
  "updatedAt": "2024-01-15T15:30:00"
}
```

### 5. Update Studio

**PUT** `/studios/{id}`

Update an existing studio.

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Studio ID |

**Request Body:**
```json
{
  "name": "Updated Studio Name",
  "description": "Updated description",
  "location": "Updated City, State",
  "pricePerHour": 2500.0,
  "imageUrl": "https://example.com/new-image.jpg",
  "contactEmail": "updated@studio.com",
  "contactPhone": "+91-9876543210",
  "isAvailable": false
}
```

**Response:**
```json
Status: 200 OK
Content-Type: application/json

{
  "id": 1,
  "name": "Updated Studio Name",
  "description": "Updated description",
  "location": "Updated City, State",
  "pricePerHour": 2500.0,
  "imageUrl": "https://example.com/new-image.jpg",
  "contactEmail": "updated@studio.com",
  "contactPhone": "+91-9876543210",
  "isAvailable": false,
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T16:45:00"
}
```

### 6. Delete Studio

**DELETE** `/studios/{id}`

Delete a studio listing.

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Studio ID |

**Response:**
```
Status: 204 No Content
```

**Error Response:**
```json
Status: 404 Not Found
Content-Type: application/json

{
  "error": "Studio not found",
  "status": 404
}
```

## Data Models

### Studio Model

```typescript
interface Studio {
  id: number;                    // Unique identifier
  name: string;                  // Studio name (required)
  description: string;           // Studio description (required)
  location: string;              // Studio location (required)
  pricePerHour: number;         // Price per hour in INR (required)
  imageUrl?: string;            // Studio image URL (optional)
  contactEmail?: string;        // Contact email (optional)
  contactPhone?: string;        // Contact phone (optional)
  isAvailable: boolean;         // Availability status (default: true)
  createdAt: string;            // ISO 8601 timestamp
  updatedAt: string;            // ISO 8601 timestamp
}
```

## Validation Rules

### Studio Creation/Update

| Field | Rules |
|-------|-------|
| `name` | Required, 1-255 characters |
| `description` | Required, 1-2000 characters |
| `location` | Required, 1-255 characters |
| `pricePerHour` | Required, positive number, max 2 decimal places |
| `imageUrl` | Optional, valid URL format, max 500 characters |
| `contactEmail` | Optional, valid email format |
| `contactPhone` | Optional, valid phone format |
| `isAvailable` | Optional, boolean (default: true) |

## Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `VALIDATION_ERROR` | Request validation failed |
| 404 | `STUDIO_NOT_FOUND` | Studio with given ID not found |
| 500 | `INTERNAL_SERVER_ERROR` | Unexpected server error |

## Rate Limiting

Currently, no rate limiting is implemented. Future versions may include:
- 100 requests per minute per IP
- 1000 requests per hour per authenticated user

## CORS Policy

The API allows cross-origin requests from:
- `http://localhost:*` (development)
- Your production Flutter app domain

## Versioning

The API follows semantic versioning. Current version: `v1`

Future versions will be accessible via:
- `/api/v2/studios`
- Header: `Accept: application/vnd.api+json;version=2`

## Sample Integration Code

### Flutter/Dart Example

```dart
// Get all studios
final response = await http.get(
  Uri.parse('$baseUrl/studios'),
  headers: {'Content-Type': 'application/json'},
);

if (response.statusCode == 200) {
  final List<dynamic> jsonList = json.decode(response.body);
  final studios = jsonList.map((json) => Studio.fromJson(json)).toList();
}

// Create a studio
final studio = Studio(
  name: 'New Studio',
  description: 'Description',
  location: 'Mumbai',
  pricePerHour: 2500.0,
);

final response = await http.post(
  Uri.parse('$baseUrl/studios'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode(studio.toJson()),
);
```

### JavaScript/React Example

```javascript
// Get all studios
const response = await fetch('/api/studios');
const studios = await response.json();

// Create a studio
const newStudio = {
  name: 'New Studio',
  description: 'Description',
  location: 'Mumbai',
  pricePerHour: 2500.0
};

const response = await fetch('/api/studios', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(newStudio),
});
```

## Testing

### Postman Collection

A Postman collection is available for testing all endpoints:

```json
{
  "info": {
    "name": "Studio Finder API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Get All Studios",
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/studios"
      }
    }
  ]
}
```

### cURL Examples

```bash
# Health check
curl -X GET http://localhost:8080/api/health

# Get all studios
curl -X GET http://localhost:8080/api/studios

# Get studios with filters
curl -X GET "http://localhost:8080/api/studios?location=mumbai&maxPrice=3000"

# Get studio by ID
curl -X GET http://localhost:8080/api/studios/1

# Create studio
curl -X POST http://localhost:8080/api/studios \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Studio",
    "description": "Test Description",
    "location": "Test Location",
    "pricePerHour": 2000.0
  }'
```

---

**Last Updated**: January 2024  
**Version**: 1.0  
**Contact**: development-team@studio-finder.com

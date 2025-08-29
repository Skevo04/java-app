# Deployment Guide

## Local Development

### Quick Start (H2 Database)
```bash
./mvnw spring-boot:run
# Access: http://localhost:8080
```

### With PostgreSQL
```bash
docker-compose up postgres -d
./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres
```

## Docker Deployment

### Single Container
```bash
# Build image
./mvnw spring-boot:build-image

# Run container
docker run -p 8080:8080 spring-petclinic:3.5.0-SNAPSHOT
```

### Full Stack with Docker Compose
```bash
# Start all services
docker-compose up --build

# Scale application
docker-compose up --scale app=3
```

## Production Deployment

### Environment Variables
```bash
export SPRING_PROFILES_ACTIVE=postgres
export DB_HOST=your-db-host
export DB_USER=your-db-user
export DB_PASSWORD=your-db-password
```

### Health Checks
- Application: `http://localhost:8080/actuator/health`
- Database: `http://localhost:8080/actuator/health/db`

### Monitoring
- Metrics: `http://localhost:8080/actuator/metrics`
- Info: `http://localhost:8080/actuator/info`

## CI/CD Pipeline

The Jenkins pipeline automatically:
1. Builds and tests the application
2. Creates Docker images
3. Deploys to staging environment
4. Runs integration tests
5. Promotes to production on success

Pipeline triggers on:
- Push to `main` branch
- Pull request creation
- Manual trigger via Jenkins UI
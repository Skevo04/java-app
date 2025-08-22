# Spring PetClinic DevOps Setup

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://jenkins.example.com/job/petclinic/)

## Quick Start

### Local Development with PostgreSQL
```bash
# Start PostgreSQL
docker-compose up postgres -d

# Run app with PostgreSQL profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres
```

### Full Docker Environment
```bash
# Build and start everything
docker-compose up --build

# Access application
open http://localhost:8080
```

## CI/CD Pipeline

The Jenkins pipeline includes:
- **Build**: Maven compile
- **Test**: Unit tests + coverage (JaCoCo)
- **Static Analysis**: Checkstyle + SpotBugs
- **Package**: JAR creation
- **Docker**: Image build
- **Deploy**: Docker Compose deployment

## Database Configuration

PostgreSQL connection via environment variables:
- `DB_HOST`: Database host (default: localhost)
- `DB_PORT`: Database port (default: 5432)
- `DB_NAME`: Database name (default: petclinic)
- `DB_USER`: Database user (default: petclinic)
- `DB_PASSWORD`: Database password (default: petclinic)

## Quality Gates

- Unit test coverage > 80%
- No Checkstyle violations
- No SpotBugs issues (High/Medium)
- All tests must pass

## Deployment

Production deployment triggered on `main` branch push via Jenkins pipeline.
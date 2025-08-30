# Jenkins CI/CD Pipeline Implementation with Spring PetClinic

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.java.net/projects/jdk/17/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.0-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://jenkins.example.com/job/petclinic/)

**A complete Jenkins CI/CD pipeline implementation** using Spring PetClinic as the demonstration application. This project showcases automated build, test, quality analysis, and deployment workflows with Jenkins.

## Jenkins CI/CD Pipeline - Main Focus

This repository demonstrates a **complete Jenkins pipeline implementation** with:

### Automated Pipeline Stages
1. **Build** - Maven compilation and dependency resolution
2. **Test** - Unit tests with JUnit 5, integration tests with Testcontainers
3. **Static Analysis** - Checkstyle code style, SpotBugs security/quality checks
4. **Package** - JAR artifact creation with build metadata
5. **Docker Build** - Container image creation
6. **Deploy** - Local Docker Compose deployment

### Quality Gates Enforced
- ✅ All tests must pass (unit + integration)
- ✅ Code coverage > 80% (JaCoCo)
- ✅ Zero Checkstyle violations
- ✅ No high/medium SpotBugs issues

## Demo Application: PetClinic

The pipeline uses **Spring PetClinic** as the demonstration application:
- **Pet Owners**: Register pets, schedule visits, view medical history
- **Veterinarians**: Manage patient records, track treatments, view schedules
- **Clinic Staff**: Handle appointments, maintain pet and owner databases

**Tech Stack**: Spring Boot 3.5, JPA/Hibernate, Thymeleaf, H2/MySQL/PostgreSQL, Docker

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Browser   │───▶│  Spring Boot App │───▶│    Database     │
│  (Thymeleaf)    │    │  (Port 8080)     │    │ H2/MySQL/Postgres│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Jenkins CI/CD   │
                       │  Pipeline        │
                       └──────────────────┘
```

## Quick Start

### Local Development
```bash
# Clone and run with H2 (in-memory database)
git clone <repository-url>
cd java-maven-jenkins
./mvnw spring-boot:run

# Access application: http://localhost:8080
```

### With Docker
```bash
# Full environment with PostgreSQL
docker-compose up --build

# Access application: http://localhost:8080
```

### Database Options
- **Default**: H2 (in-memory) - no setup required
- **MySQL**: `./mvnw spring-boot:run -Dspring-boot.run.profiles=mysql`
- **PostgreSQL**: `./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres`

## Pipeline Configuration

The Jenkins pipeline is defined in [Jenkinsfile](Jenkinsfile) and includes:
- **Tools**: Maven 3.9, JDK 17
- **Environment**: Docker image tagging with build numbers
- **Post-actions**: JUnit test reporting, artifact archiving
- **Deployment**: Automated Docker Compose deployment

## Environment Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SPRING_PROFILES_ACTIVE` | `default` | Database profile (mysql/postgres) |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `5432` | Database port |
| `DB_NAME` | `petclinic` | Database name |
| `DB_USER` | `petclinic` | Database username |
| `DB_PASSWORD` | `petclinic` | Database password |

## Development

### Prerequisites
- Java 17+ (JDK)
- Docker (for database/deployment)
- Git

### Testing
```bash
# Unit tests
./mvnw test

# Integration tests with Testcontainers
./mvnw test -Dtest="*IntegrationTests"

# All tests with coverage
./mvnw clean test jacoco:report
```

### Building
```bash
# JAR file
./mvnw clean package

# Docker image
./mvnw spring-boot:build-image
```

## Why This Matters

This project demonstrates:
- **Jenkins CI/CD Mastery**: Complete pipeline implementation with quality gates
- **DevOps Best Practices**: Automated testing, static analysis, and deployment
- **Production-Ready Pipeline**: Real-world CI/CD workflow with Docker integration
- **Quality Automation**: Enforced code standards and comprehensive testing
- **Modern Toolchain**: Jenkins, Maven, Docker, Testcontainers, quality tools

Perfect for showcasing **Jenkins CI/CD pipeline skills** with a real Java application.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

Licensed under the [Apache License 2.0](LICENSE.txt).
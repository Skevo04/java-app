# ADR-001: Multi-Database Support with Spring Profiles

## Status
Accepted

## Context
The application needs to support multiple database environments:
- Development: Fast startup, no external dependencies
- Testing: Isolated, repeatable tests
- Production: Persistent, scalable storage

## Decision
Implement multi-database support using Spring profiles:
- **Default/H2**: In-memory database for development and demos
- **MySQL**: Production-ready RDBMS option
- **PostgreSQL**: Alternative production database
- **Testcontainers**: Integration testing with real databases

## Consequences

### Positive
- Zero-setup development experience
- Production database flexibility
- Realistic integration testing
- Easy environment switching

### Negative
- Additional configuration complexity
- Multiple database schemas to maintain
- Profile-specific testing required

## Implementation
- Spring profiles: `default`, `mysql`, `postgres`
- JPA/Hibernate for database abstraction
- Testcontainers for integration tests
- Docker Compose for local multi-service setup
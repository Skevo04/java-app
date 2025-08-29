# Contributing to Spring PetClinic

## Development Workflow

### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical production fixes

### Pull Request Process
1. Fork the repository
2. Create feature branch from `main`
3. Make changes with tests
4. Ensure all quality gates pass:
   ```bash
   ./mvnw clean test spotbugs:check
   ```
5. Submit PR with clear description

### Code Standards
- Follow Spring Java Format (enforced by Maven plugin)
- Write tests for new functionality
- Update documentation for API changes
- No Checkstyle violations
- No SpotBugs high/medium issues

### Commit Messages
```
type: brief description

Longer explanation if needed

Fixes #123
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`

### Testing Requirements
- Unit tests for business logic
- Integration tests for database operations
- Testcontainers for external dependencies
- Minimum 80% code coverage

All commits must include a **Signed-off-by** trailer:
```bash
git commit -s -m "feat: add new feature"
```
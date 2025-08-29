#!/bin/bash
set -e

echo "🔍 Verifying Spring PetClinic Setup..."

# Check Java version
echo "✅ Java Version:"
java -version

# Check if Maven wrapper exists
if [ -f "./mvnw" ]; then
    echo "✅ Maven wrapper found"
else
    echo "❌ Maven wrapper not found"
    exit 1
fi

# Check if Jenkinsfile exists
if [ -f "./Jenkinsfile" ]; then
    echo "✅ Jenkins pipeline configuration found"
else
    echo "❌ Jenkinsfile not found"
    exit 1
fi

# Check if Docker files exist
if [ -f "./Dockerfile" ] && [ -f "./docker-compose.yml" ]; then
    echo "✅ Docker configuration found"
else
    echo "❌ Docker configuration incomplete"
    exit 1
fi

# Verify project structure
echo "✅ Project Structure:"
echo "  📁 src/main/java - $(find src/main/java -name "*.java" | wc -l) Java files"
echo "  📁 src/test/java - $(find src/test/java -name "*.java" | wc -l) Test files"
echo "  📁 k8s - Kubernetes manifests"
echo "  📁 docs/adr - Architecture decisions"

echo ""
echo "🎉 Setup verification complete!"
echo "🚀 Ready for development and CI/CD!"
echo ""
echo "Next steps:"
echo "  • Run: ./mvnw spring-boot:run"
echo "  • Access: http://localhost:8080"
echo "  • Jenkins: Configure pipeline with Jenkinsfile"
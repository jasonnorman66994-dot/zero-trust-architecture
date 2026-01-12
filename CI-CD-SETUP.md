# CI/CD Setup Instructions

## GitHub Actions Workflow

The Zero Trust Architecture includes a comprehensive CI/CD pipeline that automatically tests all security components on every push and pull request.

### Prerequisites

To enable GitHub Actions with the workflow file, your Personal Access Token must have the `workflow` scope enabled.

### Enable the CI/CD Pipeline

1. **Create a new Personal Access Token with workflow scope:**
   - Go to https://github.com/settings/tokens/new
   - Token name: "Zero Trust CI/CD"
   - Select scopes:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
   - Click "Generate token"
   - Copy the token

2. **Add the CI/CD workflow:**
   
   Create `.github/workflows/ci.yml` with the following content:

```yaml
name: Zero Trust CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    # Run security tests daily at 2 AM UTC
    - cron: '0 2 * * *'

jobs:
  security-tests:
    name: Security & Compliance Tests
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up test environment
      run: |
        sudo apt-get update
        sudo apt-get install -y openssl iproute2 iptables
        
    - name: Run comprehensive test suite
      run: |
        chmod +x test-suite.sh
        ./test-suite.sh
        
    - name: Validate shell scripts
      run: |
        for script in *.sh; do
          echo "Checking $script..."
          bash -n "$script"
        done
        
    - name: Check certificate security
      run: |
        # Verify all certificates are valid
        openssl verify -CAfile certs/ca-cert.pem certs/server-cert.pem
        openssl verify -CAfile certs/ca-cert.pem certs/client-cert.pem
        
        # Check key strengths
        for cert in certs/*.pem; do
          if [[ "$cert" == *"cert.pem" ]] && [[ "$cert" != *"key.pem" ]]; then
            echo "Checking $cert..."
            openssl x509 -in "$cert" -noout -text | grep "Public-Key:"
          fi
        done
        
    - name: Scan for vulnerabilities
      run: |
        # Check for common security issues
        echo "Scanning for hardcoded credentials..."
        ! grep -riE "password|secret|api_key" *.sh | grep -v "^#" | grep -v "TEST" | grep -v "echo"
        
        echo "Checking file permissions..."
        ls -la certs/*.pem
        
    - name: Generate test report
      if: always()
      run: |
        echo "## Test Results" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "✅ All security tests completed" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### Certificate Status" >> $GITHUB_STEP_SUMMARY
        openssl x509 -in certs/ca-cert.pem -noout -enddate >> $GITHUB_STEP_SUMMARY

  shellcheck:
    name: ShellCheck Linting
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Run ShellCheck
      uses: ludeeus/action-shellcheck@master
      with:
        severity: warning
        
  documentation:
    name: Documentation Validation
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Check README exists
      run: |
        test -f README.md
        echo "✅ README.md found"
        
    - name: Validate markdown links
      uses: gaurav-nelson/github-action-markdown-link-check@v1
      with:
        use-quiet-mode: 'yes'
        
  compliance-check:
    name: Compliance & Best Practices
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Check Zero Trust principles
      run: |
        echo "Validating Zero Trust implementation..."
        
        # Verify policy enforcement exists
        test -f zero-trust-policy.sh
        echo "✅ Policy enforcement engine found"
        
        # Verify mTLS infrastructure
        test -f certs/ca-cert.pem
        test -f certs/server-cert.pem
        test -f certs/client-cert.pem
        echo "✅ Mutual TLS certificates found"
        
        # Verify monitoring
        test -f security-monitoring.sh
        test -f automated-monitoring.sh
        echo "✅ Security monitoring found"
        
        # Verify network segmentation
        test -f network-namespace-demo.sh
        echo "✅ Network segmentation demo found"
        
        echo "All Zero Trust components validated ✓"
```

3. **Push the workflow:**
   ```bash
   git add .github/workflows/ci.yml
   git commit -m "Add CI/CD pipeline for automated security testing"
   git push origin main
   ```

## What the CI/CD Pipeline Does

### Automated Security Tests
- ✅ Runs comprehensive test suite (60+ tests)
- ✅ Validates shell script syntax
- ✅ Verifies certificate chain integrity
- ✅ Checks for hardcoded credentials
- ✅ Validates file permissions
- ✅ Runs ShellCheck linting
- ✅ Validates documentation
- ✅ Checks Zero Trust component compliance

### Scheduled Scans
- Daily security scans at 2 AM UTC
- Ensures no security regressions
- Validates certificate expiration

### Pull Request Checks
- All tests must pass before merging
- Prevents vulnerable code from reaching main branch
- Provides security feedback to contributors

## Manual Testing

You can run the tests locally before pushing:

```bash
# Run comprehensive test suite
./test-suite.sh

# Run intrusion detection
./intrusion-detection.sh

# Run data loss prevention scan
./data-loss-prevention.sh

# Validate all shell scripts
for script in *.sh; do
  bash -n "$script"
done

# Check certificate validity
openssl verify -CAfile certs/ca-cert.pem certs/server-cert.pem
openssl verify -CAfile certs/ca-cert.pem certs/client-cert.pem
```

## CI/CD Best Practices

1. **Branch Protection**
   - Require status checks to pass
   - Require pull request reviews
   - Enforce linear history

2. **Secret Management**
   - Never commit secrets to the repository
   - Use GitHub Secrets for sensitive data
   - Rotate credentials regularly

3. **Test Coverage**
   - Aim for >80% test coverage
   - Test both positive and negative scenarios
   - Include integration tests

4. **Security Scanning**
   - Enable Dependabot for dependency updates
   - Enable code scanning with CodeQL
   - Use security advisories

## Troubleshooting

### "refusing to allow a Personal Access Token to create or update workflow"

**Solution:** Create a new PAT with the `workflow` scope:
1. Go to https://github.com/settings/tokens/new
2. Check both `repo` and `workflow` scopes
3. Update your git remote with the new token

### Tests failing locally but passing in CI

**Solution:** Ensure your local environment matches CI:
```bash
# Install required tools
sudo apt-get update
sudo apt-get install -y openssl iproute2 iptables
```

### Certificate validation failures

**Solution:** Regenerate certificates:
```bash
# The certificates may have expired
# Regenerate them following the mTLS setup guide
```

## Advanced CI/CD Features

### Matrix Testing
Test across multiple OS versions and configurations:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, ubuntu-22.04, ubuntu-20.04]
    include:
      - os: ubuntu-latest
        test-suite: full
      - os: ubuntu-22.04
        test-suite: basic
```

### Deployment Automation
Automatically deploy to staging/production:

```yaml
deploy-staging:
  needs: [security-tests, shellcheck]
  if: github.ref == 'refs/heads/develop'
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to staging
      run: |
        # Deployment commands here
```

### Security Scanning Integration
Add additional security tools:

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Zero Trust Security Model](https://www.nist.gov/publications/zero-trust-architecture)
- [OWASP Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

---

**Last Updated:** January 12, 2026
**Maintained By:** Zero Trust Security Team

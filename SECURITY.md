# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in ATS Exporter, please report it by emailing lwnmengjing@gmail.com.

**Please do not report security vulnerabilities through public GitHub issues.**

### What to Include

When reporting a vulnerability, please include:

- Description of the vulnerability
- Steps to reproduce the issue
- Affected versions
- Potential impact
- Possible fixes (if you have any)

### Response Timeline

- We will acknowledge your report within 48 hours
- We will provide a detailed response within 7 days
- We will work on a fix and release it as soon as possible
- We will notify you when the fix is released

### Disclosure Policy

- We ask that you give us reasonable time to fix the issue before publishing it
- We will credit you in the security advisory (unless you prefer to remain anonymous)

## Security Best Practices

When using ATS Exporter:

1. **Network Security**: Run the exporter behind a firewall or VPN. The metrics endpoint should not be exposed to the public internet.

2. **Authentication**: Consider using a reverse proxy (like nginx) with authentication to protect the metrics endpoint.

3. **ATS Endpoint**: Ensure your ATS stats endpoint (`/_stats`) is properly secured and only accessible by the exporter.

4. **Updates**: Keep the exporter updated to the latest version to receive security fixes.

5. **Configuration**: Use appropriate log levels. Debug logs may expose sensitive information in production.

## Security Features

ATS Exporter includes:

- Graceful shutdown handling to prevent data corruption
- Timeout protection for ATS scraping to prevent hanging
- Structured logging with configurable levels
- No sensitive data storage (metrics are ephemeral)
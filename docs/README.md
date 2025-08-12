y# 📚 SAST Platform Documentation

Welcome to the comprehensive documentation for the Universal SAST (Static Application Security Testing) Platform.

## 🚀 Quick Start

New to SAST? Start here:

1. **[Main README](../README.md)** - Overview and quick setup
2. **[Architecture Overview](ARCHITECTURE.md)** - Understanding the system
3. **[Configuration Guide](CONFIG_GUIDE.md)** - Detailed configuration options
4. **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions

## 📖 Documentation Structure

### Core Documentation
| Document | Purpose | Audience |
|----------|---------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical architecture and design principles | Developers, DevOps |
| [CONFIG_GUIDE.md](CONFIG_GUIDE.md) | Complete configuration reference | All users |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Issue resolution and support | All users |

### Setup Guides
| Guide | Purpose | Use Case |
|-------|---------|----------|
| [GitHub Pages Setup](guides/github-pages-setup.md) | Deploy security dashboard | Teams wanting public dashboards |
| [Enterprise Setup](guides/enterprise-setup.md) | Large organization deployment | Enterprise environments |
| [Email Setup](guides/email-setup.md) | Configure notification system | Teams needing alerts |

### Additional Resources
| Resource | Description |
|----------|-------------|
| [Demo Data](data.json) | Sample data for testing |
| [Interactive Dashboard](index.html) | Live demo dashboard |
| [Enterprise Dashboard](enterprise-dashboard.html) | Enterprise demo |

## 🎯 Getting Started by Role

### Developers
1. Clone repository and run `./setup.sh --demo`
2. Review [Configuration Guide](CONFIG_GUIDE.md) for customization
3. Check [Troubleshooting](TROUBLESHOOTING.md) for common issues

### DevOps Engineers  
1. Review [Architecture Overview](ARCHITECTURE.md)
2. Plan deployment using [Enterprise Setup](guides/enterprise-setup.md)
3. Configure monitoring and alerts

### Security Teams
1. Understand scanner capabilities in [Main README](../README.md)
2. Configure compliance requirements using [Configuration Guide](CONFIG_GUIDE.md)
3. Set up enterprise dashboards with [GitHub Pages Setup](guides/github-pages-setup.md)

### Management
1. View [Live Demo Dashboard](https://mar23-lab.github.io/SAST)
2. Review business benefits in [Main README](../README.md)
3. Plan enterprise rollout with [Enterprise Setup](guides/enterprise-setup.md)

## 🔧 Platform Capabilities

### SAST Scanners
- **CodeQL**: GitHub's semantic analysis
- **Semgrep**: Fast pattern-based scanning
- **Bandit**: Python security linter
- **ESLint**: JavaScript/TypeScript security

### Monitoring & Dashboards
- **Grafana**: Real-time security dashboards
- **InfluxDB**: Time-series metrics storage
- **Prometheus**: Metrics collection and alerting

### Integrations
- **GitHub Actions**: Native CI/CD workflows
- **Slack**: Real-time notifications
- **Jira**: Automatic ticket creation
- **Email**: SMTP notification system

## 📊 Quick Reference

### Essential Commands
```bash
# Quick setup
./setup.sh --demo

# Production deployment
./setup.sh --production

# Project initialization
./sast-init.sh --interactive

# Run demo scan
./run_demo.sh
```

### Key Configuration Files
- **ci-config.yaml** - Master configuration
- **docker-compose.yml** - Full monitoring stack
- **docker-compose-minimal.yml** - Essential services only

### Important URLs (after setup)
- **Grafana Dashboard**: http://localhost:3001
- **InfluxDB UI**: http://localhost:8087
- **Prometheus**: http://localhost:9090
- **Email Testing**: http://localhost:8025

## 🆘 Getting Help

### Documentation Issues
1. Check [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review [Configuration Guide](CONFIG_GUIDE.md)
3. Search [GitHub Issues](https://github.com/mar23-lab/SAST/issues)

### Community Support
- **GitHub Discussions**: Ask questions and share solutions
- **Issue Tracker**: Report bugs and request features
- **Documentation**: Contribute improvements

### Enterprise Support
- **Professional Services**: Implementation assistance
- **Training Programs**: Team education
- **Custom Development**: Tailored solutions

## 🔄 Keep Updated

- **Star the repository** for updates
- **Watch releases** for new features
- **Follow documentation** for best practices
- **Contribute feedback** for improvements

---

**🎯 Ready to secure your applications?** Choose your path above and start building enterprise-grade security into your development workflow today!
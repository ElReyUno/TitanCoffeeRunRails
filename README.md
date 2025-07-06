# TitanCoffeeRunRails

[![Ruby](https://img.shields.io/badge/Ruby-3.3.6-red?logo=ruby)](https://www.ruby-lang.org/) [![Rails](https://img.shields.io/badge/Rails-8.0.0-red?logo=rubyonrails)](https://rubyonrails.org/) [![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Table of Contents
- [Overview](#titancoffeerunrails)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Requirements](#requirements)
- [Setup Instructions](#setup-instructions)
- [Development Tools](#development-tools)
- [Deployment](#deployment)
- [Architecture Notes](#architecture-notes)
- [Key Files](#key-files)
- [License](#license)

## Overview

TitanCoffeeRunRails is a Ruby on Rails web application designed to manage and streamline group coffee runs for teams or organizations. It allows users to create coffee runs, join orders, and track deliveries efficiently.

## Tech Stack

- **Ruby:** 3.3.6
- **Rails:** 8.0.0
- **Database:** SQLite3 (all environments with multi-database setup)
- **Frontend:** Hotwire (Turbo + Stimulus), Import Maps
- **Asset Pipeline:** Propshaft
- **Web Server:** Puma
- **Background Jobs:** Solid Queue
- **Caching:** Solid Cache
- **WebSockets:** Solid Cable
- **Deployment:** Kamal with Docker
- **HTTP Acceleration:** Thruster

## Features

- PWA support with service worker and manifest
- Modern Rails 8 architecture with Solid gems
- Docker-based deployment with Kamal
- Multi-database setup (primary, cache, queue, cable)
- Import maps for JavaScript management (no Node.js/Yarn required)
- Code quality tools (RuboCop, Brakeman)
- System testing with Capybara and Selenium

## Requirements

- **Ruby:** 3.3.6 (see `.ruby-version`)
- **Rails:** 8.0.0
- **Database:** SQLite3 2.1+
- **Docker:** For deployment (optional for development)

## Setup Instructions

### Quick Start (Recommended)

Use the automated setup script for the easiest installation:

```bash
./scripts/runRails.sh
```

The script will automatically:
- ✅ Check and install Ruby 3.3.6 (via rbenv if available)
- ✅ Install bundler and dependencies
- ✅ Set up all databases (primary, cache, queue, cable)
- ✅ Run optional tests and code quality checks
- ✅ Launch the Rails server

### Manual Setup

If you prefer manual setup or need to troubleshoot:

1. **Clone the repository:**

   ```bash
   git clone <repo-url>
   cd TitanCoffeeRunRails
   ```

2. **Install dependencies:**

   ```bash
   bundle install
   ```

3. **Database setup:**

   ```bash
   rails db:setup
   # This sets up multiple databases: primary, cache, queue, and cable
   ```

4. **Run the server:**

   ```bash
   rails server
   ```

5. **Access the app:**

   Visit [http://localhost:3000](http://localhost:3000)

## Development Tools

**Run tests:**
```bash
rails test
```

**Code quality checks:**
```bash
bin/rubocop    # Ruby style guide
bin/brakeman   # Security analysis
```

**Background jobs:**
Solid Queue runs in-process with Puma by default (see `SOLID_QUEUE_IN_PUMA=true`)

## Deployment

This app uses **Kamal** for Docker-based deployment:

```bash
bin/kamal setup    # Initial deployment
bin/kamal deploy   # Deploy updates
bin/kamal console  # Access Rails console
bin/kamal logs     # View logs
```

**Configuration:**
- Edit `config/deploy.yml` for deployment settings
- Set secrets in `.kamal/secrets`
- Uses SQLite with persistent Docker volumes
- SSL termination via proxy with Let's Encrypt

## Architecture Notes

- **PWA:** Manifest and service worker in `app/views/pwa/`
- **Assets:** Managed by Propshaft (modern Rails asset pipeline)
- **JavaScript:** Import maps eliminate need for Node.js/bundling
- **Multi-DB:** Separate SQLite databases for different concerns
- **Solid Stack:** Uses Rails 8's new Solid gems for queue, cache, and cable
- **Docker:** Containerized with Kamal for simple deployment

## Key Files

- `scripts/runRails.sh` - Automated setup and launch script
- `config/deploy.yml` - Kamal deployment configuration
- `config/importmap.rb` - JavaScript import maps
- `app/views/pwa/` - Progressive Web App files
- `.rubocop.yml` - Ruby style configuration

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Built with Rails 8 and the modern Hotwire + Solid stack.

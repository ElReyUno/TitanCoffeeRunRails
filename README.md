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

## Project Architecture & Integration

### Frontend to Rails Migration

This project integrates an existing JavaScript/HTML/CSS coffee run frontend into a Rails 8 application using Rails-first best practices. The integration transforms a localStorage-based client-side application into a full-stack Rails web application.

### Core Architecture Decisions

**Authentication & Authorization:**
- **Devise** - Industry standard authentication gem
- **Pundit** - Policy-based authorization system
- **Admin Role System** - Database-backed user permissions

**Frontend Stack:**
- **Turbo + Stimulus** - Rails 8 default Hotwire stack for SPA-like experience
- **Import Maps** - Modern JavaScript management without Node.js
- **Propshaft** - Rails 8 asset pipeline for CSS/JS/images
- **ViewComponent** - Reusable UI components (planned enhancement)

**Database Design:**
- **PostgreSQL Ready** - JSON fields for flexible data storage
- **Multi-Model Structure** - User, Product, Order, OrderItem associations
- **Enum-based Status** - Order lifecycle management
- **Calculated Fields** - Automatic total and subtotal computation

**Backend Services:**
- **Solid Queue** - Background job processing
- **Solid Cache** - High-performance caching
- **Solid Cable** - WebSocket support for real-time features
- **Action Mailer** - Email notifications for orders

### Data Model Transformation

**From localStorage to Database:**
- **User Authentication** - localStorage → Devise with encrypted passwords
- **Product Catalog** - Hardcoded JavaScript → Active Record models
- **Shopping Cart** - Client-side storage → Session-based persistence
- **Order Management** - Temporary data → Persistent order history
- **Admin Analytics** - Static charts → Dynamic database queries

**Enhanced Features:**
- **Order Status Tracking** - Pending → Confirmed → Preparing → Ready → Completed
- **Donation Integration** - Optional Titan Fund contributions
- **Audit Trail** - Created/updated timestamps for all entities
- **User Profiles** - Expandable user data beyond basic authentication

### API & Integration Points

**JSON API Endpoints:**
- `/api/v1/cart_items` - AJAX cart management
- `/api/v1/sales` - Admin dashboard data feeds
- **Chart.js Integration** - Sales analytics visualization
- **Turbo Streams** - Real-time order status updates

**External Services Ready:**
- **Payment Gateway Integration** - Stripe/PayPal API placeholder
- **Email Service** - SendGrid/Mailgun for notifications
- **SMS Notifications** - Twilio integration for order updates
- **Image Storage** - Active Storage for product photos

### Security & Performance

**Security Measures:**
- **CSRF Protection** - Rails built-in token validation
- **Parameter Filtering** - Sensitive data logging prevention
- **SQL Injection Prevention** - Active Record query parameterization
- **XSS Protection** - ERB template escaping by default

**Performance Optimizations:**
- **Database Indexing** - Foreign keys and frequently queried fields
- **Eager Loading** - Includes for N+1 query prevention
- **Fragment Caching** - Product listings and static content
- **Background Processing** - Email delivery and heavy computations

### Testing Strategy

**Test Coverage:**
- **Model Tests** - Validations, associations, business logic
- **Controller Tests** - Authentication, authorization, response formats
- **System Tests** - End-to-end user workflows with Capybara
- **Integration Tests** - API endpoints and service interactions

**Quality Assurance:**
- **RuboCop** - Ruby style guide enforcement
- **Brakeman** - Security vulnerability scanning
- **SimpleCov** - Code coverage reporting
- **FactoryBot** - Test data generation

### Migration from Frontend Project

**Asset Integration:**
- **CSS Migration** - SCSS organization into Rails asset structure
- **JavaScript Conversion** - Stimulus controllers for interactive elements
- **Image Assets** - Rails asset pipeline optimization
- **Responsive Design** - Mobile-first approach preservation

**Template Conversion:**
- **HTML → ERB** - Server-side rendering with Rails helpers
- **Form Integration** - Rails form helpers with validation
- **Navigation** - Shared layouts with authentication states
- **Error Handling** - Rails flash messages and validation display

### Development Workflow

**Environment Setup:**
- **Docker Support** - Containerized development and deployment
- **Database Seeding** - Sample data for development
- **Environment Variables** - Configuration management
- **Git Hooks** - Pre-commit quality checks

**Deployment Pipeline:**
- **Kamal Integration** - Docker-based production deployment
- **Database Migrations** - Zero-downtime schema updates
- **Asset Precompilation** - Optimized static file delivery
- **Health Checks** - Application monitoring and alerting

## Dependency Management & Non-Destructive Setup

All setup scripts have been designed to be **non-destructive** and **adaptive**, meaning they:

### ✅ Check Before Creating
- **Models**: Validates that model files exist and contain proper class definitions before generating new ones
- **Controllers**: Checks for existing controller files with correct class structures
- **Routes**: Analyzes existing routes and only adds missing ones, with backups
- **Seeds**: Preserves existing seed data and only creates new seeds if none exist
- **Gems**: Detects existing gems in Gemfile and avoids duplicates
- **Database**: Checks for existing databases, schema, and migrations before running commands

### 🔄 Adaptive Behavior
- **Ruby Version**: Uses rbenv if available, falls back to system Ruby, offers installation options
- **Database State**: Adapts to partial/complete/missing database setups
- **Model Errors**: Auto-fixes common Rails version compatibility issues (e.g., enum syntax)
- **Dependencies**: Accepts existing system tools and only installs what's missing

### 🛡️ Safety Features
- **Automatic Backups**: Creates timestamped backups before modifying critical files
- **Error Recovery**: Provides recovery options when operations fail
- **Validation**: Syntax and structure checking before applying changes
- **User Choices**: Prompts for confirmation on potentially destructive operations

### 📋 Dependency Checking Pattern
Each script follows this pattern:
1. **Detect Environment**: Check Ruby, Rails, Bundler versions
2. **Analyze Existing State**: Inventory what's already present
3. **Plan Changes**: Determine what needs to be created/modified
4. **Execute Safely**: Make changes with backups and validation
5. **Verify Results**: Confirm everything works correctly

This ensures you can run the scripts multiple times safely without corrupting existing work.

---

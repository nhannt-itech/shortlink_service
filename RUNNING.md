# Running Instructions

This document explains how to install, run, test, and use the ShortLink Service locally.

## 1) Prerequisites

- Ruby `3.4.7`
- Bundler
- PostgreSQL

Check Ruby version:

```bash
ruby -v
```

Install Bundler if needed:

```bash
gem install bundler
```

## 2) Setup

From repository root:

```bash
bundle install
```

Start PostgreSQL (example for Homebrew):

```bash
brew services start postgresql
```

Create and migrate database:

```bash
bin/rails db:create db:migrate
```

## 3) Start Application

```bash
bin/rails server
```

Base URL:

```text
http://localhost:3000
```

Health check:

```bash
curl -s http://localhost:3000/up
```

## 4) Verify Core Assignment Flow

### Encode

```bash
curl -s -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{"url":"https://codesubmit.io/library/react"}'
```

Expected shape:

```json
{ "short_url": "http://localhost:3000/<code>" }
```

### Decode

Use `<code>` from encode response:

```bash
curl -s -X POST http://localhost:3000/decode \
  -H "Content-Type: application/json" \
  -d '{"code":"<code>"}'
```

Expected shape:

```json
{ "url": "https://codesubmit.io/library/react" }
```

### Optional quick UI for demo

The repository includes a lightweight demo page:

```text
http://localhost:3000/
```

## 5) Run Tests

```bash
bundle exec rspec
```

## 6) OpenAPI / Swagger

Swagger UI:

```text
http://localhost:3000/api-docs
```

Regenerate OpenAPI from specs:

```bash
bundle exec rake rswag:specs:swaggerize
```

Generated file:

```text
swagger/v1/openapi.yaml
```

## 7) Common Errors

### `Bundler::GemNotFound`

```bash
bundle install
```

### `ActiveRecord::NoDatabaseError`

```bash
bin/rails db:create db:migrate
```

### `PG::ConnectionBad`

Ensure PostgreSQL is running and accessible by your local user.

### OpenAPI not updated after spec changes

```bash
bundle exec rake rswag:specs:swaggerize
```

# Running Instructions

This document explains how to install, run, test, and use the ShortLink Service locally.

## Prerequisites

Install the following before running the application:

- Ruby `3.4.7`
- Bundler
- PostgreSQL
- Git

Check Ruby version:

```bash
ruby -v
```

Expected major version:

```text
ruby 3.4.7
```

If Bundler is missing, install it with:

```bash
gem install bundler
```

## 1. Install Dependencies

From the project root:

```bash
bundle install
```

If the `pg` gem fails to build on macOS, make sure PostgreSQL is installed and available on your `PATH`. With Homebrew, this is usually:

```bash
brew install postgresql
```

## 2. Start PostgreSQL

If PostgreSQL is installed through Homebrew:

```bash
brew services start postgresql
```

If you already manage PostgreSQL another way, make sure it is running and that your local user can create databases.

The development database name is:

```text
shortlink_service_development
```

The test database name is:

```text
shortlink_service_test
```

## 3. Prepare the Database

Create and migrate the development and test databases:

```bash
bin/rails db:create db:migrate
RAILS_ENV=test bin/rails db:migrate
```

Alternatively, Rails can prepare the test database automatically when running the test suite.

## 4. Run the API

Start the Rails server:

```bash
bin/rails server
```

The API will be available at:

```text
http://localhost:3000
```

Health check:

```bash
curl http://localhost:3000/up
```

## 5. Use the API

### Encode a URL

Request:

```bash
curl -s -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{"url":"https://codesubmit.io/library/react"}'
```

Example response:

```json
{
  "short_url": "http://localhost:3000/00aB12"
}
```

The code is the final path segment of the returned `short_url`. In this example, the code is:

```text
00aB12
```

### Decode a Code

Request:

```bash
curl -s -X POST http://localhost:3000/decode \
  -H "Content-Type: application/json" \
  -d '{"code":"00aB12"}'
```

Example response:

```json
{
  "url": "https://codesubmit.io/library/react"
}
```

### Validation Error Example

Request:

```bash
curl -s -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{"url":"ftp://example.com/file.txt"}'
```

Example response:

```json
{
  "errors": {
    "url": [
      "must be a valid http/https URL"
    ]
  }
}
```

### Not Found Example

Request:

```bash
curl -s -X POST http://localhost:3000/decode \
  -H "Content-Type: application/json" \
  -d '{"code":"ABC123"}'
```

Example response:

```json
{
  "error": "Not Found"
}
```

## 6. Open API Documentation

Start the server and open:

```text
http://localhost:3000/api-docs
```

The static OpenAPI document is generated at:

```text
swagger/v1/openapi.yaml
```

Regenerate OpenAPI documentation from request specs:

```bash
bundle exec rake rswag:specs:swaggerize
```

## 7. Run Tests

Run the full test suite:

```bash
bundle exec rspec
```

Run only the ShortLinks integration specs:

```bash
bundle exec rspec spec/integration/short_links_spec.rb
```

The integration specs verify the main assignment requirements:

- `/encode` returns a short URL.
- repeated normalized URLs return the same short URL.
- invalid URLs return validation errors.
- `/decode` returns the original URL for a valid code.
- unknown codes return `404`.
- invalid or missing parameters return `422`.

## 8. Run Static Checks

Run RuboCop:

```bash
RUBOCOP_CACHE_ROOT=tmp/rubocop bin/rubocop
```

Run Brakeman security analysis:

```bash
bundle exec brakeman
```

Run Bundler Audit:

```bash
bundle exec bundler-audit check --update
```

## 9. Useful Environment Variables

### `DATABASE_URL`

Used by Rails in production to connect to PostgreSQL.

Example:

```bash
DATABASE_URL=postgres://user:password@host:5432/shortlink_service_production
```

### `RAILS_MASTER_KEY`

Required for production credentials when running a production build.

Example:

```bash
RAILS_MASTER_KEY=your_master_key
```

### `RAILS_LOG_LEVEL`

Controls Rails logging verbosity in production.

Example:

```bash
RAILS_LOG_LEVEL=info
```

### `SHORT_LINK_CACHE_TTL_SECONDS`

Controls decode cache TTL. Defaults to one day.

Example:

```bash
SHORT_LINK_CACHE_TTL_SECONDS=3600
```

## 10. Production Notes

The application includes a production-oriented Dockerfile. A simple build command is:

```bash
docker build -t shortlink_service .
```

Example run command:

```bash
docker run -p 80:80 \
  -e RAILS_MASTER_KEY=your_master_key \
  -e DATABASE_URL=postgres://user:password@host:5432/shortlink_service_production \
  shortlink_service
```

For a real deployment, also configure:

- A managed PostgreSQL database.
- HTTPS at the load balancer or reverse proxy.
- Host authorization for the production domain.
- Request rate limiting.
- Centralized logs and error monitoring.

## Troubleshooting

### `ActiveRecord::NoDatabaseError`

Create the database:

```bash
bin/rails db:create
```

### `PG::ConnectionBad`

PostgreSQL is not running or Rails cannot connect to it. Start PostgreSQL and verify your local database credentials.

### `Bundler::GemNotFound`

Install dependencies:

```bash
bundle install
```

### Swagger still points to localhost

Regenerate the OpenAPI file after changes:

```bash
bundle exec rake rswag:specs:swaggerize
```

The source configuration is in:

```text
spec/swagger_helper.rb
```

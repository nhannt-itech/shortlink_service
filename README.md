# ShortLink Service

ShortLink Service is a Ruby on Rails JSON API that converts long URLs into short URLs and decodes short codes back to their original URLs. It is built for the Oivan assignment requirements with persistent storage, request validation, integration tests, and generated OpenAPI documentation.

The service deliberately keeps the API small:

- `POST /encode` accepts a long URL and returns a short URL.
- `POST /decode` accepts a short code and returns the original URL.
- Encoded links survive application restarts because they are stored in PostgreSQL.

Detailed setup and execution steps are available in [`RUNNING.md`](RUNNING.md).

## Assignment Coverage

This implementation covers the requested behavior:

- Ruby implementation using Rails API mode.
- JSON endpoints for `/encode` and `/decode`.
- PostgreSQL-backed persistence for restart-safe decoding.
- Tests for success and error scenarios through Rswag request specs.
- OpenAPI documentation generated from the request specs.
- Documented security considerations and scalability strategy.

## Technology Stack

- Ruby `3.4.7`
- Rails `8.1`
- PostgreSQL
- Dry Validation for request contracts
- Addressable for URL normalization
- RSpec and Rswag for API tests and OpenAPI generation
- Rails cache for decode-path caching

## API Contract

### `POST /encode`

Encodes an absolute HTTP or HTTPS URL.

Request:

```json
{
  "url": "https://codesubmit.io/library/react"
}
```

Success response (`200`):

```json
{
  "short_url": "http://localhost:3000/00aB12"
}
```

Validation error response (`422`):

```json
{
  "errors": {
    "url": [
      "must be a valid http/https URL"
    ]
  }
}
```

Behavior notes:

- Only absolute `http` and `https` URLs are accepted.
- Input URLs are normalized before storage.
- Re-encoding the same normalized URL returns the same short URL.
- The returned short URL uses the request host, so production responses use the production domain.

### `POST /decode`

Decodes a short code into the original URL. The code is the final path segment from the `short_url` returned by `/encode`.

Request:

```json
{
  "code": "00aB12"
}
```

Success response (`200`):

```json
{
  "url": "https://codesubmit.io/library/react"
}
```

Unknown code response (`404`):

```json
{
  "error": "Not Found"
}
```

Validation error response (`422`):

```json
{
  "errors": {
    "code": [
      "must contain only alphanumeric characters"
    ]
  }
}
```

Behavior notes:

- Codes must be alphanumeric.
- Codes are limited to a small maximum length to reject obviously invalid input early.
- Successful decode results are cached by code to reduce repeated database reads.

## OpenAPI Documentation

Interactive documentation is mounted at:

```text
GET /api-docs
```

The generated OpenAPI file is:

```text
swagger/v1/openapi.yaml
```

Regenerate it from the request specs with:

```bash
bundle exec rake rswag:specs:swaggerize
```

The OpenAPI document intentionally uses relative paths instead of a hardcoded `localhost:3000` server, so the Swagger UI works correctly in local and production environments.

## Architecture

The application is organized around thin controllers and explicit service objects.

### Request Flow

1. `ShortLinksController` receives JSON requests for `/encode` or `/decode`.
2. `ApiValidatable` runs the appropriate Dry Validation contract.
3. The controller delegates business logic to a service object.
4. The service returns a `ShortLink` model.
5. The controller renders a small JSON response.

### Key Components

- `app/controllers/short_links_controller.rb`
  - Handles HTTP orchestration only.
  - Does not contain persistence or encoding logic.

- `app/contracts/short_links/encode_contract.rb`
  - Requires a non-empty `url`.
  - Enforces a maximum URL length.
  - Accepts only absolute `http` and `https` URLs.

- `app/contracts/short_links/decode_contract.rb`
  - Requires a non-empty `code`.
  - Allows only alphanumeric short codes.
  - Limits code length.

- `app/services/short_links/encode_service.rb`
  - Normalizes the submitted URL.
  - Reuses an existing record when the normalized URL already exists.
  - Creates a new record using a database sequence-backed ID.
  - Handles race conditions by retrying lookup after unique constraint conflicts.

- `app/services/short_links/decode_service.rb`
  - Checks the decode cache first.
  - Decodes the short code into the expected record ID.
  - Looks up the persisted record by both `id` and `code`.
  - Writes successful database lookups back to cache.

- `app/lib/short_links/short_code_codec.rb`
  - Converts internal IDs into public short codes.
  - Applies reversible ID obfuscation before Base62 encoding.
  - Pads codes to a minimum length for a consistent public format.

- `app/models/short_link.rb`
  - Stores `original_url` and `code`.
  - Enforces model-level validations.
  - Builds short URLs from the incoming request base URL.

## Persistence Model

The `short_links` table stores:

- `original_url`: the normalized original URL.
- `code`: the public short code.
- Rails timestamps.

Database indexes enforce uniqueness for:

- `original_url`
- `code`

These database constraints are the final source of truth for correctness under concurrent requests.

## Short Code Strategy

The implementation avoids random code generation. Instead, it generates codes deterministically from database IDs:

1. PostgreSQL allocates a unique record ID.
2. The ID is obfuscated to avoid exposing raw sequential IDs.
3. The obfuscated value is encoded with Base62.
4. The code is padded to a minimum length.

This approach has two important benefits:

- It removes the normal random-code collision retry loop.
- It allows decode to calculate the expected ID from the code and perform a direct lookup.

The database still has a unique index on `code` as a safety net.

## Caching

Decode results are cached through `Rails.cache`.

Current behavior:

- Cache key: short code.
- Cache value: a small payload containing `id`, `code`, and `original_url`.
- Default TTL: `1.day`.
- TTL override: `SHORT_LINK_CACHE_TTL_SECONDS`.

Caching is intentionally scoped to decode because decode requests are expected to be read-heavy and repeated more often than encode requests.

## Security Considerations

The assignment asks for potential attack vectors to be considered and documented. The main risks and mitigations are below.

### Server-Side Request Forgery

The service stores URLs but does not fetch or preview them. This avoids the highest-risk SSRF behavior. The encode contract still restricts input to absolute `http` and `https` URLs.

If future functionality fetches target URLs, additional protections should be added:

- Block private, loopback, link-local, and metadata service IP ranges.
- Resolve and validate DNS results before connecting.
- Re-check redirects.
- Apply strict timeouts and response size limits.

### Malformed Input

Both endpoints validate required fields and input shape before service execution.

- URLs must be strings, must be present, and must use an accepted scheme.
- URLs have a maximum length.
- Codes must be alphanumeric and have a maximum length.

Invalid input returns `422` with structured error details.

### Enumeration

Raw database IDs are not exposed directly. IDs are obfuscated before Base62 encoding, which makes codes less predictable than plain sequential IDs.

This is not cryptographic access control. Public short links should still be treated as bearer tokens: anyone with the code can decode it.

### Race Conditions

Concurrent encode requests for the same URL can race. The application handles this at two levels:

- Service logic first attempts to find an existing normalized URL.
- Database unique indexes on `original_url` and `code` enforce integrity if two requests race.

If a unique constraint is hit, the encode service retries by looking up the existing record.

### Abuse and Resource Exhaustion

Potential abuse includes storing many URLs, sending very long payloads, and repeatedly decoding invalid codes. Current mitigations include URL/code length limits, validation before database lookup, and decode caching for successful lookups.

For a production public service, the next recommended controls are:

- Rate limiting by IP or API key.
- Request body size limits at the reverse proxy.
- Abuse monitoring and alerting.
- Optional authentication for administrative or private deployments.

### Cache Safety

The decode cache stores only the data needed to render a response. It does not store secrets. Cache entries expire by TTL and the database remains the source of truth.

## Scalability Considerations

This implementation is intentionally simple for the assignment, but the design leaves clear paths for scaling.

### Database Growth

The critical lookups are indexed:

- Encode idempotency uses `original_url`.
- Decode uses `id` and `code`.

As data grows, PostgreSQL can continue to support this workload with proper indexing, connection pooling, and monitoring.

### Collision Handling

Because codes are derived from unique database IDs, normal random collisions are avoided. This is simpler and more reliable than generating random strings and retrying on collision.

The current obfuscator uses a 32-bit mask. For extremely large scale beyond that range, the codec should be upgraded to a 64-bit obfuscation strategy before the ID space is exhausted.

### Horizontal Scaling

Multiple application instances can run safely because:

- IDs are allocated by PostgreSQL.
- Uniqueness is enforced by the database.
- The service is stateless apart from database and cache dependencies.

For higher traffic, recommended next steps are:

- Use a shared cache such as Redis or Solid Cache instead of per-process memory cache.
- Add rate limiting.
- Add read replicas for decode-heavy traffic.
- Partition or shard by ID range if the table becomes very large.

### Caching Strategy

Decode is a good caching candidate because it is read-heavy and deterministic. Encode remains database-backed to preserve idempotency and keep creation behavior simple.

In a larger deployment, cache invalidation should be extended if short links become editable or deletable. In the current assignment scope, short links are immutable after creation.

## Testing

The request spec suite covers:

- Successful encode.
- Idempotent encode for the same normalized URL.
- URL normalization behavior.
- URL validation errors.
- Successful decode.
- Unknown code handling.
- Invalid code validation.
- Missing required parameters.

Run tests with:

```bash
bundle exec rspec
```

Generate OpenAPI docs from the same specs with:

```bash
bundle exec rake rswag:specs:swaggerize
```

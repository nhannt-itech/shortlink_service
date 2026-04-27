# ShortLink Service

ShortLink Service is a Ruby on Rails JSON API that converts long URLs into short URLs and decodes short codes back to their original URLs. It is built with persistent storage, request validation, integration tests, and generated OpenAPI documentation.

The service deliberately keeps the API small:

- `POST /encode` accepts a long URL and returns a short URL.
- `POST /decode` accepts a short code and returns the original URL.

Detailed setup and execution steps are available in [`RUNNING.md`](RUNNING.md).

## Technology Stack

- Ruby `3.4.7`
- Rails `8.1`
- PostgreSQL
- Dry Validation for request contracts
- Addressable for URL normalization
- RSpec and Rswag for API tests and OpenAPI generation
- Rails cache for decode-path caching

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

### Database Growth

The critical lookups are indexed:

- Encode idempotency uses `original_url`.
- Decode uses `id` and `code`.

As data grows, PostgreSQL can continue to support this workload with proper indexing, connection pooling, and monitoring.

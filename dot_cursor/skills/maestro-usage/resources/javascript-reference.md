# Maestro JavaScript Reference

Complete reference for writing JavaScript in Maestro flows. Maestro JavaScript runs in a sandboxed environment (Rhino or GraalJS) — not Node.js. Many standard JS APIs (`setTimeout`, `fetch`, `require`, `import`) are **not** available. Use the Maestro-provided globals instead.

---

## JavaScript Engines

| Engine | Notes |
|--------|-------|
| `rhino` | Current default. Older, fewer ES6+ features. |
| `graaljs` | Recommended. Better ES6+ support. Set in flow header: `jsEngine: graaljs` |

---

## Running JavaScript

### runScript (from file)

```yaml
- runScript: scripts/setup.js

# With env vars and conditions
- runScript:
    file: scripts/validate.js
    env:
      API_URL: "https://api.example.com"
      MODE: "strict"
    when:
      platform: Android
```

**File paths are relative to the calling flow file**, not the workspace root. This is required for cloud execution.

### evalScript (inline)

For simple one-liners without a separate file:

```yaml
- evalScript: ${output.count = 0}
- evalScript: ${output.name = 'User_' + Date.now()}
```

### ${} injection in YAML

JavaScript expressions can be embedded directly in YAML values:

```yaml
- inputText: ${output.generatedEmail}
- assertTrue: ${output.count > 0}
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: ${output.constants.LONGTIMEOUT}
```

---

## Global Objects & Functions

### `output` — Pass data to the flow

The `output` object persists across the entire flow. Any property you set is accessible in subsequent YAML steps via `${output.propertyName}`.

```javascript
output.email = "test@example.com";
output.userId = 12345;
output.user = { name: "John", token: "abc123" };
```

```yaml
- runScript: scripts/setup.js
- inputText: ${output.email}
- openLink: ${output.user.token}
```

You can also export functions/modules via output:

```javascript
output.api = {
  waitForExecution,
  createUser,
};
```

### `json()` — Parse JSON strings

Maestro's built-in JSON parser. Use instead of `JSON.parse()`.

```javascript
var data = json(response.body);
output.userId = data.id;
output.nested = json(response.body).myField.mySubField;
```

### `console.log()` — Logging

Output appears in the Maestro CLI console. Useful for debugging.

```javascript
console.log("User created: " + email);
console.log("Response: " + JSON.stringify(data));
```

**Limitation:** Only single-argument calls are supported. Don't use `console.log("a", "b")`.

### `maestro` — Built-in variables

| Property | Type | Description |
|----------|------|-------------|
| `maestro.copiedText` | string | Text from the last `copyTextFrom` command |
| `maestro.platform` | string | Current platform: `"ios"` or `"android"` |

```javascript
if (maestro.platform === "ios") {
  output.buttonText = "Allow";
} else {
  output.buttonText = "While using the app";
}
```

### Environment variables

Env vars from `runScript.env` or the flow header `env` are directly accessible as JavaScript variables (no import needed):

```yaml
- runScript:
    file: scripts/setup.js
    env:
      API_URL: "https://api.example.com"
      USER_COUNT: "5"
```

```javascript
// API_URL and USER_COUNT are directly available
var url = API_URL + "/users";
var count = parseInt(USER_COUNT);
```

---

## HTTP API

Maestro provides built-in HTTP functions. These are **synchronous** — they block until the response arrives.

### Methods

| Function | Description |
|----------|-------------|
| `http.get(url, options?)` | GET request |
| `http.post(url, options?)` | POST request |
| `http.put(url, options?)` | PUT request |
| `http.delete(url, options?)` | DELETE request |
| `http.request(url, options?)` | Custom method (specify `method` in options) |

### Request Options

```javascript
{
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + token,
    "Cache-Control": "no-cache"
  },
  body: JSON.stringify({ key: "value" }),
  method: "PATCH"  // only for http.request()
}
```

### Response Object

| Field | Type | Description |
|-------|------|-------------|
| `ok` | boolean | `true` if status is 2xx |
| `status` | int | HTTP status code |
| `body` | string | Response body as string |
| `headers` | object | Response headers (multiple values comma-separated) |

### Examples

**GET request:**

```javascript
var response = http.get("https://api.example.com/users");
if (!response.ok) {
  throw new Error("Failed: " + response.status + " - " + response.body);
}
var users = json(response.body);
output.firstUser = users[0];
```

**POST with JSON body:**

```javascript
var response = http.post("https://api.example.com/users", {
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    email: "test@example.com",
    name: "Test User"
  })
});
var created = json(response.body);
output.userId = created.id;
```

**Custom method (PATCH):**

```javascript
var response = http.request("https://api.example.com/users/123", {
  method: "PATCH",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ name: "Updated" })
});
```

**Multipart form data (file upload):**

```javascript
var response = http.post("https://api.example.com/upload", {
  multipartForm: {
    uploadType: "import",
    data: {
      filePath: "path/to/file.csv",   // required
      mediaType: "text/csv"            // optional
    }
  }
});
```

When `multipartForm` is provided, `body` is ignored.

**GET with cache-busting and custom headers:**

```javascript
var url = BASE_URL + "/api/data?bust_cache=" + Date.now();
var response = http.get(url, {
  headers: {
    "Cache-Control": "no-cache, no-store, must-revalidate",
    "Pragma": "no-cache",
    "Expires": "0"
  }
});
```

---

## Common Patterns

### Polling / waiting for async operations

Maestro JS has no `setTimeout` or `setInterval`. Use a busy-wait loop:

```javascript
function sleep(ms) {
  var start = Date.now();
  while (Date.now() - start < ms) {
    // busy wait
  }
}

function pollUntilReady(url, maxWaitMs, intervalMs) {
  var start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    var resp = http.get(url);
    if (resp.ok) {
      var data = json(resp.body);
      if (data.status === "complete") {
        return data;
      }
    }
    sleep(intervalMs);
  }
  throw new Error("Timed out waiting for " + url);
}
```

### Error handling

Use try/catch at the top level. Throwing an error fails the `runScript` step:

```javascript
try {
  var result = doSomething();
  output.result = result;
} catch (error) {
  output.error = error.message;
  throw error;  // Fails the step
}
```

### Generating unique test data

```javascript
var timestamp = Date.now();
output.email = "test-" + timestamp + "@example.com";
output.username = "user_" + timestamp;
```

### Conditional platform logic

```javascript
if (maestro.platform === "ios") {
  output.permissionButton = "Allow";
} else {
  output.permissionButton = "While using the app";
}
```

```yaml
- runScript: scripts/platformConfig.js
- tapOn: ${output.permissionButton}
```

### Sharing functions across scripts

Export utility functions via `output` in a shared script, then reference them in subsequent scripts:

```javascript
// utils/api.js
function waitForExecution(executionId) {
  // ... implementation
}

output.api = {
  waitForExecution,
};
```

```yaml
- runScript: ../utils/api.js
- runScript: scripts/useApi.js    # Can access output.api.waitForExecution
```

---

## Limitations & Gotchas

| Issue | Details |
|-------|---------|
| No `setTimeout`/`setInterval` | Use busy-wait `sleep()` loops (see above) |
| No `fetch` | Use `http.get()` / `http.post()` etc. |
| No `require` / `import` | Each script is standalone; share data via `output` |
| No `JSON.parse()` in Rhino | Use Maestro's `json()` function |
| No multi-arg `console.log()` | Only `console.log(singleString)` works; concatenate with `+` |
| No `async`/`await` | All HTTP calls are synchronous (blocking) |
| No DOM access | Scripts run outside the app; use Maestro commands to interact with UI |
| Unicode in `inputText` | Not fully supported on Android |
| File paths | Relative to the **calling flow file**, not workspace root |
| `const`/`let` | Use `var` with Rhino engine; `const`/`let` work with GraalJS |

---

## Quick Reference

```javascript
// Globals
output.myVar = "value";              // Pass data to flow (${output.myVar})
json(string);                        // Parse JSON (use instead of JSON.parse)
console.log("message");              // Log to CLI
maestro.copiedText;                  // Last copyTextFrom result
maestro.platform;                    // "ios" or "android"

// HTTP
http.get(url, {headers: {}});
http.post(url, {headers: {}, body: ""});
http.put(url, {headers: {}, body: ""});
http.delete(url, {headers: {}});
http.request(url, {method: "PATCH", headers: {}, body: ""});

// Response
response.ok;       // boolean
response.status;   // int
response.body;     // string
response.headers;  // object

// Env vars — directly accessible by name
var value = MY_ENV_VAR;
```

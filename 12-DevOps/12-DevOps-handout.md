# Lecture 12: From Development to Deployment (DevOps)

## 12.1 From Development to Deployment

### The Core Challenge

Developing software on your laptop is very different from running it in production. Once real users arrive, new problems appear:

- **Stress bugs** — some bugs only surface under heavy load
- **Environment mismatch** — production has different libraries, versions, and configurations than your dev machine
- **Unexpected usage** — users will use your app in ways you never intended
- **Security threats** — the internet is full of attackers and accidental misuse

> "Users are a terrible thing." — a DevOps truism

### The Bad Old Days (c. 2000)

Deploying a web app in the early 2000s meant:

1. Rent a Virtual Private Server (VPS)
2. Install and configure: Linux, Rails, Apache, MySQL, OpenSSL, SSH, firewall, caching proxy, email agent, log rotation...
3. Fall into **Library Hell** (conflicting dependencies)
4. Patch weekly security vulnerabilities
5. Tune every component for performance
6. Figure out horizontal scaling
7. ...and *then* deal with users

### Our View: Stick with PaaS

**Platform as a Service** (e.g., Heroku, Cloud Foundry) handles much of this for you:

| PaaS handles... | App developers handle... |
|---|---|
| "Easy" tiers of horizontal scaling | Minimize database load |
| Component-level performance tuning | Application-level performance (e.g., caching) |
| Infrastructure-level security | Application-level security |

**Is this feasible?** Yes — many SaaS apps are internal or limited-audience.

**Key insight:** The techniques needed to get the most from PaaS are the *same ones* you'd need if doing it yourself.

### Performance & Security Defined

| Category | Metric | Question |
|---|---|---|
| **Performance** | Availability (Uptime) | What % of time is the site up? |
| | Responsiveness | How long after a click does the user get a response? |
| | Scalability | As # users grows, can you maintain responsiveness without increasing cost/user? |
| **Security** | Privacy | Is data access limited to appropriate users? |
| | Authentication | Can we trust users are who they claim to be? |
| | Data integrity | Is sensitive data tamper-evident? |

---

## 12.2 Three-Tier Architecture

### How We Got Here

- **Early web:** pages were just static files on a server
- **Web 1.0 / e-commerce:** needed dynamic content (e.g., shopping carts differ per user)
- **Evolution:** code snippets embedded in HTML templates → code became so complex it moved out of the web server into its own tier

### The Three Tiers

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Presentation    │     │     Logic         │     │   Persistence    │
│  (Web Server)    │────▶│  (App Server)     │────▶│   (Database)     │
│  HTTP requests   │     │  Controller/Model │     │   SQL queries    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

### "Shared Nothing" Architecture

- App server instances **don't share state** with each other
- You can add more app servers without coordination
- The database tier is different: a **primary** handles writes, **read replicas** handle reads

### Development vs. Deployment Hardware

| Environment | Database | App Server | Web Server |
|---|---|---|---|
| **Development** | SQLite (file on disk) | WEBrick | (same process) |
| **Medium-scale** | MySQL | Multiple Puma processes | Nginx (reverse proxy) |
| **Large-scale (Heroku)** | Postgres (replicated) | Heroku Dynos | Cowboy + S3 for static assets |

---

## 12.3 Availability & Responsiveness

### Availability

- Measured as **% uptime** over a time window
- **"Five nines"** = 99.999% uptime ≈ 5 minutes of downtime per year (originally the phone network benchmark)
- A **cluster** achieves higher availability than a single machine (failover)
- A **distributed service** across data centers is even better

**Edge cases:**
- If nobody is accessing the service, does downtime count?
- What if some features work but others don't?

### Why Response Time Matters

| Company | Added Latency | Impact |
|---|---|---|
| Amazon | +100 ms | 1% drop in sales |
| Yahoo! | +400 ms | 5–9% drop in traffic |
| Google | +500 ms | 20% fewer searches |

- **< 100 ms** feels instantaneous
- **> 7 seconds** = users abandon the page

> "Speed is a feature." — Jeff Dean, Google Fellow

### Response Time Distributions

The "average" is misleading. Real response time distributions are **heavily right-skewed** (long tail):

- The **median** is much less than the mean
- The **95th percentile** is far to the right
- Always specify: are you talking about mean, median, or 95th percentile?

### Scalability

For SaaS, scalability means: as users increase, **response time stays the same** and **cost per user stays the same** (or decreases).

### Service Level Objectives (SLOs)

An SLO specifies:
- A **percentile** (e.g., 99%)
- A **target response time** (e.g., < 1 second)
- A **time window** (e.g., over 5 minutes)

**Example:** "99% of requests complete in < 1 sec, measured over a 5-minute window"

An **SLA** (Service Level Agreement) is an SLO with **contractual/legal obligations**.

### Apdex Score

A simplified responsiveness metric. Given a threshold latency **T**:

| Category | Response Time |
|---|---|
| **Satisfactory** | t ≤ T |
| **Tolerable** | T < t ≤ 4T |
| **Frustrating** | t > 4T |

**Formula:**

```
Apdex = (# satisfactory + 0.5 × # tolerable) / total requests
```

- **0.85–0.93** is generally "good"

**Warning — Apdex can hide outliers:**
If a critical action occurs once every 15 clicks but takes 10× as long:
- 14 satisfactory + 0 tolerable out of 15 → Apdex > 0.9
- But users are *miserable* on that critical action!

### What If Your Site Is Slow?

- **Small site:** Overprovision (add more servers). Easy with cloud computing.
- **Large site:** Overprovisioning 10,000 servers by 10% = 1,000 idle computers = expensive!

### Where Does the Time Go?

```
User click → OS/Network → Web Server → App (Controller + Model) → Database →
View Rendering → OS/Network → First byte → Browser rendering → Assets load → JS runs → Done
```

**What you control as a developer:**
1. **App code** (controller & model)
2. **Database access** — use indices, avoid abusive queries
3. **View rendering** — use CSS id/class (fast) not DOM traversal; cache fragments
4. **Embedded assets** — serve from dedicated static asset servers
5. **JavaScript** — load libraries from CDNs with generous expiration

> **Above all: measure before you act!** Don't guess where the bottleneck is.

---

## 12.3 Continuous Integration & Continuous Deployment

### Releases Then vs. Now

| Company | Deploy Frequency |
|---|---|
| Amazon | Several deploys per week |
| Stack Overflow | Multiple deploys per day |
| GitHub | Tens of deploys per day |

**Key insight:** Risk = # of engineer-hours since last deploy. Frequent deploys = less risk per deploy.

### What Makes Deployment Successful?

1. **Automation** — consistent, repeatable deploy process (PaaS provides this; Capistrano for self-hosted)
2. **Continuous Integration (CI)** — automatically test beyond what individual developers do

### Why CI?

- Catches differences between dev and production environments
- Cross-browser / cross-version testing
- Tests SOA integration with flaky remote services
- Stress testing and longevity testing
- **Example:** Salesforce CI runs **150,000+ tests** and auto-opens bug reports on failure

### Continuous Deployment (CD)

```
Push code → CI runs → (if pass) → Auto-deploy
```

- Releases are still useful as **customer-visible milestones**
- Tag commits: `git tag 'happy-hippo' HEAD && git push --tags`

### Example: Setting Up CI with GitHub Actions (MoovOver App)

Let's walk through a concrete example. Suppose you are working on the MoovOver app and want to add a small feature: showing the movie count on the listing page.

**The workflow:**

```
1. git checkout -b show-movie-count        # create feature branch
2. (edit app/views/movies/index.html.erb)  # make the change
3. git add -A && git commit -m "Show movie count on index page"
4. git push origin show-movie-count        # push to GitHub
5. Open a Pull Request on GitHub           # request review
6. CI runs automatically                   # tests checked
7. Reviewer approves                       # code review passes
8. Merge PR into main                      # deploy!
```

**Setting up CI (one-time setup):** Create `.github/workflows/ci.yml`:

```yaml
name: CI

# When to run: on every push and every pull request
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      # Step 1: Download the code
      - name: Checkout code
        uses: actions/checkout@v4

      # Step 2: Install Ruby
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3.8'
          bundler-cache: true    # automatically runs 'bundle install'

      # Step 3: Create the test database
      - name: Set up database
        run: |
          bundle exec rails db:create RAILS_ENV=test
          bundle exec rails db:schema:load RAILS_ENV=test

      # Step 4: Run the tests
      - name: Run RSpec
        run: bundle exec rspec
```

**What each part means:**
- `on: push / pull_request` — CI runs on every push to `main` and on every PR targeting `main`
- `runs-on: ubuntu-latest` — uses a free Linux machine
- `actions/checkout@v4` — downloads your code onto the CI machine
- `ruby/setup-ruby@v1` — installs Ruby; `bundler-cache: true` caches gems for faster runs
- `db:create` + `db:schema:load` — creates a fresh test database
- `bundle exec rspec` — runs all your tests

**After pushing, you see CI status on your PR page:**
- ✅ **Green check** — "All checks have passed" → ready to review and merge
- ❌ **Red X** — "Some checks failed" → click "Details" to see the log, fix the code, push again. CI re-runs automatically.

**Protecting `main` with required checks (recommended):**

Go to GitHub → Settings → Branches → Add branch protection rule:
1. Branch name pattern: `main`
2. Check "Require status checks to pass before merging"
3. Select the `test` job

Now **nobody can merge a PR with failing tests**. This turns the CI habit into an enforced rule.

**This is the CI/CD cycle in practice:**

```
Developer pushes code
       ↓
GitHub Actions runs tests automatically (CI)
       ↓
  ┌─── Pass? ───┐
  │             │
 YES            NO
  │             │
  ↓             ↓
Ready to     Fix code,
review &     push again
merge        (CI re-runs)
  │
  ↓
Merge to main → Auto-deploy (CD)
```

### Example: Automatic Deployment with GitHub Actions

You can extend the CI pipeline to **automatically deploy** whenever code is merged to `main` and tests pass. Here is a combined CI + CD workflow that deploys to Heroku:

```yaml
name: CI/CD

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3.8'
          bundler-cache: true
      - run: bundle exec rails db:create db:schema:load RAILS_ENV=test
      - run: bundle exec rspec

  deploy:
    needs: test          # ← only runs if test job passes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Heroku
        uses: akhileshns/heroku-deploy@v3.13.15
        with:
          heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
          heroku_app_name: "your-app-name"
          heroku_email: "your-email@example.com"
```

**Key points:**
- `needs: test` — the deploy job **waits for all tests to pass** before running. If any test fails, deployment is skipped.
- `secrets.HEROKU_API_KEY` — stored securely in GitHub (Settings → Secrets and variables → Actions → New repository secret). Never put API keys in code.
- Every merge to `main` now triggers: **run tests → deploy** — fully automated, no manual steps.

This is exactly the CI/CD philosophy from the lecture: **deployment should be a non-event that happens all the time**.

---

## 12.5 Monitoring

> "If you're not monitoring it, it's probably broken."

### Two Types of Monitoring

| Type | What | Examples |
|---|---|---|
| **Internal** | Instrumentation in app/framework | Rails logging, Rack middleware |
| **External** | Active probing by other sites | Pingdom, synthetic monitoring |

### Why External Monitoring?

1. If your site is **down**, internal monitoring is down too
2. Detects slowness **outside** your measurement boundary (e.g., network issues)
3. Shows the **user's perspective** from different geographic locations

### Monitoring Tools

| What | Level | Tool | Hosted? |
|---|---|---|---|
| Availability | Site | Pingdom | Yes |
| Unhandled exceptions | Site | Airbrake | Yes |
| Slow actions/queries | App | New Relic, Scout | Yes |
| User behavior | App | Google Analytics | Yes |
| Process health | Process | god, monit, nagios | No |

**APM** (Application Performance Monitoring) = dashboards + history + queryable metrics.

---

## 12.6 Caching

### The Idea

- **Don't hit the database** if the answer hasn't changed
- **Don't re-render** a page/partial if underlying data hasn't changed
- **Expire** stale cached data when it becomes invalid

Caching can happen at multiple levels: browser cache, page cache, action cache, fragment cache, and database query cache. Each level has different trade-offs in terms of what gets cached and how you invalidate it.

### How Much Does Caching Help?

With ~1K movies and ~100 reviews/movie in RottenPotatoes on Heroku:

| Strategy | Response Time | Speedup |
|---|---|---|
| No cache | 449 ms | 1× |
| Action cache | 57 ms | **8×** |
| Page cache | 21 ms | **21×** |

You can serve **8× to 21× as many users** with the same number of servers just by using caching.

---

## 12.9 Defending Customer Data

### SSL / TLS (Secure Sockets Layer / Transport Layer Security)

**Problem:** To communicate securely, two parties need a shared secret — but on the web, they're strangers.

**Solution:** Public key cryptography (Rivest, Shamir, Adelman — 2002 Turing Award)

Each party has a **key pair:**
- **Public key** — everyone can know it
- **Private key** — kept secret
- Given one part, you **cannot deduce** the other
- Encrypted with one key → can only be decrypted with the other

**How SSL works (simplified):**
1. A **Certificate Authority (CA)** signs a certificate: "bob.com is owned by Bob"
2. Certificate installed on Bob's server
3. CA public keys are **built into browsers** → browser verifies the cert
4. **Diffie-Hellman key exchange** bootstraps an encrypted channel
5. In Rails: `force_ssl` in ApplicationController

**What SSL does NOT do:**
- ✗ Assure the server of who the *user* is
- ✗ Protect data *after* it reaches the server
- ✗ Protect against other server vulnerabilities
- ✗ Protect the browser from a malicious server

### SQL Injection

One of the oldest and still most common web vulnerabilities.

```ruby
# VULNERABLE — string interpolation
Moviegoer.where("name='#{params[:name]}'")

# Evil input: BOB'); DROP TABLE moviegoers; --
# Resulting SQL:
# SELECT * FROM moviegoers WHERE (name='BOB'); DROP TABLE moviegoers; --')
```

**Fix — parameterized queries:**
```ruby
Moviegoer.where("name = ?", params[:name])
# or
Moviegoer.where(name: params[:name])
```

Rails escapes special characters automatically. **Never interpolate user input into SQL.**

### Cross-Site Request Forgery (CSRF)

**Attack scenario:**
1. Alice logs into `bank.com` → gets session cookie
2. Alice visits `blog.evil.com`
3. Evil page contains: `<img src="https://bank.com/account_info"/>`
4. Browser sends Alice's valid cookie → bank returns her data to evil.com

**Defenses:**

| Defense | How | Limitation |
|---|---|---|
| **SameSite cookie** | `Set-Cookie: ...; SameSite=Lax` | Depends on browser support |
| **Session nonce** (stronger) | Include random token with every form | Attacker can't guess the nonce |

In Rails:
```erb
<%# In layout: %>
<%= csrf_meta_tags %>
```
```ruby
# In ApplicationController:
protect_from_forgery
```
Rails form helpers automatically include the nonce and reject POSTs with mismatched nonces.

---

## 12.11–12.12 DevOps Fallacies & Pitfalls

### Pitfall: Optimizing Prematurely

- **"You are not Google"** — but speed IS a feature
- Look at **95th percentile**, not average
- **Measure first** with monitoring tools
- Horizontal scaling >> per-machine optimization
- Design to **avoid terrible** performance, not achieve optimal performance

### Fallacy: "It's on the cloud, so it will scale"

- The **database** is hardest to scale
- Cache at **every level** (page, fragment, query)
- Cache expiration is a **crosscutting concern**
- Use indices judiciously
- **Stay on PaaS** as long as possible

### Fallacy: "My small site isn't a target"

- Hackers want your **users** and **platform** (crypto mining, spam), not necessarily your data
- Security is **hard to add after the fact**
- Stay current with best practices
- **Keep regular backups** of site and database

---

## 12.10 Plan-and-Document Perspective

### P&D on Performance
- Treated as a **non-functional requirement**
- Can be part of acceptance tests
- Often deprioritized (performance optimization can excuse bad engineering)

### P&D on Release Management
- Special case of **configuration management**
- Releases include: code + config + data + documentation
- **Semantic versioning:** major.minor.bugfix (e.g., Rails 4.2.11)

### P&D on Reliability
- Dependability through **redundancy** — no single point of failure
- **MTTF** (Mean Time To Failure) includes HW, SW, and human errors
- **Unavailability ≈ MTTR / MTTF**
- Improving MTTR (repair time) is often easier than improving MTTF

### P&D on Process Improvement
- **ISO 9001** certifies that you have:
  1. A defined process
  2. A method to verify it's followed
  3. Records to improve it
- **ISO 9001 certifies the process, NOT the code quality**

### Three Security Principles

| Principle | Rule | Example | Anti-Example |
|---|---|---|---|
| **Least Privilege** | Give no more access than needed | Run as `nobody` user | Running as `root` |
| **Fail-safe Defaults** | Deny unless explicitly granted | Allow-list firewall rules | Deny-list (block-list) |
| **Psychological Acceptability** | Security shouldn't make the app harder to use | TouchID / FaceID | Zoom → SSO → CalNet → Duo 2FA |

### Reliability vs. Security

| | Reliability | Security |
|---|---|---|
| **Threats** | Random events | Intelligent opponents |
| **Approach** | Redundancy, testing | Defense in depth, least privilege |
| **Database** | CVE (Common Vulnerabilities & Exposures) | cvedetails.com |

---

## Key Takeaways

1. **Development ≠ Deployment** — real users bring stress, misuse, and attackers
2. **Stick with PaaS** — the skills transfer if you outgrow it
3. **Three-tier architecture** — shared-nothing app tier, careful database scaling
4. **Measure before optimizing** — use APM tools, look at 95th percentile
5. **CI/CD** — deploy frequently, automate everything, reduce risk per deploy
6. **Monitor everything** — internal + external, set up alerts
7. **Cache aggressively** — caching can give 8×–21× speedup
8. **Security from day one** — SSL, parameterized queries, CSRF protection, least privilege

---

*Based on ESaaS (Engineering Software as a Service), Chapter 12. Lecture by Prof. Armando Fox.*

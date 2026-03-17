# Lecture 9: Software Maintenance, Legacy Code & Refactoring

> *"Try to leave this world a little better than you found it."* — Lord Robert Baden-Powell (founder of the Boy Scouts)
>
> This applies to code, too.

---

## 9.1 What Makes Code "Legacy" — and Why Should You Care?

### The Surprising Economics of Software

About **60% of the total cost** of software over its lifetime goes to **maintenance** — and most of that is **not** bug fixes, but **enhancements** (adding new features and functionality).

**Example:** Think about an app like Instagram. The original photo-sharing features were built once, but the team has spent *years* after that adding Stories, Reels, shopping, messaging, etc. The initial development was just the beginning.

> *"Old hardware becomes obsolete, so people discard it. Old software goes into production every night."*  — Robert Glass, *Facts and Fallacies of Software Engineering*

**Takeaway:** If you go into industry as a software engineer, your first assignment will almost certainly *not* be "build something from scratch." It will be "here's an existing codebase — add value to it."

### What Makes Code "Legacy"?

Legacy code is code that:

1. **Is still doing something useful** — some customer depends on it.
2. **You didn't write it** (or you wrote it long ago and forgot the details).
3. **It's not well documented** — so understanding it is a challenge.
4. **Most importantly: it lacks good tests.**

> *Why is "lacking tests" the best definition?*
>
> Because tests serve two critical purposes:
> - **Safety net**: Without tests, modifying code is terrifying — you won't know if you broke something.
> - **Documentation**: Cucumber scenarios describe *what workflows the app supports*; RSpec/unit tests describe *how individual pieces behave*.

**Book recommendation:** *Working Effectively with Legacy Code* by Michael Feathers — the definitive practical guide.

### Two Approaches to Modifying Legacy Code

| Approach | Description | Risk Level |
|---|---|---|
| **Edit and Pray** | Make changes, hope nothing breaks. | High |
| **Cover and Modify** | Add test coverage first, then make changes safely. | Low |

**Example:** Imagine you need to change how tax is calculated in an e-commerce app. With "Edit and Pray," you change the formula and hope checkout still works. With "Cover and Modify," you first write tests that verify the current tax behavior, *then* change the formula — and if your tests fail, you immediately know something broke.

---

## 9.2 Approaching a Legacy Codebase

You've just joined a project with an existing codebase. Here's a practical step-by-step approach.

### Step 1: Create a Scratch Branch

```bash
git checkout -b scratch-exploration
```

This branch will **never be merged back**. It's your playground for:
- Getting the code to run in your environment.
- Tweaking config files, setting up a local database copy.
- Experimenting without fear of messing up the real codebase.

### Step 2: Learn the User Stories

- **Talk to customers** — watch them use the app, ask about their most important workflows.
- **Create your own documentation** as you learn.

**Example:** If the app is a university course registration system, watch an advisor walk through the process of registering a student for classes. What screens do they use? What constraints exist (prerequisites, seat limits)? Document everything.

### Step 3: Discover the Domain Model

The **domain model** captures the key entities and relationships in the app.

**Example:** For a movie review app, the domain model might be:

```
Movie ──< Review >── Moviegoer
  │
  └── has_many :reviews
```

- A `Movie` has many `Review`s.
- A `Moviegoer` has many `Review`s.
- Each `Review` belongs to one `Movie` and one `Moviegoer`.

For a database-backed app (e.g., Rails), look at the **database schema** — the relationships among tables reveal the architecture.

> *"Show me your flowchart and conceal your tables, and I shall be mystified. Show me your tables, and I won't usually need your flowchart."* — Fred Brooks, *The Mythical Man-Month*

### Step 4: Mine Existing Documentation

Look for documentation in these places:

| Source | What It Tells You |
|---|---|
| **Test suite** | What the code is *supposed* to do |
| **Code-to-test ratio** | A ratio > 1.0 is common and healthy |
| **Coverage reports** | Where tests exist (especially around your change area) |
| **Project wiki / shared drive** | Informal design docs, wireframes |
| **Project boards** (GitHub Projects, Trello, Jira) | Historical tasks and attached design docs |
| **Javadoc / RDoc** | Auto-generated API documentation from code comments |

**Key principle:** Whatever you learn, **add it to the documentation** so the next person has it easier.

---

## 9.3 Establishing Ground Truth with Characterization Tests

### The Chicken-and-Egg Problem

- You can't safely modify code without tests.
- You can't write good tests without understanding the code.
- You can't understand the code without exploring it.

**Solution:** Write **characterization tests** — tests that capture *what the app currently does*, not what it *should* do.

### Integration-Level Characterization Tests

Watch users work with the app, then reproduce their workflows as automated tests.

**Example (Cucumber-style):**

```gherkin
Scenario: User logs in and sees their dashboard
  Given I am a registered user with email "alice@example.com"
  When I go to the login page
  And I fill in "Email" with "alice@example.com"
  And I fill in "Password" with "secret123"
  And I press "Log In"
  Then I should see "Welcome back, Alice"
  And I should see "Your Dashboard"
```

This is intentionally **verbose and imperative** — it's not polished, but it captures the current behavior. You can refine it later.

### Unit-Level Characterization Tests: Poke and Observe

For lower-level tests, you iteratively **poke at the code** and capture what it does.

**Step-by-step example** — suppose you need to test a `compute_tax` method:

**Attempt 1:** Create a test double and guess at the expected value.

```ruby
it 'computes tax for an order' do
  order = double('order')
  expect(compute_tax(order)).to eq(10.00)  # just a guess
end
```

**Result:** Error — `order` double received unexpected message `get_total`.

**Attempt 2:** Stub the missing method.

```ruby
it 'computes tax for an order' do
  order = double('order', get_total: 100.00)
  expect(compute_tax(order)).to eq(10.00)  # still guessing
end
```

**Result:** Expected `10.00`, got `8.45`.

**Attempt 3:** Update the expectation to match reality.

```ruby
it 'computes tax for an order' do
  order = double('order', get_total: 100.00)
  expect(compute_tax(order)).to eq(8.45)  # captured real behavior!
end
```

Now you have a **repeatable probe** — if future changes break this code path, your test will catch it.

---

## 9.4 Comments and Commits: Tell Me a Story

### What Makes a Good Comment?

A good comment tells something **not obvious** about the code. It operates at a **higher level of abstraction** than the code itself.

**Good reasons to comment:**

| Scenario | Example |
|---|---|
| **Non-obvious invariants** | `# On entry, @user always contains a valid User instance` |
| **Unusual implementation choices** | `# We use a manual query here instead of has_many :through because of Rails bug #12345` |
| **Bug workarounds** | `# Workaround for PostgreSQL multi-tenant cache bug. Remove after upgrading to Rails 5.2 (see PR #6789)` |
| **Strange corner cases** | `# Leap seconds can cause off-by-one here; see NIST spec section 4.2` |

### Anti-Examples: Comments That Add No Value

```ruby
# Bad: repeats what the code already says
lock = SpinLock.new  # Create a spin lock to protect against concurrent access

# Bad: obvious from method/variable names
def calculate_total(items)  # Calculates the total for the given items
  items.sum(&:price)        # Sum up all the prices
end
```

If your method and variable names are well-chosen, the code **speaks for itself**.

### Comments vs. Commit Messages: Where Does Information Go?

**Bright-line test:** Is this information important for a developer to know *right now* while working on this code?

| If YES → **Put it in a comment** | If NO → **Put it in the commit message** |
|---|---|
| Active workarounds for bugs | History of bugs that were already fixed |
| Assumptions the next developer needs to know | Rationale for past design decisions |
| TODOs tied to future library upgrades | Context for why a change was made |

**Example of a well-documented workaround:**

```ruby
# Workaround: Rails has_many :through bug with scoped finds
# traversing associations (see rails/rails#28456).
# TODO: Remove this override after upgrading to Rails 5.2,
# which includes the fix (PR #29675).
def customers
  Customer.where(show_id: id)  # manual query instead of association
end
```

---

## 9.5 Beyond Correctness: Smells, Metrics, and SOFA

### Code Smells

A **code smell** is code that works correctly but "feels wrong" — it signals potential problems with maintainability or design.

### The SOFA Checklist for Methods

| Letter | Guideline | Why It Matters |
|---|---|---|
| **S** | **Short** | Easier to read, understand, and test |
| **O** | **Does One thing** | If it does many things, it should be many methods |
| **F** | **Few Arguments** | Many arguments signal hidden classes or multiple behaviors |
| **A** | **Single level of Abstraction** | Don't mix *what* with *how* |

### Too Many Arguments — Two Warning Signs

**Warning Sign 1: Arguments travel in packs**

```ruby
# Bad — these arguments are clearly related
def create_contact(name, street, city, zip, email, phone)
  # ...
end

# Better — extract a class
class Contact
  attr_accessor :name, :street, :city, :zip, :email, :phone
end

def create_contact(contact)
  # ...
end
```

**Warning Sign 2: Boolean arguments control behavior**

```ruby
# Bad — boolean controls two different behaviors
def send_notification(user, urgent)
  if urgent
    send_sms(user)
  else
    send_email(user)
  end
end

# Better — two separate methods
def send_urgent_notification(user)
  send_sms(user)
end

def send_regular_notification(user)
  send_email(user)
end
```

### Single Level of Abstraction: The Newspaper Analogy

A well-written news article starts with a **summary paragraph**, then details each point in subsequent paragraphs. Code should work the same way.

**Bad — mixed abstraction levels:**

```ruby
def handle_login(user)
  flash[:notice] = "Welcome back"
  if user.email_opt_out_date &&
     user.email_opt_out_date > 30.days.ago &&
     Setting.where(key: 'opt_in_reminder').first.try(:value)
    flash[:notice] += " — would you like to rejoin our mailing list?"
  end
  redirect_to dashboard_path
end
```

Some lines are high-level ("set the flash"), others dive into database queries and date arithmetic.

**Good — consistent abstraction with descriptive helper methods:**

```ruby
def handle_login(user)
  flash[:notice] = login_message(user)
  redirect_to dashboard_path
end

private

def login_message(user)
  if user.recently_opted_out_of_email?
    encouraged_opt_in_message
  else
    "Logged in successfully"
  end
end
```

Now the top-level method reads like English. The *how* is delegated to helper methods whose names say *what* they do.

### Quantitative Metrics

#### ABC Complexity (Assignment, Branch, Condition)

\[
\text{ABC} = \sqrt{A^2 + B^2 + C^2}
\]

where:
- **A** = number of assignments
- **B** = number of branches (method calls, conditionals)
- **C** = number of conditions

**NIST recommendation:** ABC < 20 for a single function.

**Example:** Two solutions to an anagram-grouping problem:

```ruby
# Version A (high ABC): nested loops, manual comparisons
def combine_anagrams(words)
  result = []
  used = []
  words.each_with_index do |w1, i|
    next if used.include?(i)
    group = [w1]
    words.each_with_index do |w2, j|
      next if i == j || used.include?(j)
      if w1.downcase.chars.sort == w2.downcase.chars.sort
        group << w2
        used << j
      end
    end
    used << i
    result << group
  end
  result
end

# Version B (low ABC): idiomatic Ruby
def combine_anagrams(words)
  words.group_by { |w| w.downcase.chars.sort }.values
end
```

Both produce the same result, but Version B has dramatically lower complexity.

#### Cyclomatic Complexity

Measures the number of **independent paths** through a block of code.

**Formula:** \( V(G) = E - N + 2P \)

where \( E \) = edges, \( N \) = nodes, \( P \) = connected components in the control flow graph.

**NIST recommendation:** < 10 per module.

### Tools

| Tool | Purpose |
|---|---|
| **Reek** | Detects code smells in Ruby |
| **Flog** | Measures ABC complexity |
| **MetricFu** | Aggregates multiple static analysis metrics |
| **Code Climate** | Cloud service that gives each file a GPA grade |

---

## 9.6 Method-Level Refactoring: A Step-by-Step Example

### What Is Refactoring?

**Refactoring** = changing the *structure* of code without changing its *behavior*.

> *"When you write code, all you're doing is creating a first draft. Refactoring is the act of getting from your first draft to a draft you're actually proud of."*

**Book recommendation:** *Refactoring* by Martin Fowler — the definitive catalog of refactoring techniques.

### The Microsoft Zune Bug: A Real-World Case Study

In 2008, Microsoft's Zune music player had a firmware bug: if you rebooted it on **December 31, 2008** (a leap year), it would freeze permanently and become a brick. The only fix was to wait until **January 1, 2009** and reboot.

Here's a Ruby transliteration of the code that caused the bug. It converts a count of days since January 1, 1980 into a year/month/day:

**Original (with one-letter variable names):**

```ruby
def days_to_date(d)
  y = 1980
  while d > 365
    if leap_year?(y)
      if d > 366
        d -= 366
        y += 1
      end
    else
      d -= 365
      y += 1
    end
  end
  return y, d
end
```

Can you spot the bug? Let's walk through the refactoring process to find it.

### Refactoring Step 1: Rename Variables

```ruby
def days_to_date(remaining_days)
  year = 1980
  while remaining_days > 365
    if leap_year?(year)
      if remaining_days > 366
        remaining_days -= 366
        year += 1
      end
    else
      remaining_days -= 365
      year += 1
    end
  end
  return year, remaining_days
end
```

A small change, but now your brain picks up meaningful signals from variable names.

### Refactoring Step 2: Extract Helper Method

Pull out the leap year calculation so it can be tested independently:

```ruby
def leap_year?(year)
  (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
end
```

Now write tests for it:

```ruby
describe 'leap_year?' do
  it 'returns true for typical leap years'  do expect(leap_year?(2004)).to be true  end
  it 'returns false for century years'      do expect(leap_year?(1900)).to be false end
  it 'returns true for 400-year centuries'  do expect(leap_year?(2000)).to be true  end
  it 'returns false for ordinary years'     do expect(leap_year?(2001)).to be false end
end
```

All pass. Good.

### Refactoring Step 3: Extract a Class and More Helpers

```ruby
class DateConverter
  def initialize(days_since_epoch, start_year = 1980)
    @remaining_days = days_since_epoch
    @year = start_year
  end

  def convert
    while @remaining_days > 365
      if leap_year?(@year)
        add_leap_year
      else
        add_regular_year
      end
    end
    [@year, @remaining_days]
  end

  private

  def add_leap_year
    if @remaining_days > 366       # <-- THE BUG IS HERE
      @remaining_days -= 366
      @year += 1
    end
  end

  def add_regular_year
    @remaining_days -= 365
    @year += 1
  end
end
```

### Refactoring Step 4: Write Tests That Expose the Bug

Now that `add_leap_year` is a separate method, we can test it in isolation:

```ruby
describe '#add_leap_year' do
  it 'peels off a leap year when many days remain' do
    converter = DateConverter.new(400, 2008)
    converter.send(:add_leap_year)
    expect(converter.instance_variable_get(:@year)).to eq(2009)    # PASS
  end

  it 'peels off a leap year when exactly 366 days remain' do
    converter = DateConverter.new(366, 2008)
    converter.send(:add_leap_year)
    expect(converter.instance_variable_get(:@year)).to eq(2009)    # FAIL!
  end
end
```

The second test **fails**! When there are **exactly 366 days** remaining in a leap year, the condition `> 366` is false, so the year counter never increments — causing an **infinite loop**.

### The Fix: One Character

```ruby
# Bug:
if @remaining_days > 366

# Fix:
if @remaining_days >= 366
```

That single missing `=` bricked every Zune that rebooted on December 31, 2008.

### Key Lessons from This Example

1. **Renaming variables** improves readability at zero cost.
2. **Extracting methods** makes each piece independently testable.
3. **Extracting a class** organizes related state and behavior together.
4. **Refactoring can expose bugs** that hide in complex, monolithic methods.
5. **More lines of code ≠ worse.** The refactored version is longer but has lower complexity (ABC score dropped from 23 to ≤ 12 per method).

### Glass-Box (White-Box) Testing

When writing unit tests, identify:

- **Critical values** — boundary cases where behavior changes (e.g., exactly 366 days, leap year boundaries).
- **Non-critical values** — pick one representative from each "normal" range.

This strategy is what helped catch the Zune bug.

---

## 9.7 Plan-and-Document vs. Agile Perspectives on Maintenance

### Key Differences

| Aspect | Plan & Document | Agile |
|---|---|---|
| **Team structure** | Separate maintenance team from dev team | Same team does both |
| **Change requests** | Formal process → Change Control Board | User stories in the backlog |
| **Prioritization** | CCB evaluates cost, QA effort, doc updates | Team + customer prioritize together |
| **Documentation** | Maintained by a dedicated team | Tests *are* documentation; kept in sync continuously |
| **Urgency** | Emergency patches → then sync docs later | Continuous integration/deployment handles changes incrementally |
| **Refactoring** | Harder to justify — doesn't add visible customer value | Built into the development process |

### When Is P&D Better?

- Safety-critical systems (medical devices, aviation).
- Heavily regulated environments.
- Customers who won't be available post-deployment.

### Agile's Advantage

Agile treats maintenance and development as **the same activity on different time scales**. The same skills — BDD, TDD, refactoring, continuous integration — apply whether you're writing new code or enhancing a 10-year-old codebase.

---

## 9.8–9.9 Fallacies, Pitfalls, and Conclusions

### Pitfall 1: "Let's Just Throw It Away and Start Over"

This is **almost never the right decision**.

**Why?** That old code isn't just lines on a screen — it contains years of accumulated knowledge about customer needs, edge cases, and bug fixes.

**The rewrite trap:**
- The first 50% of functionality is rebuilt quickly → you feel great.
- The next 40% takes much longer than expected → you start to worry.
- The last 10% seems to take forever → this is all the institutional knowledge you threw away.

### Pitfall 2: Mixing Refactoring with Feature Development

When refactoring, **only refactor**. Don't add features at the same time.

**Correct workflow:**
1. Refactor to improve code structure → all tests pass.
2. *Then* add the new feature from a stable, well-tested base.

### Pitfall 3: Worshipping Metrics

No single metric is gospel truth. Use metrics as **engineering guidance**, not absolute rules.

**Good practice:** Look for **hotspots** — places where *multiple* metrics flag problems simultaneously.

### Pitfall 4: Putting Off Refactoring Until Later

Small, continuous refactoring prevents **technical debt** from accumulating.

**Technical debt** = "We know the code is ugly, but it was an emergency... we'll fix it later."

> *"Later" rarely comes.*

If you let technical debt build up, you'll eventually face the temptation of Pitfall 1 — wanting to throw everything away.

### The First Draft Analogy

> The opening of the U.S. Declaration of Independence originally read:
> *"When in the course of human events it becomes necessary for a people to advance from that subordination in which they have hitherto remained..."*
>
> After refactoring (editing), it became:
> *"We hold these truths to be self-evident..."*
>
> Your first draft of code is just that — a first draft. **Refactoring** is what turns it into something you're proud of.

---

## Summary: The Complete Workflow for Legacy Code

```
┌─────────────────────────────────────────────────────┐
│  1. Get the code running (scratch branch)           │
│  2. Learn user stories (talk to customers)          │
│  3. Discover the domain model (database schema)     │
│  4. Mine existing documentation (tests, wikis, PRs) │
│  5. Write characterization tests (capture current   │
│     behavior at integration + unit levels)          │
│  6. Identify change points (where to modify)        │
│  7. Refactor to improve testability (SOFA, metrics) │
│  8. Add your feature from a stable, tested base     │
│  9. Leave the code better than you found it         │
└─────────────────────────────────────────────────────┘
```

---

## Key Terms Quick Reference

| Term | Definition |
|---|---|
| **Legacy Code** | Code still in use that lacks good tests |
| **Characterization Test** | A test that captures current behavior (not ideal behavior) |
| **Refactoring** | Changing code structure without changing behavior |
| **Code Smell** | Code that works but has structural problems |
| **SOFA** | Short, One thing, Few arguments, single Abstraction level |
| **ABC Complexity** | Metric: \(\sqrt{A^2 + B^2 + C^2}\) for assignments, branches, conditions |
| **Cyclomatic Complexity** | Number of independent paths through code |
| **Technical Debt** | Accumulated shortcuts that make future changes harder |
| **Glass-Box Testing** | Writing tests with knowledge of the implementation |
| **Cover and Modify** | Add test coverage before making changes |
| **Edit and Pray** | Make changes without tests (don't do this) |

---

## Recommended Reading

| Book | Author | Why Read It |
|---|---|---|
| *Working Effectively with Legacy Code* | Michael Feathers | The definitive guide to approaching legacy codebases |
| *Refactoring* | Martin Fowler | The catalog of refactoring techniques — like a recipe book |
| *The Mythical Man-Month* | Fred Brooks | Timeless lessons on large software projects |
| *Facts and Fallacies of Software Engineering* | Robert Glass | Concise, evidence-based insights about the industry |

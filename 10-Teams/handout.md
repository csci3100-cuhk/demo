# CSCI3100 Lecture 10: Agile Teams — Student Handout

---

## 1. Software Engineering Is a Team Sport

The era of the "rockstar programmer" who builds everything alone is over. Modern software is too complex for one person. A successful SWE career requires:

- Strong programming skills
- Ability to work on a team
- Communication and documentation skills
- Helping the team win — not just individual heroics

> **Fred Brooks:** "There are no winners on a losing team, and no losers on a winning team."

**Why teams have grown:** Video games illustrate the trend well.

| Game | Year | Team Size |
|---|---|---|
| Space Invaders | 1981 | 1 |
| Super Mario Bros. | 1985 | 8 |
| Sonic the Hedgehog | 1999 | 30 |
| Resident Evil 6 | 2013 | 600 |
| Red Dead Redemption 2 | 2018 | 1,200 |

---

## 2. Scrum: How Agile Teams Are Organized

### Team Size: The "2-Pizza Rule"
Keep teams small enough that two pizzas can feed everyone — roughly **4 to 9 people**. This is your day-to-day working group.

### Daily Stand-Up (Daily Scrum)
A **15-minute meeting, same time and place every day**. Everyone answers three questions:

1. What have you done since yesterday?
2. What are you planning to do today?
3. Are there any impediments or stumbling blocks?

**Why stand up?** Standing keeps meetings short and focused. It's okay — and expected — to say you're stuck. That's the point: surface blockers early so teammates can help.

### Scrum Roles

**Scrum Master**
- A team member (not a separate manager) who also writes code
- Acts as a buffer between the team and external distractions
- Keeps the team focused and on task
- Removes blockers
- Enforces team rules (coding standards, etc.)
- Because they're a peer in the code, trust is easier to build

**Product Owner**
- A different team member from the Scrum Master
- Represents the voice of the customer
- Prioritizes user stories
- Separating these two roles is intentional — it creates healthy tension between customer needs and development priorities

**Tip:** Rotate both roles across team members each sprint. Everyone benefits from experiencing both perspectives.

### Sprints
Teams work in **2–4 week sprints**. At the start of each sprint, hold an **Iteration Planning Meeting** to pick which stories to work on.

---

## 3. Resolving Conflicts

Disagreements happen. Here's a structured approach:

**Step 1 — Start with agreements**
List everything both sides agree on before listing disagreements. You'll often find you're closer than you thought.

**Step 2 — Articulate the other side's argument**
Even if you disagree, try to argue the other position. This forces you to understand it and often reveals that the real conflict is about terminology, not substance.

**Step 3 — Constructive Confrontation (Intel)**
If you have a strong technical opinion that something is wrong, you are *obligated* to raise it — even to your boss. Framing it as helping the team (not attacking a person) makes this easier.

**Step 4 — Disagree and Commit (Intel)**
Once a decision is made, embrace it and move forward.
> "I disagree, but I am going to help even if I don't agree."

You lost the argument about which library to use — fine. You're still on the team. Help ship it.

---

## 4. Effective Branching: Branch Per Feature

### Why Branches?
Creating a branch in Git is **free and instant**. Branches let multiple features be developed in parallel without breaking each other.

### Branch Per Feature Workflow

```
# 1. Create a new branch for your feature
git checkout -b my-feature

# 2. Work, commit, repeat
git add .
git commit -m "Add login form"

# 3. Push to remote (backup + triggers CI)
git push origin my-feature

# 4. When done, merge back to main
git checkout main
git merge my-feature
```

**Key principle:** One branch = one feature (or bug fix, or chore). Keep branches focused and short-lived.

In a well-factored app, one feature branch shouldn't touch many parts of the codebase.

### Rebase Before Merging

`git rebase` lets you "pretend" your branch was created from a more recent point in history. Use it to:
- Keep your branch in sync with main as teammates push changes
- Produce a clean, conflict-free merge when you're ready

```
# Sync your feature branch with latest main
git rebase main
```

The best merge conflict is the one that never happens. Frequent rebasing prevents conflicts from accumulating.

### Deployment Strategies

| Strategy | How it works |
|---|---|
| **Deploy from main** | Every merged PR triggers automatic deployment |
| **Branch per release** | Cut a named branch (e.g. `v1.3`) when releasing; patch that branch for hotfixes |

Most modern teams use "deploy from main" because it forces fast iteration and good test coverage.

### `git cherry-pick`
Pick a specific commit from one branch and apply it to another. Useful for applying a bug fix from main into a release branch without pulling in unfinished features.

```
git cherry-pick <commit-hash>
```

---

## 5. Pull Requests (PRs)

A PR is a request for someone to pull your branch's changes into another branch. PRs are a GitHub feature (not part of Git itself) and are arguably the most valuable thing GitHub adds.

### What PRs give you
- A description of what changed and why
- A place for teammates to comment on specific lines
- Hooks for automation (CI runs, code quality checks)
- A permanent record of design decisions

### PRs as Code Reviews
At Google, **no code is merged without at least one reviewer** commenting "LGTM" (Looks Good To Me). This is the standard in professional teams.

**Keep PRs small.** A PR with 3–4 changed files is reviewable in minutes. A PR with 500 lines is nearly useless — reviewers can't meaningfully evaluate it.

> Code gets a million bugs one bug at a time. Small PRs are your defense.

### Branch vs. Fork

| Situation | Use |
|---|---|
| You have commit access to the repo | Create a branch in the same repo |
| You don't have access (e.g. open source) | Fork the repo, work on your fork, open a PR back |

**Open source courtesy:** Before opening a PR on someone else's project, check their contribution guidelines. Nobody likes a surprise 500-line PR dropped on them.

---

## 6. Git Cheatsheet

### Undo Commands

```bash
# Undo last merge (before pushing)
git reset --hard ORIG_HEAD

# Reset to last commit (discard all local changes)
git reset --hard HEAD

# Restore specific files from a commit
git checkout <commit-or-branch> -- file1.rb file2.rb
```

### Investigate History

```bash
# Diff against a branch or commit
git diff main -- app/models/user.rb

# Diff against a date
git diff "main@{2 days ago}" -- app/models/user.rb

# See who last changed each line
git blame app/models/user.rb

# View commit history for a file
git log app/models/user.rb
```

### "Commitish" Syntax
Anywhere Git accepts a commit reference, you can use:

| Syntax | Meaning |
|---|---|
| `HEAD` | Current commit |
| `HEAD~2` | 2 commits before current |
| `origin/main` | Latest commit on remote main |
| `abc1234` | Specific commit hash (short or long) |
| `@{2 days ago}` | Relative time |

### Common Gitfalls

**Stomping on changes after merging/switching branches**
- Always check `git status` before editing
- Commit everything before switching branches
- Reload files in your editor after a merge

**Making "simple" changes directly on main**
- What starts as a 1-line fix becomes 5 files and broken tests
- Rule: **Never edit main directly.** Main is for merging and deploying only.
- Tip: Configure your shell prompt to show the current branch name

**Letting your local repo drift out of sync**
- `git pull` before starting any new work
- `git push` as soon as your local commits are stable
- Use `git rebase` periodically on long-lived branches

---

## 7. Design Reviews and Code Reviews

### Design Review
A meeting where the team discusses the *architecture* of a feature **before writing code**. Goal: benefit from everyone's experience, catch problems early.

### Code Review
Happens after the design is implemented. Looks at actual code. No point debating function names before code exists.

### Review Agenda (for both)
1. Start with customer desires — why does this feature exist?
2. Present the software architecture and APIs
3. Walk through code and documentation
4. Discuss testing plan and schedule
5. Verify: are we building the right thing? Does it do what we asked?

### Good Meetings: SAMOSAS

| Letter | Stands for |
|---|---|
| **S** | Start and stop on time |
| **A** | Agenda created in advance (no agenda = no meeting) |
| **M** | Minutes recorded |
| **O** | One speaker at a time |
| **S** | Send material in advance |
| **A** | Action items assigned at end |
| **S** | Set date/time of next meeting |

### Avoid Big Reviews
Formal reviews that happen late in the process have little impact — the code is already written. Instead:

- Hold **"approach reviews"** early: a few developers brainstorm the high-level approach before coding starts
- If you must do a formal review, hold a **mini-design review** first to prepare everyone
- Avoid surprises — everyone should arrive knowing what's being discussed

### Agile Alternatives to Formal Reviews
- **Pair programming** (Pivotal Labs model): two people working together = continuous review, no special review needed
- **Frequent small PRs** (GitHub model): each PR is a mini-review; if discussion gets long, schedule a quick meeting

---

## 8. Continuous Integration (CI)

CI is a service (e.g. GitHub Actions) that automatically runs your test suite every time you push code.

### Why CI matters
- Catches test failures you might miss locally
- Runs the *full* test suite, not just the tests you're focused on
- Gives teammates visibility into the health of your branch
- Calculates code coverage, saves screenshots, etc.

### Basic Workflow

```
Local machine          GitHub (remote)         CI Service
─────────────          ───────────────         ──────────
checkout branch   →    push branch        →    run all tests
make commits           open PR                 report results
fix CI failures   ←    review comments   ←    flag failures
push fixes        →    merge PR          →    deploy to staging
                                              → deploy to production
```

### Story States in This Workflow

| State | When |
|---|---|
| **Started** | You create the branch and begin coding |
| **Finished** | You open a PR; CI passes; you're confident it's done |
| **Delivered** | Pushed to staging; customer can test it |
| **Accepted** | Customer signs off; deployed to production |

---

## 9. Minimizing Feedback Loops

The goal is to iterate fast. Every loop (CI failure, code review comment, customer rejection) costs time.

**Small stories → short-lived branches → small PRs → fast reviews → fast merges**

Practical rules:
- Work on **one story at a time** — finish the full cycle before starting another
- Work in **priority order** — respect what the team agreed matters most
- If a story blocks another, pair up to unblock it first
- Maintain a **sustainable pace** — don't batch all your commits to Friday afternoon

---

## 10. Fixing Bugs: The Five R's

**No bug fix without a test.** This is non-negotiable.

| Step | What to do |
|---|---|
| **Report** | Add the bug to your tracker (Pivotal, GitHub Issues). Bugs = 0 story points (not zero effort!) |
| **Reproduce / Reclassify** | Can you reproduce it with the simplest possible test case? Or is it actually a feature request? |
| **Regression test** | Write a test that *fails* in the presence of the bug. If you can't make it fail, you don't understand the bug. |
| **Repair** | Fix the code until the regression test passes |
| **Release** | Push and deploy the fix |

**Why write the failing test first?** If you fix the bug without seeing the test fail, you can't prove you actually fixed it. The bug might just be hiding.

**Reclassifying is valid.** Some bugs are actually feature requests. Some bugs won't be fixed because the fix would break something else. Communicate clearly when this happens.

---

## 11. Pitfalls and Fallacies

### Pitfall: Dividing work by stack layer
Don't split "Alice does front-end, Bob does back-end." This creates coordination overhead and means neither person has the full picture. In agile, each team member should deliver **all aspects of a story** — tests, views, controllers, models.

### Pitfall: Stomping on changes
Commit before switching branches. Reload files after merging. Check `git status` constantly.

### Pitfall: Letting your repo drift
Pull before starting. Push when stable. Rebase long-lived branches regularly.

### Fallacy: "It's fine to make a simple change on main"
It never stays simple. Always create a branch. Branching is instant and free.

### The 10 Commandments for Being a Bad Team Player (and what to do instead)

| Bad habit | Better approach |
|---|---|
| "Those test failures don't matter" | Never push red — keep CI green |
| "My branches, my sanctuary" | Keep branches short-lived |
| "It's just a simple change" | Always branch, even for tiny changes |
| "I am a special snowflake" | Follow the team's coding style |
| "Cleverness is impressive" | Transparency is more valuable |
| "Just change it quickly on the production server" | Make every change automatable and tracked |
| "Time spent looking stuff up = wasted time" | Spend 5 minutes searching before asking |
| "More tests = higher quality" | Green fever: catch it — quality > quantity |
| "Weeks of coding can save hours of planning" | Walk through your design first |

### Team Health Rules (example from real teams)
- Any method with complexity score > 10 gets refactored
- Any branch older than ~3 days gets cleaned up
- Any merge that breaks the build gets reverted; author must rebase
- Any bug fix without >90% test coverage gets rejected

---

## 12. Concluding Principles

- **2-pizza teams** reduce management overhead but don't eliminate it — you still need Scrum Master and Product Owner roles
- **Story points + velocity** make delivery more predictable over time; use them to improve estimation, not to judge people
- **When a project ends**, take time to reflect: what went well, what didn't, what you'd do differently. Write it down before jumping to the next thing.
- **Git is a life skill** — use it for every project, every paper, every text file. Put your GitHub username on your resume.

> "If it hurts, do it more frequently, and bring the pain forward."
> — *Continuous Delivery*, Jez Humble (2010)

The more often you do something painful (merging, deploying, reviewing), the more you're forced to fix the pain points — and the easier it becomes.

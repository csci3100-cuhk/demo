# Git & GitHub Workflow: A Step-by-Step Example

This guide teaches you the **full Git and GitHub workflow** from Lecture 10.
We use the **MoovOver** app. The feature is tiny on purpose — the point is
learning the **process**, not the code.

**The feature:** show a movie count on the index page, like
`Showing 5 movies`. This is **one line** of code.

**What you need before starting:**

- Git installed on your computer
- A GitHub account
- The MoovOver repository on GitHub (shared with your team)
- A local clone of the repository

If you do not have a local clone yet, first, fork the repo `https://github.com/csci3100-cuhk/moovover-10-teams.git` on GitHub, then

```bash
git clone https://github.com/your-team/moovover-10-teams.git
cd moovover
```

---

## Step 1 — Pull the latest `main` (avoid stale clone)

**Why:** Your local copy may be **old**. If you start work on old code, you
will have **painful merge conflicts** later.

```bash
cd moovover
git checkout main
git pull origin main
```

**What each command does:**

- `cd moovover` — go into the project folder
- `git checkout main` — switch to the `main` branch
- `git pull origin main` — download the latest code from GitHub and update your
  local `main`

You should see something like:

```
Already up to date.
```

or:

```
Updating a1b2c3d..e4f5g6h
Fast-forward
 app/views/movies/index.html.erb | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Both are fine. Now your local `main` matches GitHub.

---

## Step 2 — Create a feature branch

**Why:** Never work directly on `main`. The `main` branch is for **reviewed,
tested** code only. You work on a **separate** branch.

```bash
git checkout -b show-movie-count
```

**What this does:** creates a new branch called `show-movie-count` and switches
to it. The name describes the feature.

Check that you are on the new branch:

```bash
git branch
```

You should see:

```
  main
* show-movie-count
```

The `*` means you are on `show-movie-count`.

> **Tip:** show the current branch in your terminal prompt. That prevents
> accidentally working on the wrong branch.

---

## Step 3 — Make the code change

Open the file `app/views/movies/index.html.erb` in your editor.

Find this line near the top:

```erb
<h1>Movies</h1>
```

Add **one line** right below it:

```erb
<p>Showing <%= @movies.count %> movies</p>
```

So the file now looks like:

```erb
<h1>Movies</h1>
<p>Showing <%= @movies.count %> movies</p>
```

**Save** the file. That is the entire code change.

**How it works:** `@movies` is a list of all movies (set by the controller).
`.count` returns how many. `<%= ... %>` prints the result into the HTML page.

---

## Step 4 — Check what changed

Before committing, always **look** at what you changed.

```bash
git status
```

You should see:

```
On branch show-movie-count
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)

        modified:   app/views/movies/index.html.erb

no changes to commit (use "git add" to track)
```

This tells you: **one file changed**, on the **correct branch**. Good.

To see the **exact** change:

```bash
git diff
```

You should see something like:

```diff
diff --git a/app/views/movies/index.html.erb b/app/views/movies/index.html.erb
--- a/app/views/movies/index.html.erb
+++ b/app/views/movies/index.html.erb
@@ -15,6 +15,7 @@

 <h1>Movies</h1>
+<p>Showing <%= @movies.count %> movies</p>
```

The `+` line is what you added. Nothing else changed. Good.

> **Lecture link:** `git diff` for understanding changes.

---

## Step 5 — Stage and commit

**Staging** tells Git which changes go into the next commit.

```bash
git add app/views/movies/index.html.erb
```

Now **commit** with a clear message:

```bash
git commit -m "Show movie count on index page"
```

You should see:

```
[show-movie-count 7f3a1b2] Show movie count on index page
 1 file changed, 1 insertion(+)
```

The commit is saved **locally** on your computer. It is **not** on GitHub yet.

> **Good commit messages:** short, starts with a verb, describes **what** the
> change does.

---

## Step 6 — Push the branch to GitHub

```bash
git push origin show-movie-count
```

You should see:

```
Enumerating objects: 7, done.
...
To https://github.com/your-team/moovover-10-teams.git
 * [new branch]      show-movie-count -> show-movie-count
```

**What happened:**

1. Your branch is now **on GitHub** — it is backed up (laptops break).
2. If you have **CI** (GitHub Actions), it starts running tests on your branch
   automatically.

---

## Step 7 — Open a Pull Request on GitHub

A **Pull Request** (PR) means: *"Please review my changes and merge them into
`main`."*

### Step 7a — Go to your repository on GitHub

Open your browser. Go to `https://github.com/your-team/moovover-10-teams`.

You should see a yellow banner near the top:

> **show-movie-count** had recent pushes — **Compare & pull request**

Click **"Compare & pull request"**.

(If you do not see the banner, click the **"Pull requests"** tab → click
**"New pull request"** → set **base:** `main` and **compare:**
`show-movie-count` → click **"Create pull request"**.)

### Step 7b — Fill in the PR form

**Title:** `Show movie count on index page`

**Description box** — write something like:

```
## What
Shows "Showing X movies" on the movie listing page.

## Why
Users can quickly see how many movies are in the database.

## How to test
1. Visit /movies
2. You should see "Showing N movies" below the heading
```

### Step 7c — Choose a reviewer

On the right side, click **"Reviewers"** and select a teammate.

### Step 7d — Click "Create pull request"

Done! Your PR is now open. The PR page shows:

- Your **description**
- The **diff** (the one-line change)
- **CI status** (yellow = running, green ✓ = passed, red ✗ = failed)

> **Lecture link:** Slides 25–26 — pull requests.

---

## Step 8 — Set up CI so tests run automatically

**CI** (Continuous Integration) means: every time someone pushes code, a
machine runs the tests automatically. We use **GitHub Actions** for this.

You only need to do this **once** for the repository. After that, every push
and every PR triggers the tests.

### Step 8a — Create the workflow file

GitHub Actions reads instructions from a file inside `.github/workflows/`.
Create this folder and file in your project:

```bash
mkdir -p .github/workflows
```

Now create the file `.github/workflows/ci.yml` with the following content:

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
          ruby-version: '3.3.8'   # must match the version in Gemfile
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

- `name: CI` — the name shown on GitHub
- `on: push / pull_request` — run this on every push to `main` and on every PR
  that targets `main`
- `runs-on: ubuntu-latest` — use a Linux machine (free for public repos)
- `actions/checkout@v4` — downloads your code onto the machine
- `ruby/setup-ruby@v1` — installs Ruby; `bundler-cache: true` runs
  `bundle install` and caches gems so later runs are faster
- `db:create` + `db:schema:load` — creates a fresh test database (SQLite)
- `bundle exec rspec` — **runs all your tests**

### Step 8b — Commit and push the CI file

If you are still on your feature branch:

```bash
git add .github/workflows/ci.yml
git commit -m "Add GitHub Actions CI to run RSpec on push and PR"
git push origin show-movie-count
```

(Alternatively, you can add CI in a **separate** branch and PR first, so `main`
gets CI before your feature. Either way works for a class project.)

### Step 8c — See CI run on GitHub

Go to your PR page on GitHub. Near the bottom you will see a new section:

```
Some checks haven't completed yet
  CI / test — ⏳ In progress
```

Wait a minute or two. It becomes one of:

- ✅ **Green check** — "All checks have passed" → ready to review
- ❌ **Red X** — "Some checks failed" → click **"Details"** to see the log

### Step 8d — Read a CI failure log

If CI shows ❌, click **"Details"**. You will see the full log. Scroll to the
**"Run RSpec"** step. It will look something like:

```
Failures:

  1) Movie.order_by_title returns movies sorted alphabetically
     Failure/Error: expect(Movie.order_by_title).to eq([alien, milk, zulu])
       NoMethodError: undefined method 'order_by_title' for Movie:Class
```

This tells you **which test** failed and **why**. Fix the code locally, commit,
push again. CI re-runs on the same PR automatically.

### Step 8e — Protect `main` with required checks (recommended)

You can tell GitHub: **do not allow merging** until CI passes.

1. Go to your repository on GitHub.
2. Click **Settings** (tab at the top).
3. In the left sidebar, click **Branches**.
4. Under "Branch protection rules", click **"Add branch protection rule"**.
5. Branch name pattern: `main`
6. Check ✅ **"Require status checks to pass before merging"**
7. In the search box, find and select **"test"** (the job name from your
   `ci.yml`).
8. Click **"Create"** (or **"Save changes"**).

Now nobody can merge a PR with failing tests. This is the lecture rule:
**`main` stays green**.

> **Lecture link:** Slides 47–49 — continuous integration. The lecture says:
> "branch protection (require green checks before merge) turns the habit into
> a rule, not only willpower."

---

## Step 9 — Code review

Your teammate (the reviewer) now reads your PR on GitHub.

### What the reviewer does

1. Go to the PR page.
2. Click the **"Files changed"** tab to see the diff.
3. Read the change. For our example it is one line:
   ```erb
   <p>Showing <%= @movies.count %> movies</p>
   ```
4. If they have a comment, they **click on the line number** next to the code.
   A comment box appears. They type a comment and click **"Start a review"**
   (or **"Add single comment"**).

   Example comment:
   > Nice! Small suggestion: maybe say "Showing 1 movie" (singular) when
   > count is 1? Not blocking though.

5. When done reading, the reviewer clicks **"Review changes"** (green button,
   top right). They choose one of:
   - **Comment** — just notes, no decision
   - **Approve** — the change looks good ✅
   - **Request changes** — something must be fixed first ❌

6. Click **"Submit review"**.

### What the author does

- **Read** the comments on the PR page.
- If there is a **required fix**, do it locally, commit, and push. The PR
  updates automatically.
- If it is a **small suggestion** (like singular/plural), you can fix it now or
  reply "will do in a follow-up" — both are fine.
- **If the comment thread gets long:** stop typing. Set up a 15-minute call or
  meeting. Voice fixes misunderstanding faster than long text.

> **Lecture link:** Slides 26, 37–38, 46 — code review and resolving long
> threads.

---

## Step 10 — Rebase when `main` has changed

While you waited for review, a **teammate may have merged another PR** into
`main`. Now your branch is **behind**. You need to update it before merging.

Let us **simulate** this situation so you can practice.

### Step 10a — Simulate a teammate's change on `main`

We will pretend to be a teammate who changes the footer. Go to **GitHub** in
your browser:

1. Go to the repository page (`https://github.com/your-team/moovover-10-teams`).
2. Make sure you are viewing the **`main`** branch (the dropdown at the top
   left should say `main`).
3. Navigate to `app/views/layouts/application.html.erb`. Click on the file
   name.
4. Click the **pencil icon** ✏️ (top right of the file) to edit.
5. Find the footer line (near the bottom):
   ```
   <small>MoovOver &copy; <%= Date.today.year %> | CSCI3100 Software Engineering - Lecture 6: JavaScript</small>
   ```
6. Change it to:
   ```
   <small>MoovOver &copy; <%= Date.today.year %> | CSCI3100 Software Engineering</small>
   ```
   (We removed "- Lecture 6: JavaScript".)
7. Click **"Commit changes…"**. In the dialog:
   - Commit message: `Simplify footer text`
   - Select: **"Commit directly to the `main` branch"**
   - Click **"Commit changes"**.

Now **`main` on GitHub has a new commit** that your local branch does not know
about.

### Step 10b — Fetch the updated `main` into your local machine

Go back to your terminal:

```bash
git fetch origin
```

This **downloads** new commits from GitHub but does **not change** your files
yet. You can check:

```bash
git log --oneline origin/main -3
```

You should see the "Simplify footer text" commit at the top:

```
e4f5g6h Simplify footer text
a1b2c3d (some earlier commit)
...
```

### Step 10c — Rebase your branch on top of the updated `main`

Make sure you are on your feature branch:

```bash
git checkout show-movie-count
```

Now **rebase**:

```bash
git rebase origin/main
```

**What rebase does:** it takes your commit ("Show movie count on index page")
and **replays** it **on top of** the latest `main`. Picture it like:

```
Before rebase:
  main:            A --- B --- C (Simplify footer text)
  your branch:     A --- B --- D (Show movie count)

After rebase:
  main:            A --- B --- C (Simplify footer text)
  your branch:     A --- B --- C --- D' (Show movie count)
```

Your change `D` is now **after** the teammate's change `C`.

If there is **no conflict**, you will see:

```
Successfully rebased and updated refs/heads/show-movie-count.
```

Done! Skip to step 10e.

### Step 10d — If there is a conflict (what it looks like and how to fix it)

Sometimes Git **cannot** combine two changes automatically. This happens when
**two people changed the same lines** in the same file. Git stops and says:

```
CONFLICT (content): Merge conflict in app/views/movies/index.html.erb
error: could not apply d1e2f3a... Show movie count on index page
```

Open the conflicting file. You will see **conflict markers**:

```erb
<<<<<<< HEAD
(the code from main)
=======
(your code)
>>>>>>> Show movie count on index page
```

**How to fix it:**

1. Open the file in your editor.
2. Look at both versions between `<<<<<<<` and `>>>>>>>`.
3. **Delete** the markers (`<<<<<<<`, `=======`, `>>>>>>>`) and keep the
   **correct** combined code.
4. **Save** the file.
5. Tell Git the conflict is resolved:

```bash
git add app/views/movies/index.html.erb
git rebase --continue
```

Git finishes the rebase.

**If you get confused** and want to **give up** the rebase and go back to how
things were before:

```bash
git rebase --abort
```

This is safe. Nothing is lost.

### Step 10e — Push the rebased branch

Rebase **rewrites** your commit (it gets a new ID). So you need to **force
push**:

```bash
git push --force-with-lease origin show-movie-count
```

`--force-with-lease` is a **safe** force push. It refuses if someone else
pushed to your branch at the same time. Always use this instead of
`--force`.

The PR on GitHub now shows your change **on top of** the latest `main`.

> **Lecture link:** Slide 24 — rebase and pull request.

---

## Step 11 — Merge the Pull Request

Now everything is ready:

- ✅ CI is **green**
- ✅ Reviewer **approved**
- ✅ Branch is **up to date** with `main`

### Step 11a — Merge on GitHub

Go to the PR page on GitHub. At the bottom you see a green button:
**"Merge pull request"**.

You may see a dropdown arrow ▾ next to the button. Click it to choose:

- **Create a merge commit** — keeps all your commits + adds a merge commit
- **Squash and merge** — combines your commits into one clean commit
- **Rebase and merge** — replays your commits on `main` without a merge commit

For a small feature like this, any option works. **Squash and merge** is simple
and clean.

Click the green button. Confirm.

### Step 11b — Delete the branch on GitHub

After merging, GitHub shows:
**"Pull request successfully merged. You can safely delete this branch."**

Click **"Delete branch"**. Short-lived branches should **die** after merge.
This keeps the repository clean.

> **Lecture link:** Slide 28 — feature branches should end soon.

---

## Step 12 — Update your local `main`

Back in your terminal:

```bash
git checkout main
git pull origin main
```

Now your local `main` has the merged feature.

Delete the local branch too (it is already merged):

```bash
git branch -d show-movie-count
```

You should see:

```
Deleted branch show-movie-count (was 7f3a1b2).
```

**Done!** Your feature is on `main`, tested, reviewed, and tracked in Git
history. The whole team can `git pull` and see the movie count.

---

## Step 13 — Undo mistakes

Things go wrong. Here is how to fix them.

### "I committed on `main` by accident"

```bash
git branch oops-feature            # save the commit to a new branch
git checkout main                   # go back to main
git reset --hard HEAD~1             # remove the last commit from main
git checkout oops-feature           # continue work on the branch
```

`HEAD~1` means "one commit before the current one."

### "I merged something bad (before pushing)"

```bash
git reset --hard ORIG_HEAD
```

`ORIG_HEAD` is where you were **before** the merge. This undoes the merge.

### "I want to throw away all uncommitted changes"

```bash
git checkout -- .
```

This resets **all** files to the last commit. **Careful:** your unsaved work
is gone.

### "I want to see who wrote a specific line"

```bash
git blame app/views/movies/index.html.erb
```

Shows **who** changed each line and **when**.

> **Lecture link:** Slide 33 — undo cheatsheet.

---

## Step 14 — Cherry-pick a fix to an old release (optional)

Sometimes you have a **release branch** (e.g. `release-v1.3`) for an older
version. A bug fix on `main` also needs to go to the old release. But you
do **not** want to merge **all** of `main` — it has unfinished features.

**Cherry-pick** copies **one specific commit** to another branch.

### Step 14a — Find the commit you want

```bash
git log --oneline main -5
```

```
a1b2c3d Show movie count on index page
e4f5g6h Simplify footer text
...
```

You want `a1b2c3d`.

### Step 14b — Apply it to the release branch

```bash
git checkout release-v1.3
git cherry-pick a1b2c3d
```

If there is no conflict, done. If there is a conflict, fix it the same way
as in Step 10d, then:

```bash
git add <file>
git cherry-pick --continue
```

Push the release branch:

```bash
git push origin release-v1.3
```

> **Lecture link:** Slide 30 — bugfix branches and cherry-pick.

---

## Quick-reference table

| What you want to do | Command |
|---|---|
| Clone a repo | `git clone <url>` |
| Switch to a branch | `git checkout <branch>` |
| Create + switch to new branch | `git checkout -b <branch>` |
| See which branch you are on | `git branch` |
| See what files changed | `git status` |
| See exact line changes | `git diff` |
| Stage a file for commit | `git add <file>` |
| Commit staged files | `git commit -m "message"` |
| Push branch to GitHub | `git push origin <branch>` |
| Download updates (no file change) | `git fetch origin` |
| Download + update files | `git pull origin <branch>` |
| Rebase on latest main | `git fetch origin && git rebase origin/main` |
| Force push after rebase | `git push --force-with-lease origin <branch>` |
| Cancel a rebase mid-way | `git rebase --abort` |
| Copy one commit to another branch | `git cherry-pick <commit-hash>` |
| Undo last commit (keep on branch) | `git reset --hard HEAD~1` |
| Undo a bad merge (before push) | `git reset --hard ORIG_HEAD` |
| See who wrote each line | `git blame <file>` |
| See commit history | `git log --oneline` |
| Delete a local branch | `git branch -d <branch>` |

---

## How this maps to the lecture

| Step in this guide | Lecture topic |
|---|---|
| 1. Pull latest main | Slide 61 — stale clone pitfall |
| 2. Create feature branch | Slides 20–22 — branch per feature |
| 3. Make the code change | Slide 59 — vertical slice |
| 4. Check what changed | Slide 33 — `git diff`, `git status` |
| 5. Stage and commit | Slide 23 — Git mechanics |
| 6. Push to GitHub | Slide 23 — push early for backup + CI |
| 7. Open a Pull Request | Slides 25–26 — pull requests |
| 8. CI runs | Slides 47–49 — continuous integration |
| 9. Code review | Slides 26, 37–38, 46 — review |
| 10. Rebase | Slide 24 — rebase when main moves |
| 11. Merge PR + delete branch | Slides 25, 28 — merge, short-lived branches |
| 12. Pull merged main locally | Slide 61 — stay in sync |
| 13. Undo mistakes | Slide 33 — undo cheatsheet |
| 14. Cherry-pick hotfix | Slide 30 — bugfix branches |

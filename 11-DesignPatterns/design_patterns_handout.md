# Lecture 11 handout: Design patterns

_Based on [`slides.pdf`](slides.pdf) for CSCI3100 Engineering Software as a Service_

---

## Patterns

### What is a design pattern?

A design pattern is a **reusable solution shape** for a problem that appears often. A pattern is:

- not a single library or class
- not a full finished design
- more like a blueprint that can be adapted to a new situation

Patterns promote **reuse of design**, not just reuse of code.

### Pattern categories mentioned in the lecture

| Category | Examples |
| --- | --- |
| Architectural patterns | MVC, Pipe and Filter, event-based design, layering |
| Computation patterns | FFT, dense linear algebra, sparse linear algebra |
| GoF design patterns | creational, structural, and behavioral patterns |

The lecture briefly listed all 23 GoF patterns, but the most important takeaway for this course is to understand the **purpose** of patterns rather than memorize the whole zoo.

### Two meta-patterns to remember

1. **Program to an interface, not an implementation**
2. **Prefer composition and delegation over inheritance**

These two ideas show up again and again in SOLID and in the concrete patterns from this lecture.

## 🧭 Just enough UML and CRC cards

### UML basics

The lecture only expects "just enough UML":

- **Inheritance**: an "is-a" relationship
- **Composition**: a strong "has-a" relationship; the part belongs to the whole
- **Aggregation**: a weaker "has-a" relationship

For example:

- `Car` is a subclass of `Vehicle`
- `Car` has an `Engine`
- `Engine` exposes operations such as `start()` and `stop()`

### CRC cards

CRC stands for **Class-Responsibility-Collaborator**.

A CRC card asks three useful questions:

- What should this class know or do?
- What is this class responsible for?
- Which other classes does it need to collaborate with?

CRC cards are a lightweight way to move from **user stories** to **candidate classes** without doing heavy formal design too early.

## 🧱 SOLID in practice

| Principle | Core question | Common smell | Common fix or pattern |
| --- | --- | --- | --- |
| Single Responsibility | Does this class have exactly one reason to change? | large class, low cohesion, "God object" | Extract Class, composition, delegation |
| Open/Closed | Can I add behavior without editing existing source? | `case` or `if` chains on type/format | Abstract Factory, Template Method, Strategy, Decorator |
| Liskov Substitution | Can a subtype safely stand in for its base type? | subclass breaks assumptions | prefer composition over bad inheritance |
| Dependency Injection | Are collaborators wired through abstractions rather than hard-coded? | hardwired constructors, awkward stubs | Adapter, Façade, Proxy, injected dependency |
| Demeter | Am I only talking to close collaborators? | long call chains, mock trainwrecks | delegation, Observer, Visitor |

### Single Responsibility Principle

**Definition:** a class should have one and only one reason to change.

Important ideas from the lecture:

- each responsibility creates a possible axis of change
- changes along one axis should not force unrelated changes
- very large model classes are often a warning sign
- **LCOM** (Lack of Cohesion of Methods) is a useful metric: high LCOM suggests the class may really be several classes glued together

Typical smell:

- a `User` model that handles authentication, billing, social features, reporting, formatting, and external API sync all in one file

Better direction:

- extract smaller classes or modules
- use composition and delegation
- look for "test seams" and mock trainwrecks as hints for extraction

```ruby
class Customer
  def initialize(identity:, address:)
    @identity = identity
    @address = address
  end

  def name
    @identity.name
  end

  def zip
    @address.zip
  end
end

class Identity
  attr_reader :name, :email

  def initialize(name:, email:)
    @name = name
    @email = email
  end
end

class Address
  attr_reader :street, :zip

  def initialize(street:, zip:)
    @street = street
    @zip = zip
  end
end
```

This version is easier to change because identity logic and address logic evolve independently.

### Open/Closed Principle

**Definition:** software entities should be **open for extension** but **closed for source modification**.

The classic smell from the lecture is a `case` statement on a type that keeps growing:

```ruby
class Report
  def initialize(format, title, text)
    @format = format
    @title = title
    @text = text
  end

  def output_report
    case @format
    when :html
      HtmlFormatter.new(self).output
    when :pdf
      PdfFormatter.new(self).output
    else
      raise "unknown format"
    end
  end
end
```

If we add `:markdown`, we must edit this class again. That is an OCP warning sign.

#### Abstract Factory

Abstract Factory helps when **object creation varies**, especially when the right concrete class is chosen at runtime.

Instead of spreading construction logic all over the codebase, we centralize it:

```ruby
class FormatterFactory
  def self.build(format)
    case format
    when :html then HtmlFormatter.new
    when :pdf  then PdfFormatter.new
    else
      raise "unknown format"
    end
  end
end

class Report
  def initialize(formatter:, title:, text:)
    @formatter = formatter
    @title = title
    @text = text
  end

  def output_report
    @formatter.output_report(self)
  end
end

report = Report.new(
  formatter: FormatterFactory.build(:pdf),
  title: "Midterm review",
  text: "Important topics..."
)
```

The lecture's point is not that `case` is always evil. It is that **construction decisions should not be duplicated everywhere**.

#### Template Method vs Strategy

- **Template Method**: the overall steps stay the same, but subclasses override individual steps
- **Strategy**: the task is the same, but different objects provide interchangeable algorithms

Template Method:

```ruby
class Report
  def output_report
    output_title
    output_header
    output_body
  end
end

class HtmlReport < Report
  def output_title
    puts "<h1>Title</h1>"
  end

  def output_header
    puts "<hr>"
  end

  def output_body
    puts "<p>Body</p>"
  end
end
```

Strategy:

```ruby
class Report
  def initialize(formatter:, title:, text:)
    @formatter = formatter
    @title = title
    @text = text
  end

  attr_reader :title, :text

  def output_report
    @formatter.output_report(self)
  end
end

class HtmlFormatter
  def output_report(report)
    puts "<h1>#{report.title}</h1>"
    puts "<p>#{report.text}</p>"
  end
end

class PdfFormatter
  def output_report(report)
    puts "PDF: #{report.title}"
    puts report.text
  end
end
```

In Ruby, Strategy is often especially convenient because duck typing makes the "interface" lightweight.

### Liskov Substitution Principle

**Definition:** if code works with an object of type `T`, it should also work correctly with any subtype of `T`.

This is about **behavioral substitutability**, not just matching method names.

The lecture's warning:

- a subtype that forces callers to change their assumptions is probably a bad subtype
- in Ruby, this matters even with duck typing, because collaborators still depend on behavioral contracts

Classic bad idea:

```ruby
class Rectangle
  attr_accessor :width, :height

  def area
    width * height
  end
end

class Square < Rectangle
  def width=(value)
    @width = value
    @height = value
  end

  def height=(value)
    @width = value
    @height = value
  end
end
```

Now suppose someone writes:

```ruby
def make_twice_as_wide(shape)
  shape.width = 10
  shape.height = 5
  shape.width = shape.width * 2
  shape.area
end
```

This behaves differently for `Square`, because the subtype changed the contract in a surprising way.

Better direction:

- avoid forcing a "square is a rectangle" inheritance when the behaviors do not line up cleanly
- use composition instead

### Dependency injection

**Definition:** classes whose collaborators may vary at runtime should depend on an intermediate abstraction rather than constructing concrete collaborators directly.

The key idea is sometimes called **dependency inversion**:

- instead of `A` directly depending on concrete `B`
- both `A` and `B` depend on a stable abstraction

Bad:

```ruby
class NewsletterSignup
  def subscribe(email)
    MailchimpList.new.subscribe(email)
  end
end
```

Better:

```ruby
class NewsletterSignup
  def initialize(email_list:)
    @email_list = email_list
  end

  def subscribe(email)
    @email_list.opt_in(email)
  end
end

class MailchimpAdapter
  def initialize(client)
    @client = client
  end

  def opt_in(email)
    @client.subscribe(email)
  end
end

class FakeEmailList
  attr_reader :emails

  def initialize
    @emails = []
  end

  def opt_in(email)
    @emails << email
  end
end
```

This helps in two ways:

- production code can swap providers without rewriting `NewsletterSignup`
- tests can inject `FakeEmailList` instead of using ad hoc stubs everywhere


### Demeter principle

**Definition:** only talk to your close collaborators, not strangers.

The lecture's rule of thumb:

- you can call methods on `self`
- you can call methods on your instance variables
- but you should avoid calling methods on the objects returned by those calls

Smell:

```ruby
customer.wallet.payment_method.charge(100)
```

This creates tight coupling and often leads to "mock trainwrecks" in tests.

Better:

```ruby
class Customer
  def initialize(wallet:)
    @wallet = wallet
  end

  def charge(amount)
    @wallet.charge(amount)
  end
end
```

Now callers only need to know `customer.charge(100)`.


## Design process, agility, and judgment

### Plan-and-document vs agile

The lecture does **not** say "all design up front is good" or "all design up front is bad."

Instead:

- Plan-and-Document can help teams reason about architecture explicitly
- Agile reminds us that many designs look good until real code and real user stories expose their weaknesses
- experienced developers may still plan for known constraints early, such as persistence or horizontal scaling

So the practical advice is:

- do **enough** early design to avoid obvious trouble
- let short iterations reveal what kinds of change actually matter
- then close the design against those changes

---

## The 6S checklist

The lecture ends with a practical checklist for clean code:

| Item | Meaning |
| --- | --- |
| Site | put code in the right place |
| SOLID | apply the SOLID design principles |
| SOFA | methods should be Short, do One thing, have Few arguments, and stay at a single level of Abstraction |
| Smells | look for design and code smells |
| Style | use a linter and consistent conventions |
| Sign-Off | get another person to review your code |

Related heuristics mentioned in the lecture from Sandi Metz:

- classes no longer than about 100 lines
- methods no longer than about 5 lines
- methods with no more than about 4 arguments
- controller actions naming at most 2 other classes and setting at most 1 instance variable for the view

Treat these as **helpful heuristics**, not laws of nature.

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Seed the MoovOver DB with some movies.
movies_data = [
  { title: 'Aladdin', rating: 'G', release_date: '25-Nov-1992' },
  { title: 'The Terminator', rating: 'R', release_date: '26-Oct-1984' },
  { title: 'When Harry Met Sally', rating: 'R', release_date: '21-Jul-1989' },
  { title: 'The Help', rating: 'PG-13', release_date: '10-Aug-2011' },
  { title: 'Chocolat', rating: 'PG-13', release_date: '5-Jan-2001' },
  { title: 'Amelie', rating: 'R', release_date: '25-Apr-2001' },
  { title: '2001: A Space Odyssey', rating: 'G', release_date: '6-Apr-1968' },
  { title: 'The Incredibles', rating: 'PG', release_date: '5-Nov-2004' },
  { title: 'Raiders of the Lost Ark', rating: 'PG', release_date: '12-Jun-1981' },
  { title: 'Chicken Run', rating: 'G', release_date: '21-Jun-2000' }
]

movies_data.each do |movie|
  Movie.find_or_create_by!(title: movie[:title]) do |m|
    m.rating = movie[:rating]
    m.release_date = movie[:release_date]
  end
end

puts "Created #{Movie.count} movies"

# Create sample moviegoers for demo (ESaaS §5.2)
# In production, these would be created via OAuth
moviegoers_data = [
  { name: 'Alice', email: 'alice@example.com', provider: 'developer', uid: 'alice123' },
  { name: 'Bob', email: 'bob@example.com', provider: 'developer', uid: 'bob456' },
  { name: 'Charlie', email: 'charlie@example.com', provider: 'developer', uid: 'charlie789' }
]

moviegoers_data.each do |mg|
  Moviegoer.find_or_create_by!(provider: mg[:provider], uid: mg[:uid]) do |m|
    m.name = mg[:name]
    m.email = mg[:email]
  end
end

puts "Created #{Moviegoer.count} moviegoers"

# Create sample reviews to demonstrate associations (ESaaS §5.3, §5.4)
# This demonstrates has_many :through relationships
if Review.count == 0
  alice = Moviegoer.find_by(name: 'Alice')
  bob = Moviegoer.find_by(name: 'Bob')
  charlie = Moviegoer.find_by(name: 'Charlie')

  aladdin = Movie.find_by(title: 'Aladdin')
  terminator = Movie.find_by(title: 'The Terminator')
  incredibles = Movie.find_by(title: 'The Incredibles')

  # Alice reviews (ESaaS §5.4 - Association proxy methods)
  # @movie.reviews.build(potatoes: 5) - build sets the movie_id foreign key automatically
  aladdin.reviews.create!(moviegoer: alice, potatoes: 5) if alice && aladdin
  terminator.reviews.create!(moviegoer: alice, potatoes: 4) if alice && terminator
  incredibles.reviews.create!(moviegoer: alice, potatoes: 5) if alice && incredibles

  # Bob reviews
  aladdin.reviews.create!(moviegoer: bob, potatoes: 4) if bob && aladdin
  terminator.reviews.create!(moviegoer: bob, potatoes: 5) if bob && terminator

  # Charlie reviews
  incredibles.reviews.create!(moviegoer: charlie, potatoes: 4) if charlie && incredibles

  puts "Created #{Review.count} reviews"
end

# Demonstrate scopes (ESaaS §5.8)
puts "\n--- Demonstrating Scopes ---"
puts "Movies for kids (G, PG): #{Movie.for_kids.pluck(:title).join(', ')}"

if Review.count > 0
  good_movies = Movie.with_good_reviews(3)
  puts "Movies with good reviews (avg > 3): #{good_movies.pluck(:title).join(', ')}" if good_movies.any?

  recent = Movie.recently_reviewed(30)
  puts "Recently reviewed movies (last 30 days): #{recent.pluck(:title).join(', ')}" if recent.any?
end

# Demonstrate has_many :through (ESaaS §5.5)
puts "\n--- Demonstrating has_many :through ---"
alice = Moviegoer.find_by(name: 'Alice')
if alice
  # @user.movies # movies rated by user (ESaaS §5.5)
  puts "Movies reviewed by Alice: #{alice.movies.pluck(:title).join(', ')}"
end

aladdin = Movie.find_by(title: 'Aladdin')
if aladdin
  # @movie.users # users who rated this movie (ESaaS §5.5)
  puts "Moviegoers who reviewed Aladdin: #{aladdin.moviegoers.pluck(:name).join(', ')}"
end

puts "\nSeeding complete!"

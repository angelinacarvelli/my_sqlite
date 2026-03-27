require_relative 'my_sqlite_request'

db_name = "users.db"
File.delete(db_name) if File.exist?(db_name) # On repart de zéro

db = SQLite3::Database.new db_name
db.execute("CREATE TABLE users (name TEXT, age INTEGER);")
db.close
# can change values here.
puts " TEST 1 : INSERT "
MySqliteRequest.new.insert("users").values({"name" => "Charlie", "age" => 30}).run

puts "Contenu actuel :"
puts MySqliteRequest.new.from("users").select("*").run

puts "\n TEST 2 : UPDATE (Bob -> Robert) "
MySqliteRequest.new.update("users").set({"name" => "ANAEE"}).where("name", "Bob").run
puts MySqliteRequest.new.from("users").select("*").where("name", "Robert").run

puts "\n TEST 3 : DELETE (Alice) "
MySqliteRequest.new.from("users").delete.where("name", "Alice").run

puts "\n RÉSULTAT FINAL (Trié par age DESC)"
res = MySqliteRequest.new.from("users").select("*").order(:desc, "age").run
res.each { |row| puts "#{row['name']} - #{row['age']} ans" }

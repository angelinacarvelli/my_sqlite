require 'readline'
require_relative 'my_sqlite_request'

# Transforme "name=Bob, age=20" en {name: "Bob", age: "20"}
def parse_pairs(info)
  return {} if info.nil? || info.empty?
  info.gsub(/[()]/, '').split(',').map do |pair|
    if pair.include?('=')
      key, value = pair.split('=', 2).map(&:strip)
      [key.to_sym, value]
    end
  end.compact.to_h 
end

puts "--- MySQLite CLI Ready (Table: users) ---"

while (input = Readline.readline('my_sqlite> ', true))
  break if input.downcase =~ /exit|quit/
  next if input.strip.empty?

  req = MySqliteRequest.new
  result = nil

  # On utilise des expressions régulières (Regex) pour être flexible sur les espaces
  case 
  when input =~ /^SELECT/i
    # SELECT id,name FROM users WHERE id=1
    parts = input.split(/\s+/)
    cols = parts[1].split(',')
    table = input.split(/FROM/i)[1].strip.split(/\s+/)[0]
    
    req.select(cols).from(table)
    
    if input =~ /WHERE/i
      where_part = input.split(/WHERE/i)[1].strip
      col, val = where_part.split('=').map(&:strip)
      req.where(col, val)
    end
    result = req.run

  when input =~ /^INSERT INTO/i
    # INSERT INTO users VALUES (name=Alice, age=25)
    table = input.split(/\s+/)[2]
    values_part = input.split(/VALUES/i)[1].strip
    req.insert(table).values(parse_pairs(values_part))
    result = req.run

  when input =~ /^UPDATE/i
    # UPDATE users SET name=Bob WHERE id=1
    table = input.split(/\s+/)[1]
    
    if input =~ /WHERE/i
      set_part = input.split(/SET/i)[1].split(/WHERE/i)[0].strip
      where_part = input.split(/WHERE/i)[1].strip
      col_w, val_w = where_part.split('=').map(&:strip)
      req.update(table).set(parse_pairs(set_part)).where(col_w, val_w)
    else
      set_part = input.split(/SET/i)[1].strip
      req.update(table).set(parse_pairs(set_part))
    end
    result = req.run

  when input =~ /^DELETE FROM/i
    table = input.split(/\s+/)[2]
    req.from(table).delete
    
    if input =~ /WHERE/i
      where_part = input.split(/WHERE/i)[1].strip
      col, val = where_part.split('=').map(&:strip)
      req.where(col, val)
    end
    result = req.run

  else
    result = "Commande non reconnue"
  end

  # Affichage du résultat
  if result.is_a?(Array)
    puts "Resultat :"
    result.each { |row| p row }
  else
    puts "=> #{result}"
  end
end

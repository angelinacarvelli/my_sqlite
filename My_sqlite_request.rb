require 'sqlite3'

class MySqliteRequest
  def initialize
    @type_of_request = :none
    @select_columns = []
    @where_params = []
    @table_name = nil
    @join_params = nil
    @order_params = nil
    @data = nil
  end

  def from(table_name)
    @table_name = table_name
    self # retourne l objet même
  end

  def select(columns)
    @type_of_request = :select
    @select_columns = columns.is_a?(Array) ? columns : [columns] # le ? = condition vrai faux
    self 
  end

  def where(column_name, value)
    @where_params << { column: column_name, value: value } #<< = mettre nouvel element fin tableau
    self
  end

  def join(column_on_db_a, filename_db_b, column_on_db_b)
    @join_params = { col_a: column_on_db_a, table_b: filename_db_b, col_b: column_on_db_b }
    self
  end

  def order(order, column_name)
    @order_params = { order: order, column: column_name }
    self
  end

  def insert(table_name)
    @type_of_request = :insert
    @table_name = table_name
    self
  end

  def values(data)
    @data = data
    self
  end

  def update(table_name)
    @type_of_request = :update
    @table_name = table_name
    self
  end

  def set(data)
    @data = data
    self
  end

  def delete
    @type_of_request = :delete
    self
  end

  def run
    return [] unless @table_name
    
    case @type_of_request
    when :select then execute_select
    when :insert then execute_insert
    when :update then execute_update
    when :delete then execute_delete
    else "Erreur : aucune action choisie"
    end
  end

  private

  def get_db
    # Si oublie .db sa rajoute 
    db_file = @table_name.end_with?(".db") ? @table_name : "#{@table_name}.db"
    db = SQLite3::Database.new db_file
    # Permet de recevoir les données sous forme de Hash
    db.results_as_hash = true
    db
  end

  def build_where_clause
    return "" if @where_params.empty? # Rien si pas de filtre
    # Transforme [{col: "age", val: 20}] en " WHERE age = '20'"
    " WHERE " + @where_params.map { |f| "#{f[:column]} = '#{f[:value]}'" }.join(" AND ")
  end

  def execute_select
    # Choisit les colonnes
    cols = (@select_columns.empty? || @select_columns.include?('*')) ? "*" : @select_columns.join(", ")
    sql = "SELECT #{cols} FROM #{@table_name}"
    
    if @join_params
      sql += " JOIN #{@join_params[:table_b]} ON #{@table_name}.#{@join_params[:col_a]} = #{@join_params[:table_b]}.#{@join_params[:col_b]}"
    end

    sql += build_where_clause # Ajoute les filtres
    
    # Ajoute le tri si demander
    if @order_params
      sql += " ORDER BY #{@order_params[:column]} #{@order_params[:order].to_s.upcase}"
    end
  
    db = get_db
    result = db.execute(sql) # envoie l ordre à SQLite
    db.close                 # ferme 
    result                   # renvoie ligne
  end
  
  def execute_insert
    keys = @data.keys.join(", ")                    # Liste colonne
    values = @data.values.map { |v| "'#{v}'" }.join(", ") # Liste valeur
    sql = "INSERT INTO #{@table_name} (#{keys}) VALUES (#{values})"
    
    db = get_db
    db.execute(sql) # Execute réellement l'insertion
    db.close
    "Insert successful" # Message de confirmation
  end
  
def execute_update
    # Transforme {name: "Robert"} en "name = 'Robert'"
    set_clause = @data.map { |k, v| "#{k} = '#{v}'" }.join(", ")
    sql = "UPDATE #{@table_name} SET #{set_clause}"
    sql += build_where_clause  # sert a ne pas tout modifier juste ce qu'il faut
    
    puts "DEBUG SQL: #{sql}"
    
    db = get_db
    db.execute(sql)
    db.close
    "Update successful"
  end

  def execute_delete
    sql = "DELETE FROM #{@table_name}" + build_where_clause
    
    db = get_db
    db.execute(sql)
    db.close
    "Delete successful"
  end
end

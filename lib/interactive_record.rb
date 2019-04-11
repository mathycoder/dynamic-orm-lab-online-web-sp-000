require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name 
    self.to_s.downcase + "s"
  end 
  
  def self.column_names 
    sql = %{
      PRAGMA table_info("#{self.table_name}")
    }
    table_info = DB[:conn].execute(sql)
    columns = []
    table_info.each{|col| columns << col["name"]}
    columns.compact 
  end 
  
  def initialize(attribute_hash={})
    attribute_hash.each do |key, value|
      self.send("#{key}=", value)
    end 
  end 
  
  def table_name_for_insert 
    self.class.table_name 
  end 
  
  def col_names_for_insert
    self.class.column_names.delete_if{|col| col == "id"}.join(", ") 
  end 
  
  def values_for_insert
    values_array = []
    self.class.column_names.each do |col|
      values_array << "'#{self.send(col)}'" if !self.send(col).nil?
    end 
    values_array.join(", ")
  end 
  
  def save 
    sql = %{
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    }
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end 
  
  def self.find_by_name(name)
    sql = %{
      SELECT * FROM #{self.table_name}
      WHERE name = '#{name}' 
    }
    the_hash = DB[:conn].execute(sql)
  end 
  
  def self.find_by(attribute_hash)
    attribute_hash.map do |key, value|
      sql = %{
        SELECT * FROM #{self.table_name}
        WHERE #{key.to_s} = '#{value}'
      }
      DB[:conn].execute(sql)  
    end.first  
  end 
end
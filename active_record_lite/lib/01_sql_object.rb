require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @columns.nil?
      arr = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL

      @columns = arr.first.map! { |x| x.to_sym }
    end

    @columns

  end



  def self.finalize!
    self.columns.each do |name|
      define_method(name) do
        self.attributes[name]
      end

      define_method("#{name}=") do |value|
        self.attributes[name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(result)
  end

  def self.parse_all(results)
    objects = []
    results.each do |hash|
      objects << self.new(hash)
    end

    objects
  end

  def self.find(id)
    db = self.all
    db.find { |obj| obj.id == id }
  end

  def initialize(params = {})
    params.each do |k ,v|
      if self.class.columns.include?(k.to_sym)
        self.send("#{k}=", v)
      else
        raise "unknown attribute '#{k}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| self.send(col)}
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.count).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.instance.last_insert_row_id
  end

  def update
    columns = self.class.columns.drop(1)
    columns = columns.map{|name| "#{name} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    UPDATE
      #{self.class.table_name}
    SET
      #{columns}
    WHERE
      id = #{self.id}
    SQL
  end

  def save
    if id.nil?
      self.insert
    else
      update
    end
  end
end

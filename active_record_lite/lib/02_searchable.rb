require 'byebug'
require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

    conditions = params.keys.map {|k| "#{k} = ?"}.join(" AND ")


    result = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{conditions}
    SQL

    result.map { |r| self.new(r)}
  end


end

class SQLObject
  extend Searchable
end

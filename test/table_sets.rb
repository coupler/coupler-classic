module TableSets
  SETS = {
    :basic_cross_linkage => {
      :table_name => :records,
      :data => <<-EOF
          +-------------+-----------------+-----------------+
          | id(Integer) | uno_col(String) | dos_col(String) |
          +=============+=================+=================+
          | 18          | foo             |                 |
          | 16          | foo             |                 |
          | 17          | foo             |                 |
          | 15          |                 | foo             |
          | 13          |                 | foo             |
          | 10          |                 | foo             |
          | 19          |                 | foo             |
          | 25          | bar             |                 |
          | 23          | bar             |                 |
          | 20          | bar             |                 |
          | 29          | bar             |                 |
          | 28          |                 | bar             |
          | 26          |                 | bar             |
          | 27          |                 | bar             |
          | 38          | baz             |                 |
          | 35          |                 | baz             |
          | 33          |                 | baz             |
          | 30          |                 | baz             |
          | 39          |                 | baz             |
          | 45          | quux            |                 |
          | 43          | quux            |                 |
          | 40          | quux            |                 |
          | 49          | quux            |                 |
          | 48          |                 | quux            |
          | 55          | ditto           | ditto           |
          | 53          | ditto           | ditto           |
          +-------------+-----------------+-----------------+
        EOF
    }
  }

  def load_table_set(name)
    set = SETS[name]
    TableMaker.new(test_database, set[:table_name], set[:data])
  end

  def unload_table_set(name)
    test_database.drop_table(SETS[name][:table_name])
  end
end

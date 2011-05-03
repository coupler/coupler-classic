require 'helper'

class TestImport < Coupler::Test::IntegrationTest

  test "import!" do
    project = Project.create(:name => "foo")
    import = Import.create(:data => fixture_file_upload("people.csv"), :project => project)
    import.import!
    assert_not_nil import.occurred_at

    project.local_database do |db|
      name = :"import_#{import.id}"
      assert db.tables.include?(name)
      schema = db.schema(name)
      assert_equal [:integer, true], schema.assoc(:id)[1].values_at(:type, :primary_key)
      assert_equal :string, schema.assoc(:first_name)[1][:type]
      assert_equal :string, schema.assoc(:last_name)[1][:type]
      assert_equal :integer, schema.assoc(:age)[1][:type]

      ds = db[name]
      assert_equal 50, ds.count
    end
  end

  test "flags duplicate primary keys" do
    tempfile = Tempfile.new('coupler-import')
    tempfile.write("id,foo,bar\n1,abc,def\n2,ghi,jkl\n2,mno,pqr")
    tempfile.close

    project = Project.create(:name => "foo")
    import = Import.create(:data => file_upload(tempfile.path), :project => project)

    assert !import.import!
    assert import.has_duplicate_keys

    project.local_database do |db|
      ds = db[:"import_#{import.id}"]
      assert ds.filter(:id => 2).select_map(:dup_key_count).all?
    end
  end

  test "repair duplicate keys" do
    project = Project.create(:name => "foo")
    import = Import.create(:data => fixture_file_upload('duplicate-keys.csv'), :project => project)
    import.import!

    import.repair_duplicate_keys!(nil)
    import.dataset do |ds|
      assert !ds.columns!.include?(:dup_key_count)
      assert_equal 1, ds.filter(:id => 2).count
      assert_equal 1, ds.filter(:id => 4).count
    end
    project.local_database do |db|
      assert db.schema(:"import_#{import.id}").assoc(:id)[1][:primary_key]
    end
  end

  test "repair duplicate keys with deletions" do
    tempfile = Tempfile.new('coupler-import')
    tempfile.write("id,foo,bar\n1,2,3\n1,4,5\n1,6,7\n123,456,789\n")
    tempfile.close

    project = Project.create(:name => "foo")
    import = Import.create(:data => file_upload(tempfile.path), :project => project)
    import.import!

    import.repair_duplicate_keys!({"1" => ["1"]})
    import.dataset do |ds|
      assert !ds.columns!.include?(:dup_key_count)
      assert_equal 1, ds.filter(:id => 1).count
      assert_equal 1, ds.filter(:id => 124).count
      assert_equal 0, ds.filter(:id => 125).count
    end
    project.local_database do |db|
      assert db.schema(:"import_#{import.id}").assoc(:id)[1][:primary_key]
    end
  end
end

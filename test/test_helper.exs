# TwMerge's cache is a named ETS table. Create it once here, owned by this
# long-lived process. Creating it in each test's setup tied it to the test
# process, so concurrent async tests raced on the name ("table name already
# exists") and it was torn down after every test.
TwMerge.Cache.create_table()

ExUnit.start()

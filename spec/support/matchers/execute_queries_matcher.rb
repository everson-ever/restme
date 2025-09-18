# frozen_string_literal: true

IGNORED_SQL = /
  TRANSACTION
  | pg_tables
  | sqlite_master
  | SHOW
  | SAVEPOINT
  | ROLLBACK
  | RELEASE
  | generate_subscripts
  | pg_attribute
  | INSERT
/x

RSpec::Matchers.define :execute_queries do |expected_queries|
  supports_block_expectations

  def capture_sql(&block)
    executed_queries = []

    callback = lambda do |*_, payload|
      sql = payload[:sql].squish
      executed_queries << sql unless sql.match?(IGNORED_SQL)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)

    executed_queries
  end

  match do |block|
    actual = capture_sql(&block)

    actual == expected_queries
  end

  failure_message do |block|
    actual = capture_sql(&block)
    <<~MSG
      expected queries:
      #{expected_queries.join("\n")}

      but got:
      #{actual.join("\n")}
    MSG
  end
end

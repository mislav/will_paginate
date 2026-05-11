RSpec::Matchers.define :execute do |expected_count|
  match do |block|
    run(block)

    if expected_count.respond_to? :include?
      expected_count.include? @count
    else
      @count == expected_count
    end
  end

  def run(block)
    $query_count = 0
    $query_sql = []
    block.call
  ensure
    @queries = $query_sql.dup
    @count = $query_count
  end

  chain(:queries) {}
  supports_block_expectations

  failure_message do
    "expected #{expected_count} queries, got #{@count}\n#{@queries.join("\n")}"
  end

  failure_message_when_negated do
    "expected query count not to be #{expected_count}"
  end
end

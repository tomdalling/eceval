require_relative '../test_init'

context Eceval do
  def augment(text, input_lineno = 0)
    input = StringIO.new(text)
    output = StringIO.new
    Eceval.augment(input, out: output, filename: __FILE__, lineno: input_lineno + 1)
    output.string
  end

  def assert_augments_to(text, input_lineno, expected_output)
    actual_output = augment(text, input_lineno)
    begin
      assert(actual_output == expected_output, caller_location: caller_locations.first)
    rescue TestBench::Fixture::AssertionFailure => ex
      detail "\n\n" + SuperDiff::Differs::Main.call(expected_output, actual_output) + "\n\n"
      raise
    end
  end

  test "inserts the result of evaluating ruby code inside fenced code blocks" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        ```ruby
        1 + 1 #=>
        ```
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        ```ruby
        1 + 1 #=> 2
        ```
      END_EXPECTED_OUTPUT
    )
  end

  test "outputs exceptions when directed to" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        ```ruby
        raise "catch me"
          #=> !!!
        ```
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        ```ruby
        raise "catch me"
          #=> !!! RuntimeError: catch me
        ```
      END_EXPECTED_OUTPUT
    )
  end

  test "fails if there is supposed to be an exception, but there isn't" do
    message = <<~END_MESSAGE.strip.gsub(/\s+/, ' ')
      Expected an exception at `#{__FILE__}:2` but none was raised. Instead, the
      code evaluated to: 2
    END_MESSAGE

    assert_raises(Eceval::NoExceptionRaised, message) do
      augment(<<~END_INPUT)
        ```ruby
        1 + 1 #=> !!!
        ```
      END_INPUT
    end
  end

  test "does not swallow exceptions by default" do
    assert_raises(RuntimeError, "hello") do
      augment(<<~END_INPUT)
        ```ruby
        raise "hello"
        ```
      END_INPUT
    end
  end

  test "allows markers to be on a new line" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        ```ruby
        3 + 3
          #=>
        ```
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        ```ruby
        3 + 3
          #=> 6
        ```
      END_EXPECTED_OUTPUT
    )
  end

  test "uses #inspect to generate output" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        ```ruby
        class X; def inspect; 'wawawa'; end; end
        X.new #=>
        ```
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        ```ruby
        class X; def inspect; 'wawawa'; end; end
        X.new #=> wawawa
        ```
      END_EXPECTED_OUTPUT
    )
  end

  test "does not affect normal markdown" do
    markdown = <<~END_MARKDOWN
      # title

      Paragraph with [a link](to_somewhere.html).

       - list 1
       - list 2

      > blockquote

      h2 title
      --------

      Para with *italics* and **bold** and ~~strikethrough~~ and `inline code`.

          def indented_code_block
            raise "shouldn't run this"
          end
          indented_code_block

      [linkref]: http://example.com
    END_MARKDOWN

    assert_augments_to(markdown, __LINE__-23, markdown)
  end

  test "carries a scope across code blocks" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        ```ruby
        MY_CONST = 5
        ```
        markdown markdown markdown
        ```ruby
        MY_CONST #=>
        ```
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        ```ruby
        MY_CONST = 5
        ```
        markdown markdown markdown
        ```ruby
        MY_CONST #=> 5
        ```
      END_EXPECTED_OUTPUT
    )
  end

  test "does not try to evaluate document text" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        1 + 1 #=>
        ```ruby
        2 + 2 #=>
        ```
        3 + 3 #=>
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        1 + 1 #=>
        ```ruby
        2 + 2 #=> 4
        ```
        3 + 3 #=>
      END_EXPECTED_OUTPUT
    )
  end

  test "handles trailing whitespace after markers" do
    assert_augments_to(
      <<~END_INPUT, __LINE__,
        ```ruby
        2 + 2 #=>    
        6 / 0 #=> !!!    
        ```
      END_INPUT
      <<~END_EXPECTED_OUTPUT
        ```ruby
        2 + 2 #=> 4
        6 / 0 #=> !!! ZeroDivisionError: divided by 0
        ```
      END_EXPECTED_OUTPUT
    )
  end
end

require 'open3'
require_relative '../test_init'
require_relative '../../lib/eceval/cli'

context Eceval::CLI do
  markdown_path = TEST_TMP_DIR / "cli_test.md"
  markdown_path.write(<<~END_MARKDOWN)
    # Ruby Math

    Do Ruby math like this:

    ```ruby
    # check that `--load_path` and `--require` worked
    Eceval.name #=>
    1 + 1 #=>
    6 / 2 #=>
    6 / 0 #=> !!!
    ```

    Easy peasy.
  END_MARKDOWN

  bin_path = TEST_ROOT_DIR / '../exe/eceval'
  out_str, err_str, exit_status = Open3.capture3(
    bin_path.to_path,
    '--require=eceval',
    '--load_path=../lib/',
    markdown_path.to_path,
    chdir: TEST_ROOT_DIR.to_path,
  )

  test "it exits successfully" do
    assert(exit_status.success?)
  end

  test "outputs the augmented markdown" do
    assert(out_str == <<~END_MARKDOWN)
      # Ruby Math

      Do Ruby math like this:

      ```ruby
      # check that `--load_path` and `--require` worked
      Eceval.name #=> "Eceval"
      1 + 1 #=> 2
      6 / 2 #=> 3
      6 / 0 #=> !!! ZeroDivisionError: divided by 0
      ```

      Easy peasy.
    END_MARKDOWN
  end

  test "does not output to stderr" do
    assert(err_str.empty?)
  end
end

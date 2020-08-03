require 'dry/cli'
require_relative '../eceval'

module Eceval::CLI
  def self.run(argv: ARGV, out: $stdout, err: $stderr)
    old_out = $stdout
    old_err = $stderr

    begin
      $stdout = out
      $stderr = err
      Dry::CLI.new(Command).call(arguments: argv, out: out, err: err)
    ensure
      $stdout = old_out
      $stderr = old_err
    end
  end

  class Command < Dry::CLI::Command
    desc "Outputs the given markdown file after augmenting the code blocks with the results of evaluation"
    argument :path, type: :string, required: true, desc: "The path the to markdown file. Reads from STDIN if the path is '-'."
    option :require, type: :array, default: [], desc: "Libraries to load using `require`"
    option :load_path, type: :array, default: [], desc: "Paths to add to $LOAD_PATH"

    example [
      "path/to/my_file.md",
      "--load_path=lib --require=mygem README.md  # load the gem in this repo before evaluation",
    ]

    def call(path:, require:, load_path:, **)
      $LOAD_PATH.unshift(*load_path)
      require.each { |lib| require lib }

      if path == '-'
        Eceval.augment($stdin, filename: "[STDIN]")
      else
        File.open(path) do |file|
          Eceval.augment(file, filename: path)
        end
      end
    end
  end
end

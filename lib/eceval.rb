# frozen_string_literal: true
require 'stringio'

ECEVAL_MAIN_BINDING = binding

module Eceval
  EVAL_MARKER = "#=>"
  CONTINUATION_MARKER = "#=*"
  EVAL_EXCEPTION_MARKER = "#=> !!!"
  STDOUT_MARKER = "# outputs:"
  BEGIN_CODE_BLOCK = '```ruby'
  END_CODE_BLOCK = '```'
  NEW_SCOPE_DIRECTIVE = '# eceval: new_scope'

  NoExceptionRaised = Class.new(RuntimeError)

  def self.augment(io, out: $stdout, filename: "[String]", lineno: 1)
    context = EvaluationContext.new(filename: filename, lineno: lineno)
    loop do
      break if io.eof?
      line = io.gets
      out.puts(context.process_line(line.chomp))
    end
  end

  class EvaluationContext
    attr_reader :filename, :lineno

    def initialize(filename:, lineno: 1)
      @filename = filename
      @lineno = lineno
      @lines_consumed = 0
      @chunk = nil
      @eval_stdout = StringIO.new
    end

    def process_line(line)
      if @chunk
        process_code_line(line)
      else
        process_noncode_line(line)
      end
    ensure
      @lines_consumed += 1
    end

    private

      def process_noncode_line(line)
        begin_chunk if line.strip == BEGIN_CODE_BLOCK
        line
      end

      def begin_chunk
        raise "Already chunkin" if @chunk

        @chunk = Chunk.new(
          filename: filename,
          lineno: lineno + @lines_consumed + 1, # starts on next line
        )
      end

      def process_code_line(line)
        if line.strip == END_CODE_BLOCK
          consume_chunk
          line
        elsif line.strip == NEW_SCOPE_DIRECTIVE
          reset_scope
          line
        else
          process_chunk_line(line)
        end
      end

      def process_chunk_line(line)
        @chunk << line

        if line.rstrip.end_with?(EVAL_MARKER)
          result = consume_chunk
          begin_chunk
          line.rstrip + ' ' + result.inspect
        elsif line.rstrip.end_with?(EVAL_EXCEPTION_MARKER)
          ex = consume_chunk(rescue_exceptions: true)
          begin_chunk
          format_exception(line.rstrip, ex)
        elsif line.rstrip.end_with?(STDOUT_MARKER)
          consume_chunk
          begin_chunk
          output = @eval_stdout.string.chomp
          @eval_stdout.string = ''

          line + ' ' + output
        else
          line
        end
      end

      def consume_chunk(rescue_exceptions: false)
        old_chunk = @chunk
        old_stdout = $stdout
        @chunk = nil

        begin
          $stdout = @eval_stdout
          old_chunk.evaluate
        rescue Exception => ex
          if rescue_exceptions
            return ex
          else
            raise
          end
        ensure
          $stdout = old_stdout
        end
      end

      def format_exception(line, ex)
        unless ex.is_a?(Exception)
          raise NoExceptionRaised, "Expected an exception at #{current_pos}" \
            " but none was raised. Instead, the code evaluated to: " +
            ex.inspect
        end

        # for multiline exception messages, indent them to line up with the first line
        indentation = CONTINUATION_MARKER + ' '*(line.length - CONTINUATION_MARKER.length + 1)
        ex_message = ex.message
          .lines
          .map(&:chomp)
          .join("\n" + indentation)

        "#{line} #{ex.class}: #{ex_message}"
      end

      def current_pos
        "`#{filename}:#{lineno + @lines_consumed}`"
      end
  end

  class Chunk
    attr_reader :filename, :lineno

    def initialize(filename:, lineno:)
      @filename = filename
      @lineno = lineno
      @buffered_lines = []
    end

    def <<(line)
      @buffered_lines << line
    end

    def evaluate
      ECEVAL_MAIN_BINDING.eval(@buffered_lines.join("\n"), filename, lineno)
    end
  end
end

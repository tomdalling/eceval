require 'test_bench'
require 'byebug'
require 'super_diff'
require 'delegate'
require 'pathname'

require_relative '../lib/eceval'

TEST_ROOT_DIR = Pathname(__dir__)
TEST_TMP_DIR = TEST_ROOT_DIR / 'tmp'

TEST_ROOT_DIR.mkdir unless TEST_ROOT_DIR.directory?

TestBench.activate

# -*- coding: utf-8 -*-

#
# Taken from the [Aruba project](). Original license:
#
#         Copyright (c) 2010 Aslak Hellesøy, David Chelimsky
#
#         Permission is hereby granted, free of charge, to any person obtaining
#         a copy of this software and associated documentation files (the
#         "Software"), to deal in the Software without restriction, including
#         without limitation the rights to use, copy, modify, merge, publish,
#         distribute, sublicense, and/or sell copies of the Software, and to
#         permit persons to whom the Software is furnished to do so, subject to
#         the following conditions:
#
#         The above copyright notice and this permission notice shall be
#         included in all copies or substantial portions of the Software.
#
#         THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#         EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#         MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#         NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#         LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#         OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#         WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


require 'childprocess'
require 'tempfile'

module Wukong
  class Runner

    class Process
      attr_reader :keep_ansi

      def initialize(cmd, exit_timeout=2.0, io_wait=2.0, keep_ansi=true)
        @exit_timeout = exit_timeout
        @io_wait      = io_wait
        @keep_ansi    = true

        @process           = ChildProcess.build(*cmd)
        @process.io.stdout = raw_out_io
        @process.io.stderr = raw_err_io
        @process.duplex    = true
      end

      def raw_out_io
        @raw_out_io ||= StringIO.new('', 'w')
      end

      def raw_err_io
        @raw_err_io ||= StringIO.new('', 'w')
      end

      def run!(&block)
        @process.start
        yield self if block_given?
      end

      def stdin
        wait_for_io do
          @process.io.stdin.sync = true
          @process.io.stdin
        end
      end

      def output
        stdout + stderr
      end

      def stdout
        wait_for_io do
          @raw_out_io.rewind
          filter_ansi(@raw_out_io.read)
        end
      end

      def stderr
        wait_for_io do
          @raw_err_io.rewind
          filter_ansi(@raw_err_io.read)
        end
      end

      def stop(reader)
        return unless @process
        unless @process.exited?
          reader.stdout stdout
          reader.stderr stderr
          @process.poll_for_exit(@exit_timeout)
        end
        @process.exit_code
      end

      def terminate
        if @process
          flush
          @process.stop
          flush
        end
      end

      def flush
        stdout && stderr # flush output
      end

    private

      def wait_for_io(&block)
        sleep @io_wait if @process.alive?
        yield
      end

      def filter_ansi(string)
        keep_ansi ? string : string.gsub(/\e\[\d+(?>(;\d+)*)m/, '')
      end

    end
  end
end

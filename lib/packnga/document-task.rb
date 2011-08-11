# -*- coding: utf-8 -*-
#
# Copyright (C) 2011  yoshihara haruka <yoshihara@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "pathname"

module Packnga
  class DocumentTask
    include Rack::DSL

    attr_writer :readme, :base_dir
    def initialize(spec)
      @spec = spec
      @yardoc_task_defined = false
      @yardoc_task = nil
      @readme = nil
      @text_files = nil
      @base_dir = nil
      @files = spec.files.find_all do |file|
        /\.rb\z/ =~ file
      end
      yield(self)
      set_default_values
      define_tasks
    end

    def readme
      @readme || Rake::FileList["README*"].to_a.first
    end

    def text_files
      @text_files ||= []
    end

    def yard(&block)
      set_default_values
      define_yardoc_task(&block)
    end

    private
    def set_default_values
      if @text_files.nil?
        @text_files = ["doc/text/**/*"] if File.directory?("doc/text")
      end
      @base_dir ||= "doc"
    end

    def reference_dir
      Pathname.new(@base_dir) + "reference"
    end

    def reference_en_dir
      reference_dir + "en"
    end

    def define_tasks
      define_yard_task
    end

    def define_yardoc_task
      YARD::Rake::YardocTask.new do |yardoc_task|
        yardoc_task.options += ["--title", @spec.name]
        yardoc_task.options += ["--readme", readme]
        @text_files.each do |file|
          yardoc_task.options += ["--files", file]
        end
        yardoc_task.options += ["--output-dir", reference_en_dir.to_s]
        yardoc_task.options += ["--charset", "utf-8"]
        yardoc_task.files += @files
        yield(yardoc_task) if block_given?
      end
      @yardoc_task_defined = true
    end

    def define_yard_task
      define_yardoc_task unless @yardoc_task_defined

      task :yard do |yard_task|
        reference_en_dir.find do |path|
          next if path.extname != ".html"
          html = path.read
          html = html.gsub(/<div id="footer">.+<\/div>/m,
                           "<div id=\"footer\"></div>")
          path.open("w") do |html_file|
            html_file.print(html)
          end
        end
      end
    end
  end
end

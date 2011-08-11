# -*- coding: utf-8 -*-
#
# Copyright (C) 2011  yoshihara haruka <yoshihara@clear-code.com>
# Copyright (C) 2011  Kouhei Sutou <kou@clear-code.com>
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

require "yard"

module Packnga
  class YARDTask
    include Rake::DSL

    attr_writer :readme
    attr_accessor :base_dir
    def initialize(spec)
      @spec = spec
      @hooks = []
      @readme = nil
      @text_files = nil
      @base_dir = nil
      @files = spec.files.find_all do |file|
        /\.rb\z/ =~ file
      end
      if block_given?
        yield(self)
        define
      end
    end

    def readme
      @readme || Rake::FileList["README*"].to_a.first
    end

    def text_files
      @text_files ||= []
    end

    def define
      set_default_values
      define_tasks
    end

    def before_define(&hook)
      @hooks << hook
    end

    private
    def set_default_values
      @base_dir ||= "doc"
      @base_dir = Pathname.new(@base_dir)
      if @text_files.nil?
        text_dir = @base_dir + "text"
        @text_files = [(text_dir + "**/*").to_s] if text_dir.directory?
      end
    end

    def reference_dir
      @base_dir + "reference"
    end

    def reference_en_dir
      reference_dir + "en"
    end

    def define_tasks
      define_yardoc_task
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
        @hooks.each do |hook|
          hook.call(yardoc_task)
        end
      end
    end

    def define_yard_task
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

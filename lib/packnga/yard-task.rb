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
  # This class creates YARD task.
  # YARD task generates references by YARD.
  #
  # @since 0.9.0
  class YARDTask
    include Rake::DSL

    # This attribute is used to sets README file to yardoc task.
    # @return [String] path to readme file
    attr_accessor :readme

    # @return [String] path of base directory of document.
    attr_accessor :base_dir

    # @return [Array<String>] document target files.
    attr_accessor :source_files

    attr_accessor :text_files

    # @return [Array<String>] custom yardoc command line options.
    attr_accessor :options

    # @private
    def initialize(spec)
      @spec = spec
      @hooks = []
      @readme = nil
      @text_files = nil
      @base_dir = nil
      @options = []
      @source_files = nil
    end

    # @private
    def text_files
      @text_files ||= []
    end

    # @private
    def define
      set_default_values
      define_tasks
    end

    # Regists yardoc parameters with block.
    def before_define(&hook)
      @hooks << hook
    end

    private
    def set_default_values
      @base_dir ||= "doc"
      @base_dir = Pathname.new(@base_dir)
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
        yardoc_task.options += ["--no-private"]
        yardoc_task.options += @options
        yardoc_task.files += @source_files
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

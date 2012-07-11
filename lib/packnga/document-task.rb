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

require "pathname"
require "packnga/yard-task"
require "packnga/reference-task"

module Packnga
  # This class creates docment tasks.
  # They generate YARD doucment or references.
  #
  # @since 0.9.0
  class DocumentTask
    include Rake::DSL
    # Defines tasks to generate YARD documentation
    # and to translate references.
    # @param [Gem::Specification] spec specification for your package.
    def initialize(spec)
      @spec = spec
      @yard_task = YARDTask.new(@spec)
      @reference_task = ReferenceTask.new(@spec)
      self.base_dir = "doc"
      yield(self) if block_given?
      define
    end

    # Sets base directory for documents. Default value is "doc".
    # @param [String] dir base direcory path
    def base_dir=(dir)
      dir = Pathname.new(dir)
      @yard_task.base_dir = dir
      @reference_task.base_dir = dir
    end

    # Runs block to task for YARD documentation.
    def yard
      yield(@yard_task)
    end

    # Runs block to tasks for references.
    def reference
      yield(@reference_task)
    end

    def htaccess
      @reference_task.htaccess
    end

    private
    # @private
    def define
      set_default_values
      define_tasks
    end

    def set_default_values
    end

    def define_tasks
      @yard_task.define
      @reference_task.define
    end
  end
end

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

module Packnga
  class DocumentTask
    # This class creates docment tasks.
    #
    # @since 1.0.0
    include Rake::DSL
    # Defines task to generate YARD documentation.
    # @param [Jeweler::Task] spec created by Jeweler::Task.new.
    def initialize(spec)
      @spec = spec
      @yard_task = YARDTask.new(@spec)
      @reference_task = ReferenceTask.new(@spec)
      self.base_dir = "doc"
      if block_given?
        yield(self)
        define
      end
    end

    # @private
    def define
      set_default_values
      define_tasks
    end

    # Sets yard base directory.
    # @param [String] yard base direcory path
    def base_dir=(dir)
      dir = Pathname.new(dir)
      @yard_task.base_dir = dir
      @reference_task.base_dir = dir
    end

    # Sets parameters for yard task.
    #   Parameters can be written in block of DocumentTask.new.
    def yard
      yield(@yard_task)
    end

    def reference
      yield(@reference_task)
    end

    private
    def set_default_values
    end

    def define_tasks
      @yard_task.define
      @reference_task.define
    end
  end
end

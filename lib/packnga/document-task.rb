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
    include Rake::DSL

    attr_writer :base_dir
    def initialize(spec)
      @spec = spec
      @yard_task = YARDTask.new(@spec)
      @base_dir = Pathname.new("doc")
      if block_given?
        yield(self)
        define
      end
    end

    def define
      set_default_values
      define_tasks
    end

    def yard
      yield(@yard_task)
    end

    private
    def set_default_values
      @yard_task.base_dir ||= @base_dir
    end

    def define_tasks
      @yard_task.define
    end
  end
end

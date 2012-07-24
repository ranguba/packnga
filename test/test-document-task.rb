# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  yoshihara haruka <yoshihara@clear-code.com>
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

class DocumentTaskTest < Test::Unit::TestCase
  def test_base_directory_set
    spec = Gem::Specification.new
    base_dir = Pathname("base_directory")
    document_task = Packnga::DocumentTask.new(spec) do |task|
      task.base_dir = base_dir.to_s
    end

    document_task.yard do |yard_task|
      assert_equal(base_dir, yard_task.base_dir)
    end

    document_task.reference do |reference_task|
      assert_equal(base_dir, reference_task.base_dir)
    end
  end
end

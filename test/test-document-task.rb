# -*- coding: utf-8 -*-
#
# Copyright (C) 2012 Haruka Yoshihara <yoshihara@clear-code.com>
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

  class SpecifyReadmeTest < self
    def setup
      @readme = "README.textile"
      spec = Gem::Specification.new do |_spec|
        _spec.files = [@readme]
      end
      document_task = Packnga::DocumentTask.new(spec)
      @yard_task = extract_yard_task(document_task)
      @reference_task = extract_reference_task(document_task)
    end

    def test_readme
      assert_equal(@readme, @yard_task.readme)
      assert_equal(@readme, @reference_task.readme)
    end

    def test_source_files
      assert_equal([], @yard_task.source_files)
      assert_equal([], @reference_task.source_files)
    end

    def test_text_files
      assert_equal([], @yard_task.text_files)
      assert_equal([], @reference_task.text_files)
    end
  end

  def test_specify_no_files
    spec = Gem::Specification.new
    document_task = Packnga::DocumentTask.new(spec)
    yard_task = extract_yard_task(document_task)
    reference_task = extract_reference_task(document_task)

    assert_nil(yard_task.readme)
    assert_nil(reference_task.readme)

    assert_equal([], yard_task.source_files)
    assert_equal([], reference_task.source_files)

    assert_equal([], yard_task.text_files)
    assert_equal([], reference_task.text_files)
  end

  private
  def extract_yard_task(document_task)
    document_task.yard do |yard_task|
      yard_task
    end
  end

  def extract_reference_task(document_task)
    document_task.reference do |reference_task|
      reference_task
    end
  end
end

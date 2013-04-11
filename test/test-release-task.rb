# -*- coding: utf-8 -*-
#
# Copyright (C) 2013 Haruka Yoshihara <yoshihara@clear-code.com>
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

require "test/unit/rr"
require "tmpdir"

class ReleaseTaskTest < Test::Unit::TestCase
  def teardown
    Rake::Task.clear
  end

  def test_upload_references
    Dir.mktmpdir do |base_dir|
      package_name = "packnga"
      index_dir = File.join(base_dir, "index_dir")
      reference_dir = File.join(base_dir, "html", package_name)
      reference_filename = "file.html"

      spec = Gem::Specification.new do |_spec|
        _spec.name = package_name
      end

      Packnga::ReleaseTask.new(spec) do |task|
        task.index_html_dir = index_dir
        task.base_dir = base_dir
      end

      FileUtils.mkdir_p(reference_dir)
      FileUtils.touch(File.join(reference_dir, reference_filename))

      Rake::Task["release:references:upload"].invoke
      uploaded_path = File.join(index_dir, reference_filename)
      assert_true(File.exist?(uploaded_path))
    end
  end
end

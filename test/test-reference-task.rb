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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "test/unit/rr"
require "tmpdir"

class ReferenceTaskTest < Test::Unit::TestCase
  def teardown
    Rake::Task.clear
  end

  def test_reference_publication_prepare
    Dir.mktmpdir do |base_dir|
      package_name = "packnga"
      language = "en"

      spec = Gem::Specification.new do |_spec|
        _spec.name = package_name
      end

      Packnga::DocumentTask.new(spec) do |task|
        task.translate_language = language
        task.base_dir = base_dir
      end

      reference_dir = File.join(base_dir, "reference/#{language}")
      fixtures_dir = File.join(File.dirname(__FILE__), "fixtures")
      fixtures = Dir.glob(File.join(fixtures_dir, "{file.news,_index}.html"))

      FileUtils.mkdir_p(reference_dir)
      FileUtils.cp_r(fixtures, reference_dir)

      Rake::Task["reference:publication:prepare"].invoke

      html_dir = File.join(base_dir, "html/#{package_name}/#{language}")
      Dir.chdir(html_dir) do
        assert_true(File.exist?("file.news.html"))
        assert_true(File.exist?("alphabetical_index.html"))
        assert_false(File.exist?("_index.html"))

        expected_file = File.join(fixtures_dir, "expected", "file.news.html")
        expected_content = File.read(expected_file)
        actual_content = File.read("file.news.html")
        assert_equal(expected_content, actual_content)
      end
    end
  end
end

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

  class InfoUpdateTest < self
    def test_none_version
      Dir.mktmpdir do |base_dir|
        index_dir = File.join(base_dir, "index_dir")

        spec = Gem::Specification.new

        Packnga::ReleaseTask.new(spec) do |task|
          task.index_html_dir = index_dir
          task.base_dir = base_dir
        end

        index = "1-0-0 2013-03-28"
        index_file = File.join(index_dir, "index.html")
        create_index_file(index_file, index)
        ja_index_file = File.join(index_dir, "ja", "index.html")
        create_index_file(ja_index_file, index)

        package_infos = {
          :old_version      => "1.0.0",
          :old_release_date => "2013-03-28",
          :new_release_date => "2013-04-01"
        }
        set_environments(package_infos)
        assert_raise(ArgumentError) do
          Rake::Task["release:info:update"].invoke
        end
      end
    end

    def test_version_in_spec
      Dir.mktmpdir do |base_dir|
        index_dir = File.join(base_dir, "index_dir")

        spec = nil
        Gem::Specification.new do |_spec|
          spec = _spec
          spec.version = "1.0.1"
        end
        Packnga::ReleaseTask.new(spec) do |task|
          task.index_html_dir = index_dir
          task.base_dir = base_dir
        end

        index = "1-0-0 2013-03-28"
        index_file = File.join(index_dir, "index.html")
        create_index_file(index_file, index)
        ja_index_file = File.join(index_dir, "ja", "index.html")
        create_index_file(ja_index_file, index)

        package_infos = {
          :old_version      => "1.0.0",
          :old_release_date => "2013-03-28",
          :new_release_date => "2013-04-01"
        }
        set_environments(package_infos)
        Rake::Task["release:info:update"].invoke

        expected_index = "1-0-1 2013-04-01"
        assert_equal(expected_index, File.read(index_file))
        assert_equal(expected_index, File.read(ja_index_file))
      end
    end

    def test_version_in_env
      Dir.mktmpdir do |base_dir|
        index_dir = File.join(base_dir, "index_dir")

        spec = Gem::Specification.new
        Packnga::ReleaseTask.new(spec) do |task|
          task.index_html_dir = index_dir
          task.base_dir = base_dir
        end

        index = "1-0-0 2013-03-28"
        index_file = File.join(index_dir, "index.html")
        create_index_file(index_file, index)
        ja_index_file = File.join(index_dir, "ja", "index.html")
        create_index_file(ja_index_file, index)

        package_infos = {
          :old_version      => "1.0.0",
          :new_version      => "1.0.1",
          :old_release_date => "2013-03-28",
          :new_release_date => "2013-04-01"
        }
        set_environments(package_infos)
        Rake::Task["release:info:update"].invoke

        expected_index = "1-0-1 2013-04-01"
        assert_equal(expected_index, File.read(index_file))
        assert_equal(expected_index, File.read(ja_index_file))
      end
    end

    def test_same_versions
      Dir.mktmpdir do |base_dir|
        index_dir = File.join(base_dir, "index_dir")

        Packnga::ReleaseTask.new(Gem::Specification.new) do |task|
          task.index_html_dir = index_dir
          task.base_dir = base_dir
        end

        index = "1-0-0 2013-03-28"
        index_file = File.join(index_dir, "index.html")
        create_index_file(index_file, index)
        ja_index_file = File.join(index_dir, "ja", "index.html")
        create_index_file(ja_index_file, index)

        package_infos = {
          :old_version      => "1.0.0",
          :new_version      => "1.0.0",
          :old_release_date => "2013-03-28",
          :new_release_date => "2013-04-01"
        }
        set_environments(package_infos)

        Rake::Task["release:info:update"].invoke
        expected_index = "1-0-0 2013-04-01"
        assert_equal(expected_index, File.read(index_file))
        assert_equal(expected_index, File.read(ja_index_file))
      end
    end

    private
    def create_index_file(index_file, index)
      FileUtils.mkdir_p(File.dirname(index_file))
      File.open(index_file, "w") do |file|
        file.print(index)
      end
    end

    def set_environments(package_infos={})
      ENV["OLD_VERSION"]      = package_infos[:old_version]
      ENV["VERSION"]          = package_infos[:new_version]
      ENV["OLD_RELEASE_DATE"] = package_infos[:old_release_date]
      ENV["RELEASE_DATE"]     = package_infos[:new_release_date]
    end
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

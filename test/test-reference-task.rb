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

require "test/unit/rr"
require "tmpdir"

class ReferenceTaskTest < Test::Unit::TestCase
  def teardown
    Rake::Task.clear
  end

  def test_po_update_no_po_file_exists
    Dir.mktmpdir do |base_dir|
      package_name = "packnga"
      language = "ja"

      spec = Gem::Specification.new do |_spec|
        _spec.name = package_name
      end

      Packnga::DocumentTask.new(spec) do |task|
        task.translate_language = language
        task.base_dir = base_dir
      end

      po_dir = "#{base_dir}/po"
      pot_file = "#{po_dir}/#{package_name}.pot"
      po_file = "#{po_dir}/#{language}.po"

      mock(GetText::Tools::MsgInit).run("--input", pot_file,
                                        "--output", po_file,
                                        "--locale", language)

      Rake::Task["reference:po:update:ja"].invoke
    end
  end
end

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

class ReleaseTaskTest < Test::Unit::TestCase
  def test_html_publish
    spec = Gem::Specification.new do |_spec|
      _spec.rubyforge_project = "packnga"
    end
    release_task = Packnga::ReleaseTask.new(spec)
    html_base_dir = "doc/html/"

    mock(release_task).rsync_to_rubyforge(spec, html_base_dir, "", {})
    Rake::Task["release:html:publish"].invoke
  end
end

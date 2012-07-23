# -*- coding: utf-8; mode: ruby -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
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

base_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path("lib", base_dir))
require "packnga/version"

version = Packnga::VERSION.dup

readme_path = File.join(base_dir, "README.textile")
entries = File.read(readme_path).split(/^h2\.\s(.*)$/)
entry = lambda do |entry_title|
  entries[entries.index(entry_title) + 1]
end

authors = []
emails = []
entry.call("Authors").each_line do |line|
  if /\*\s*(.+)\s<([^<>]*)>$/ =~ line
    authors << $1
    emails << $2
  end
end

clean_white_space = lambda do |entry|
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end
description = clean_white_space.call(entry.call("Description"))
summary, description = description.split(/\n\n+/, 2)

Gem::Specification.new do |s|
  s.name = "packnga"
  s.version = version
  s.authors = authors
  s.email = emails
  s.summary = summary
  s.description = description

  s.extra_rdoc_files = ["README.textile"]
  s.files = ["README.textile", "Rakefile", "Gemfile"]
  Dir.chdir(base_dir) do
    s.files += Dir.glob("lib/**/*.rb")
    s.files += Dir.glob("doc/text/*.*")
  end

  s.homepage = "http://groonga.rubyforge.org/"
  s.licenses = ["LGPLv2"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "groonga"

  s.add_runtime_dependency("rake")
  s.add_runtime_dependency("yard")
  s.add_runtime_dependency("rubyforge")
  s.add_runtime_dependency("gettext")
  s.add_development_dependency("test-unit")
  s.add_development_dependency("test-unit-notify")
  s.add_development_dependency("bundler")
  s.add_development_dependency("RedCloth")
end


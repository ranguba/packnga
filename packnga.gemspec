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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

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

Gem::Specification.new do |spec|
  spec.name = "packnga"
  spec.version = version
  spec.authors = authors
  spec.email = emails
  spec.summary = summary
  spec.description = description

  spec.extra_rdoc_files = ["README.textile"]
  spec.files = ["README.textile", "Rakefile", "Gemfile", ".yardopts"]
  spec.files += ["packnga.gemspec"]
  Dir.chdir(base_dir) do
    spec.files += Dir.glob("lib/**/*.rb")
    spec.files += Dir.glob("doc/text/*.*")
    spec.test_files = Dir.glob("test/**/*.rb")
  end

  spec.homepage = "http://ranguba.org/packnga/en/"
  spec.licenses = ["LGPLv2"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("rake")
  spec.add_runtime_dependency("yard", ">= 0.8.6.1")
  spec.add_runtime_dependency("gettext", ">= 3.1.3")
  spec.add_development_dependency("test-unit")
  spec.add_development_dependency("test-unit-notify")
  spec.add_development_dependency("test-unit-rr")
  spec.add_development_dependency("bundler")
  spec.add_development_dependency("RedCloth")
end


# -*- coding: utf-8; mode: ruby -*-
#
# Copyright (C) 2011-2013  Haruka Yoshihara <yoshihara@clear-code.com>
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

require "English"

require "pathname"
require "rubygems"
require "rubygems/package_task"
require "bundler/gem_helper"

base_dir = File.join(File.dirname(__FILE__))

packnga_lib_dir = File.join(base_dir, "lib")
$LOAD_PATH.unshift(packnga_lib_dir)
ENV["RUBYLIB"] = "#{packnga_lib_dir}:#{ENV['RUBYLIB']}"

require "packnga"

helper = Bundler::GemHelper.new(base_dir)
helper.install
def helper.version_tag
  version
end

spec = helper.gemspec
Rake::Task["release"].prerequisites.clear

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_tar_gz = true
end

Packnga::DocumentTask.new(spec) do |task|
  task.original_language = "en"
  task.translate_language = "ja"
end

ranguba_org_dir = Dir.glob("{..,../../www}/ranguba.org").first
Packnga::ReleaseTask.new(spec) do |task|
  task.index_html_dir = ranguba_org_dir
end

desc "Run tests."
task :test do
  ruby("-rubygems", "test/run-test.rb")
end

task :default => :test

# -*- coding: utf-8; mode: ruby -*-
#
# Copyright (C) 2011  Haruka Yoshihara <yoshihara@clear-code.com>
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

require 'English'

require 'pathname'
require 'erb'
require 'rubygems'
require 'rubygems/package_task'
require "rake/clean"
require 'yard'
require 'jeweler'

base_dir = File.join(File.dirname(__FILE__))

packnga_lib_dir = File.join(base_dir, 'lib')
$LOAD_PATH.unshift(packnga_lib_dir)
ENV["RUBYLIB"] = "#{packnga_lib_dir}:#{ENV['RUBYLIB']}"

require "packnga"

def guess_version
  Packnga::VERSION.dup
end

def cleanup_white_space(entry)
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

ENV["VERSION"] ||= guess_version
version = ENV["VERSION"].dup
spec = nil
Jeweler::Tasks.new do |_spec|
  spec = _spec
  spec.name = "packnga"
  spec.version = version
  spec.rubyforge_project = "groonga"
  spec.homepage = "http://groonga.rubyforge.org/"
  spec.authors = ["Haruka Yoshihara", "Kouhei Sutou"]
  spec.email = ["yoshihara@clear-code.com", "kou@clear-code.com"]
  entries = File.read("README.textile").split(/^h2\.\s(.*)$/)
  description = cleanup_white_space(entries[entries.index("Description") + 1])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)
  spec.license = "LGPLv2"
  spec.files = FileList["lib/**/*.rb",
                        "Rakefile",
                        "README.textile",
                        "Gemfile",
                        "doc/text/**"]
  spec.test_files = FileList["test/**/*.rb"]
end

Rake::Task["release"].prerequisites.clear
Jeweler::RubygemsDotOrgTasks.new do
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_tar_gz = true
end

reference_base_dir = Pathname.new("doc/reference")
doc_en_dir = reference_base_dir + "en"
html_base_dir = Pathname.new("doc/html")
html_reference_dir = html_base_dir + spec.name

Packnga::DocumentTask.new(spec) do |task|
  task.yard do |yard_task|
  end
end

Packnga::ReferenceTask.new(spec) do |task|
end

include ERB::Util

def apply_template(content, paths, templates, language)
  content = content.sub(/lang="en"/, "lang=\"#{language}\"")

  title = nil
  content = content.sub(/<title>(.+?)<\/title>/m) do
    title = $1
    templates[:head].result(binding)
  end

  content = content.sub(/<body(?:.*?)>/) do |body_start|
    "#{body_start}\n#{templates[:header].result(binding)}\n"
  end

  content = content.sub(/<\/body/) do |body_end|
    "\n#{templates[:footer].result(binding)}\n#{body_end}"
  end

  content
end

def erb_template(name)
  file = File.join("doc/templates", "#{name}.html.erb")
  template = File.read(file)
  erb = ERB.new(template, nil, "-")
  erb.filename = file
  erb
end

def rsync_to_rubyforge(spec, source, destination, options={})
  config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  host = "#{config["username"]}@rubyforge.org"

  rsync_args = "-av --exclude '*.erb' --chmod=ug+w"
  rsync_args << " --delete" if options[:delete]
  remote_dir = "/var/www/gforge-projects/#{spec.rubyforge_project}/"
  sh("rsync #{rsync_args} #{source} #{host}:#{remote_dir}#{destination}")
end

def rake(*arguments)
  ruby($0, *arguments)
end

namespace :reference do
  translate_languages = [:ja]
  supported_languages = [:en, *translate_languages]
  html_files = FileList[(doc_en_dir + "**/*.html").to_s].to_a

  directory reference_base_dir.to_s
  CLOBBER.include(reference_base_dir.to_s)

  po_dir = "doc/po"
  pot_file = "#{po_dir}/#{spec.name}.pot"

  namespace :translate do
    translate_languages.each do |language|
      po_file = "#{po_dir}/#{language}.po"
      translate_doc_dir = "#{reference_base_dir}/#{language}"

      desc "Translates documents to #{language}."
      task language => [po_file, reference_base_dir, *html_files] do
        doc_en_dir.find do |path|
          base_path = path.relative_path_from(doc_en_dir)
          translated_path = "#{translate_doc_dir}/#{base_path}"
          if path.directory?
            mkdir_p(translated_path)
            next
          end
          case path.extname
          when ".html"
            sh("xml2po --keep-entities " +
               "--po-file #{po_file} --language #{language} " +
               "#{path} > #{translated_path}")
          else
            cp(path.to_s, translated_path, :preserve => true)
          end
        end
      end
    end
  end

  translate_task_names = translate_languages.collect do |language|
    "reference:translate:#{language}"
  end
  desc "Translates references."
  task :translate => translate_task_names

  desc "Generates references."
  task :generate => [:yard, :translate]

  namespace :publication do
    task :prepare do
      supported_languages.each do |language|
        raw_reference_dir = reference_base_dir + language.to_s
        prepared_reference_dir = html_reference_dir + language.to_s
        rm_rf(prepared_reference_dir.to_s)
        head = erb_template("head.#{language}")
        header = erb_template("header.#{language}")
        footer = erb_template("footer.#{language}")
        raw_reference_dir.find do |path|
          relative_path = path.relative_path_from(raw_reference_dir)
          prepared_path = prepared_reference_dir + relative_path
          if path.directory?
            mkdir_p(prepared_path.to_s)
          else
            case path.basename.to_s
            when /(?:file|method|class)_list\.html\z/
              cp(path.to_s, prepared_path.to_s)
            when /\.html\z/
              relative_dir_path = relative_path.dirname
              current_path = relative_dir_path + path.basename
              if current_path.basename.to_s == "index.html"
                current_path = current_path.dirname
              end
              top_path = html_base_dir.relative_path_from(prepared_path.dirname)
              package_path = top_path + spec.name
              paths = {
                :top => top_path,
                :current => current_path,
                :package => package_path,
              }
              templates = {
                :head => head,
                :header => header,
                :footer => footer
              }
              content = apply_template(File.read(path.to_s),
                                       paths,
                                       templates,
                                       language)
              File.open(prepared_path.to_s, "w") do |file|
                file.print(content)
              end
            else
              cp(path.to_s, prepared_path.to_s)
            end
          end
        end
      end
      File.open("#{html_reference_dir}/.htaccess", "w") do |file|
        file.puts("Redirect permanent /#{spec.name}/text/TUTORIAL_ja_rdoc.html " +
                  "#{spec.homepage}#{spec.name}/ja/file.tutorial.html")
        file.puts("RedirectMatch permanent ^/#{spec.name}/$ " +
                  "#{spec.homepage}#{spec.name}/en/")
      end
    end
  end

  desc "Upload document to rubyforge."
  task :publish => [:generate, "reference:publication:prepare"] do
    rsync_to_rubyforge(spec, "#{html_reference_dir}/", spec.name)
  end
end

namespace :html do
  desc "Publish HTML to Web site."
  task :publish do
    rsync_to_rubyforge(spec, "#{html_base_dir}/", "")
  end
end

desc "Upload document and HTML to rubyforge."
task :publish => ["html:publish", "reference:publish"]

desc "Tag the current revision."
task :tag do
  sh("git tag -a #{version} -m 'release #{version}!!!'")
end

namespace :release do
  namespace :info do
    desc "update version in index HTML."
    task :update do
      old_version = ENV["OLD_VERSION"]
      old_release_date = ENV["OLD_RELEASE_DATE"]
      new_release_date = ENV["RELEASE_DATE"] || Time.now.strftime("%Y-%m-%d")
      new_version = ENV["VERSION"]

      empty_options = []
      empty_options << "OLD_VERSION" if old_version.nil?
      empty_options << "OLD_RELEASE_DATE" if old_release_date.nil?

      unless empty_options.empty?
        raise ArgumentError, "Specify option(s) of #{empty_options.join(", ")}."
      end

      indexes = ["doc/html/index.html", "doc/html/index.html.ja"]
      indexes.each do |index|
        content = replaced_content = File.read(index)
        [[old_version, new_version],
         [old_release_date, new_release_date]].each do |old, new|
          replaced_content = replaced_content.gsub(/#{Regexp.escape(old)}/, new)
          if /\./ =~ old
            old_underscore = old.gsub(/\./, '-')
            new_underscore = new.gsub(/\./, '-')
            replaced_content =
              replaced_content.gsub(/#{Regexp.escape(old_underscore)}/,
                                    new_underscore)
          end
        end

        next if replaced_content == content
        File.open(index, "w") do |output|
          output.print(replaced_content)
        end
      end
    end
  end

  namespace :rubyforge do
    desc "Upload tar.gz to RubyForge."
    task :upload => "package" do
      ruby("-S", "rubyforge",
           "add_release",
           spec.rubyforge_project,
           spec.name,
           spec.version.to_s,
           "pkg/#{spec.name}-#{spec.version}.tar.gz")
    end
  end

  desc "Release to RubyForge."
  task :rubyforge => "release:rubyforge:upload"
end

namespace :test do
  task :install do
    gemspec_helper = Rake.application.jeweler.gemspec_helper
    ruby("-S gem install --user-install #{gemspec_helper.gem_path}")

    gem_spec = Gem.source_index.find_name("rroonga").last
    installed_path = gem_spec.full_gem_path
    ENV["NO_MAKE"] = "yes"
    ruby("-rubygems", "#{installed_path}/test/run-test.rb")
  end
end
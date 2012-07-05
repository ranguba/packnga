# -*- coding: utf-8 -*-
#
# Copyright (C) 2011  yoshihara haruka <yoshihara@clear-code.com>
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

require "erb"
require "gettext/tools"
require "tempfile"
require "tmpdir"

module Packnga
  # This class creates reference tasks.
  # They generate, translate and prepare to publish references.
  #
  # @since 0.9.0
  class ReferenceTask
    include Rake::DSL
    include ERB::Util

    # @return [String] path of base directory of document
    attr_writer :base_dir

    # @return [String] mode used in xml2po. The default is "docbook".
    attr_writer :mode

    # @private
    def initialize(spec)
      @spec = spec
      @base_dir = nil
      @mode = nil
      @translate_languages = nil
      @supported_languages = nil
      @sources = spec.files.find_all do |file|
        /\Alib\// =~ file and /\.rb\z/ =~ file
      end
      @extra_files = nil
      @html_files = nil
      @po_dir = nil
      @pot_file = nil
      if block_given?
        yield(self)
        define
      end
    end

    # @private
    def define
      set_default_values
      define_tasks
    end

    # path of .htaccess.
    def htaccess
      html_reference_dir + ".htaccess"
    end

    private
    def set_default_values
      @base_dir ||= Pathname.new("doc")
      @mode ||= "docbook"
      @translate_languages ||= [:ja]
      @supported_languages = [:en, *@translate_languages]
      @html_files = FileList[(doc_en_dir + "**/*.html").to_s].to_a
      @po_dir = "doc/po"
      @pot_file = "#{@po_dir}/#{@spec.name}.pot"
      text_dir = @base_dir + "text"
      @extra_files = @spec.files.find_all do |file|
        /\.textile\z/ =~ file or /\A#{text_dir}/ =~ file
      end
    end

    def reference_base_dir
      @base_dir + "reference"
    end

    def doc_en_dir
      @base_dir + "reference/en"
    end

    def html_base_dir
      @base_dir + "html"
    end

    def html_reference_dir
      html_base_dir + @spec.name
    end

    def define_tasks
      namespace :reference do
        define_pot_tasks
        define_po_tasks
        define_translate_task
        define_generate_task
        define_publication_task
      end
    end

    def define_pot_tasks
      namespace :pot do
        directory @po_dir
        file @pot_file => [@po_dir, *@sources, *@extra_files] do |t|
          create_pot_file(@pot_file)
        end
        desc "Generates pot file."
        task :generate => @pot_file do |t|
        end
      end
    end

    def define_po_tasks
      namespace :po do
        namespace :update do
          @translate_languages.each do |language|
            po_file = "#{@po_dir}/#{language}.po"

            if File.exist?(po_file)
              file po_file => [*@sources, *@extra_files] do |t|
                current_pot_file = Tempfile.new("tmp.pot").path
                create_pot_file(current_pot_file)
                GetText.msgmerge(po_file, current_pot_file,
                                 "#{@spec.name} #{Packnga::VERSION}")
              end
            else
              file po_file => @pot_file do |t|
                sh("msginit",
                   "--input=#{@pot_file}",
                   "--output=#{t.name}",
                   "--locale=#{language}")
              end
            end

            desc "Updates po file for #{language}."
            task language => po_file
          end
        end

        desc "Updates po files."
        task :update do
          ruby($0, "clobber")
          @translate_languages.each do |language|
            ruby($0, "reference:po:update:#{language}")
          end
        end
      end
    end

    def create_pot_file(pot_file_path)
      i18n_command = YARD::CLI::I18n.new
      i18n_command.run("-o", "#{pot_file_path}",
                       *@sources, "-", *@extra_files)
    end

    def define_translate_task
      namespace :translate do
        @translate_languages.each do |language|
          po_file = "#{@po_dir}/#{language}.po"
          translate_doc_dir = "#{reference_base_dir}/#{language}"
          desc "Translates documents to #{language}."
          task language => [po_file, reference_base_dir, *@sources, *@extra_files] do
            locale = YARD::I18n::Locale.new(language)
            locale.load(@po_dir)
            Dir.mktmpdir do |temp_dir|
              create_translate_files(@sources, temp_dir, locale)
              create_translate_files(@extra_files, temp_dir, locale)

              yardoc_command = YARD::CLI::Yardoc.new
              translated_sources = @sources.collect do |source|
                File.join(temp_dir, source)
              end
              translated_extra_files = @extra_files.collect do |extra_files|
                File.join(temp_dir, extra_files)
              end
              yardoc_command.run("-o", translate_doc_dir,
                                 translated_sources,
                                 "-", translated_extra_files)
            end
          end
        end
      end

      translate_task_names = @translate_languages.collect do |language|
        "reference:translate:#{language}"
      end
      desc "Translates references."
      task :translate => translate_task_names
    end

    def define_generate_task
      desc "Generates references."
      task :generate => [:yard, :translate]
    end

    def define_publication_task
      namespace :publication do
        task :prepare do
          @supported_languages.each do |language|
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
                  package_path = top_path + @spec.name
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
          File.open(htaccess, "w") do |file|
            file.puts("RedirectMatch permanent ^/#{@spec.name}/$ " +
                      "#{@spec.homepage}#{@spec.name}/en/")
          end
        end

        task :generate => ["reference:generate", "reference:publication:prepare"]
      end
    end

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

    def create_translate_files(original_files, translated_file_dir, locale)
      original_files.each do |original_file|
        translated_file = File.join(translated_file_dir, original_file)
        FileUtils.mkdir_p(File.dirname(translated_file))

        translated_text = ""
        File.read(original_file).each_line do |line|
          text = YARD::I18n::Text.new(line, :have_header => true)
          translated_text << text.translate(locale)
        end

        File.open(translated_file, "w") do |file|
          file.puts(translated_text)
        end
      end
    end
  end
end

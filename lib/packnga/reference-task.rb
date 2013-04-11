# -*- coding: utf-8 -*-
#
# Copyright (C) 2011-2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
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
require "rake/clean"

module Packnga
  # This class creates reference tasks.
  # They generate, translate and prepare to publish references.
  #
  # @since 0.9.0
  class ReferenceTask
    include Rake::DSL
    include ERB::Util

    # This attribute is used to set path of base directory of document.
    # @return [String] path of base directory of document
    attr_accessor :base_dir

    # This attribute is used to set README file.
    # @return [String] path of readme file
    attr_accessor :readme

    # This attribute is used to set source files for document.
    # @return [Array<String>] target source files
    attr_accessor :source_files

    # This attribute is used to set text files for document.
    # @return [Array<String>] target text files
    attr_accessor :text_files

    # This attribute is used to set the language you wrote original
    # document. Its default value is "en" (English).
    # @return [String] language you used to write document
    #
    # @see DocumentTask#original_language=
    #
    # @since 0.9.6
    attr_accessor :original_language

    # This attribute is used to set languages for translated document.
    # If original_language isn't English, its default value is one.
    # Otherwise, it is not specified.
    #
    # @see DocumentTask#translate_languages=
    #   See this page to specifiy multiple languages to this attribute.
    # @see DocumentTask#translate_language=
    #   See this page to specifiy a single language to this attribute.
    # @return [Array<String>] target languages
    #
    # @since 0.9.6
    attr_accessor :translate_languages

    # @private
    def initialize(spec)
      @spec = spec
      @base_dir = nil
      @original_language = nil
      @translate_languages = nil
      @supported_languages = nil
      @source_files = nil
      @text_files = nil
      @readme = nil
      @extra_files = nil
      @files = nil
      @po_dir = nil
      @pot_file = nil
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
      @original_language ||= "en"
      if @original_language == "en"
        @translate_languages ||= []
      else
        @translate_languages ||= ["en"]
      end
      @supported_languages = [@original_language, *@translate_languages]
      @po_dir = "#{@base_dir}/po"
      @pot_file = "#{@po_dir}/#{@spec.name}.pot"
      @extra_files = @text_files
      @extra_files += [@readme] if @readme
      @files = @source_files + @extra_files
    end

    def reference_base_dir
      @base_dir + "reference"
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
        file @pot_file => [@po_dir, *@files] do |t|
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
              file po_file => @files do |t|
                current_pot_file = "#{@po_dir}/tmp.pot"
                create_pot_file(current_pot_file)
                GetText::Tools::MsgMerge.run(po_file, current_pot_file,
                                             "-o", po_file)
                FileUtils.rm_f(current_pot_file)
              end
            else
              file po_file => @pot_file do |t|
                GetText::Tools::MsgInit.run("--input", @pot_file,
                                            "--output", t.name,
                                            "--locale", language.to_s)
              end
            end

            desc "Updates po file for #{language}."
            task language => po_file
          end
        end

        desc "Updates po files."
        task :update do
          Rake::Task["clobber"].invoke
          @translate_languages.each do |language|
            Rake::Task["reference:po:update:#{language}"].invoke
          end
        end
      end
    end

    def create_pot_file(pot_file_path)
      options = ["-o", pot_file_path]
      options += @source_files
      options += ["-"]
      options += @extra_files
      YARD::CLI::I18n.run(*options)
    end

    def define_translate_task
      directory reference_base_dir.to_s
      namespace :translate do
        @translate_languages.each do |language|
          po_file = "#{@po_dir}/#{language}.po"
          desc "Translates documents to #{language}."
          task language => [po_file, reference_base_dir, *@files] do
            locale = YARD::I18n::Locale.new(language)
            locale.load(@po_dir)
            Dir.mktmpdir do |temp_dir|
              create_translated_sources(temp_dir, locale)
              copy_extra_files(temp_dir)
              create_translated_documents(temp_dir, locale)
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
              prepared_path = generate_prepared_path(prepared_reference_dir,
                                                     relative_path)
              if path.directory?
                mkdir_p(prepared_path.to_s)
              else
                case path.basename.to_s
                when /(?:file|method|class)_list\.html\z/
                  cp(path.to_s, prepared_path.to_s)
                when /\.html\z/
                  relative_dir_path = relative_path.dirname
                  if path.basename.to_s == "_index.html"
                    current_path = relative_dir_path + "alphabetical_index.html"
                  else
                    current_path = relative_dir_path + path.basename
                    if current_path.basename.to_s == "index.html"
                      current_path = current_path.dirname
                    end
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
                  content = content.gsub(/"(.+)_index\.html/,
                                         "\\1alphabetical_index.html")
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

    def generate_prepared_path(prepared_reference_dir, relative_path)
      prepared_path = prepared_reference_dir + relative_path
      if prepared_path.basename.to_s == "_index.html"
        prepared_path.dirname + "alphabetical_index.html"
      else
        prepared_path
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

    def create_translated_documents(output_dir, locale)
      language = locale.name.to_s
      translate_doc_dir = "#{reference_base_dir}/#{language}"
      po_dir = File.expand_path(@po_dir)
      mkdir_p(translate_doc_dir)

      Dir.chdir(output_dir) do
        YARD::Registry.clear
        YARD.parse(@source_files)

        options = [
          "--title", @spec.name,
          "-o", translate_doc_dir,
          "--po-dir", po_dir,
          "--locale", language,
          "--charset", "utf-8",
          "--no-private"
        ]
        options += ["--readme", @readme] if @readme
        options += @source_files
        options += ["-"]
        options += @text_files

        YARD::CLI::Yardoc.run(*options)
      end
      translated_files = File.join(output_dir, translate_doc_dir, "**")
      FileUtils.cp_r(Dir.glob(translated_files), translate_doc_dir)
    end

    def create_translated_sources(output_dir, locale)
      YARD.parse(@source_files)
      create_translated_files(@source_files, output_dir) do |content|
        code_objects = YARD::Registry.all
        code_objects.each do |code_object|
          original_docstring = code_object.docstring
          content = translate_content_part(content,
                                           original_docstring,
                                           locale)

          original_docstring.tags.each do |tag|
            original_tag_text = tag.text
            next if original_tag_text.nil?
            content = translate_content_part(content,
                                             original_tag_text,
                                             locale)
          end
        end
        content
      end
    end

    def copy_extra_files(output_dir)
      @extra_files.each do |file|
        target_extra_file = File.join(output_dir, file)
        FileUtils.mkdir_p(File.dirname(target_extra_file))
        FileUtils.cp_r(file, target_extra_file)
      end
    end

    def create_translated_files(original_files, output_dir)
      original_files.each do |file|
        translated_file = File.join(output_dir, file)
        FileUtils.mkdir_p(File.dirname(translated_file))
        content = File.read(file)

        translated_text = yield(content)

        File.open(translated_file, "w") do |file|
          file.puts(translated_text)
        end
      end
    end

    def translate_content_part(content, original_text, locale)
      translated_content = ""
      text = YARD::I18n::Text.new(original_text)
      translate_text = text.translate(locale)
      original_text = original_text.each_line.collect do |line|
        "(.+)#{Regexp.escape(line)}"
      end
      translate_text = translate_text.each_line.collect do |line|
        "\\1#{line}"
      end
      content.sub(/#{original_text.join}/, translate_text.join)
    end
  end
end

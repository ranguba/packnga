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
    # document.
    # @return [String] language you used to write document
    attr_accessor :original_language

    # This attribute is used to set languages for tnanslated document.
    # @return [Array<String>] target languages
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
      @original_language ||= current_language
      if not @original_language == "en"
        @translate_languages ||= ["en"]
      else
        @translate_languages ||= []
      end
      @supported_languages = [@original_language, *@translate_languages]
      @po_dir = "#{@base_dir}/po"
      @pot_file = "#{@po_dir}/#{@spec.name}.pot"
      @extra_files = @text_files
      @extra_files += [@readme] if @readme
      @files = @source_files + @extra_files
    end

    def current_language
      locale = Locale.current
      language = locale.language
      region = locale.region

      if region.nil?
        language
      else
        "#{language}_#{region}"
      end
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
                current_pot_file = "tmp.pot"
                create_pot_file(current_pot_file)
                GetText.msgmerge(po_file, current_pot_file,
                                 "#{@spec.name} #{Packnga::VERSION}")
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

# XXX: This module is the re-definition of YARD module.
# this module should be deleted in the next release of YARD.
# @private
module YARD
  module CLI
    # @private
    class Yardoc
      def parse_arguments(*args)
        parse_yardopts_options(*args)

        # Parse files and then command line arguments
        optparse(*support_rdoc_document_file!) if use_document_file
        optparse(*yardopts) if use_yardopts_file
        optparse(*args)

        # Last minute modifications
        self.files = ['{lib,app}/**/*.rb', 'ext/**/*.c'] if self.files.empty?
        self.files.delete_if {|x| x =~ /\A\s*\Z/ } # remove empty ones
        readme = Dir.glob('README*').first
        readme ||= Dir.glob(files.first).first if options.onefile
        options.readme ||= CodeObjects::ExtraFileObject.new(readme) if readme
        options.files.unshift(options.readme).uniq! if options.readme

        Tags::Library.visible_tags -= hidden_tags
        add_visibility_verifier
        add_api_verifier

        apply_locale

        # US-ASCII is invalid encoding for onefile
        if defined?(::Encoding) && options.onefile
          if ::Encoding.default_internal == ::Encoding::US_ASCII
            log.warn "--one-file is not compatible with US-ASCII encoding, using ASCII-8BIT"
            ::Encoding.default_external, ::Encoding.default_internal = ['ascii-8bit'] * 2
          end
        end

        if generate && !verify_markup_options
          false
        else
          true
        end
      end

      def apply_locale
        options.files.each do |file|
          file.locale = options.locale
        end
      end

      def output_options(opts)
        opts.separator ""
        opts.separator "Output options:"

        opts.on('--one-file', 'Generates output as a single file') do
          options.onefile = true
        end

        opts.on('--list', 'List objects to standard out (implies -n)') do |format|
          self.generate = false
          self.list = true
        end

        opts.on('--no-public', "Don't show public methods. (default shows public)") do
          visibilities.delete(:public)
        end

        opts.on('--protected', "Show protected methods. (default hides protected)") do
          visibilities.push(:protected)
        end

        opts.on('--private', "Show private methods. (default hides private)") do
          visibilities.push(:private)
        end

        opts.on('--no-private', "Hide objects with @private tag") do
          options.verifier.add_expressions '!object.tag(:private) &&
            (object.namespace.is_a?(CodeObjects::Proxy) || !object.namespace.tag(:private))'
        end

        opts.on('--[no-]api API', 'Generates documentation for a given API',
                                  '(objects which define the correct @api tag).',
                                  'If --no-api is given, displays objects with',
                                  'no @api tag.') do |api|
          api = '' if api == false
          apis.push(api)
        end

        opts.on('--embed-mixins', "Embeds mixin methods into class documentation") do
          options.embed_mixins << '*'
        end

        opts.on('--embed-mixin [MODULE]', "Embeds mixin methods from a particular",
                                          " module into class documentation") do |mod|
          options.embed_mixins << mod
        end

        opts.on('--no-highlight', "Don't highlight code blocks in output.") do
          options.highlight = false
        end

        opts.on('--default-return TYPE', "Shown if method has no return type. ",
                                         "  (defaults to 'Object')") do |type|
          options.default_return = type
        end

        opts.on('--hide-void-return', "Hides return types specified as 'void'. ",
                                      "  (default is shown)") do
          options.hide_void_return = true
        end

        opts.on('--query QUERY', "Only show objects that match a specific query") do |query|
          next if YARD::Config.options[:safe_mode]
          options.verifier.add_expressions(query.taint)
        end

        opts.on('--title TITLE', 'Add a specific title to HTML documents') do |title|
          options.title = title
        end

        opts.on('-r', '--readme FILE', '--main FILE', 'The readme file used as the title page',
                                                      '  of documentation.') do |readme|
          if File.file?(readme)
            options.readme = CodeObjects::ExtraFileObject.new(readme)
          else
            log.warn "Could not find readme file: #{readme}"
          end
        end

        opts.on('--files FILE1,FILE2,...', 'Any extra comma separated static files to be ',
                                           '  included (eg. FAQ)') do |files|
          add_extra_files(*files.split(","))
        end

        opts.on('--asset FROM[:TO]', 'A file or directory to copy over to output ',
                                     '  directory after generating') do |asset|
          re = /^(?:\.\.\/|\/)/
          from, to = *asset.split(':').map {|f| File.cleanpath(f) }
          to ||= from
          if from =~ re || to =~ re
            log.warn "Invalid file '#{asset}'"
          else
            assets[from] = to
          end
        end

        opts.on('-o', '--output-dir PATH',
                'The output directory. (defaults to ./doc)') do |dir|
          options.serializer.basepath = dir
        end

        opts.on('-m', '--markup MARKUP',
                'Markup style used in documentation, like textile, ',
                '  markdown or rdoc. (defaults to rdoc)') do |markup|
          self.has_markup = true
          options.markup = markup.to_sym
        end

        opts.on('-M', '--markup-provider MARKUP_PROVIDER',
                'Overrides the library used to process markup ',
                '  formatting (specify the gem name)') do |markup_provider|
          options.markup_provider = markup_provider.to_sym
        end

        opts.on('--charset ENC', 'Character set to use when parsing files ',
                                 '  (default is system locale)') do |encoding|
          begin
            if defined?(Encoding) && Encoding.respond_to?(:default_external=)
              Encoding.default_external, Encoding.default_internal = encoding, encoding
            end
          rescue ArgumentError => e
            raise OptionParser::InvalidOption, e
          end
        end

        opts.on('-t', '--template TEMPLATE',
                'The template to use. (defaults to "default")') do |template|
          options.template = template.to_sym
        end

        opts.on('-p', '--template-path PATH',
                'The template path to look for templates in.',
                '  (used with -t).') do |path|
          next if YARD::Config.options[:safe_mode]
          YARD::Templates::Engine.register_template_path(File.expand_path(path))
        end

        opts.on('-f', '--format FORMAT',
                'The output format for the template.',
                '  (defaults to html)') do |format|
          options.format = format.to_sym
        end

        opts.on('--no-stats', 'Don\'t print statistics') do
          self.statistics = false
        end

        opts.on('--locale LOCALE',
                'The locale for generated documentation.',
                '  (defaults to en)') do |locale|
          options.locale = locale
        end

        opts.on('--po-dir DIR',
                'The directory that has .po files.',
                '  (defaults to #{YARD::Registry.po_dir})') do |dir|
          YARD::Registry.po_dir = dir
        end
      end
    end
  end

  module CodeObjects
    # @private
    class ExtraFileObject
      attr_writer :attributes
      attr_reader :locale

      def initialize(filename, contents = nil)
        self.filename = filename
        self.name = File.basename(filename).gsub(/\.[^.]+$/, '')
        self.attributes = SymbolHash.new(false)
        @original_contents = contents
        @parsed = false
        @locale = nil
        ensure_parsed
      end

      def attributes
        ensure_parsed
        @attributes
      end

      def contents
        ensure_parsed
        @contents
      end

      def contents=(contents)
        @original_contents = contents
        @parsed = false
      end

      def locale=(locale)
        @locale = locale
        @parsed = false
      end

      private
      def ensure_parsed
        return if @parsed
        @parsed = true
        @contents = parse_contents(@original_contents || File.read(@filename))
      end

      def parse_contents(data)
        retried = false
        cut_index = 0
        data = translate(data)
        data = data.split("\n")
        data.each_with_index do |line, index|
          case line
          when /^#!(\S+)\s*$/
            if index == 0
              attributes[:markup] = $1
            else
              cut_index = index
              break
            end
          when /^\s*#\s*@(\S+)\s*(.+?)\s*$/
            attributes[$1] = $2
          else
            cut_index = index
            break
          end
        end
        data = data[cut_index..-1] if cut_index > 0
        contents = data.join("\n")

        if contents.respond_to?(:force_encoding) && attributes[:encoding]
          begin
            contents.force_encoding(attributes[:encoding])
          rescue ArgumentError
            log.warn "Invalid encoding `#{attributes[:encoding]}' in #{filename}"
          end
        end
        contents
      rescue ArgumentError => e
        if retried && e.message =~ /invalid byte sequence/
          # This should never happen.
          log.warn "Could not read #{filename}, #{e.message}. You probably want to set `--charset`."
          return ''
        end
        data.force_encoding('binary') if data.respond_to?(:force_encoding)
        retried = true
        retry
      end

      def translate(data)
        text = YARD::I18n::Text.new(data, :have_header => true)
        text.translate(YARD::Registry.locale(locale))
      end
    end
  end

  module I18n
    # @private
    class Locale
      def load(locale_directory)
        return false if @name.nil?

        po_file = File.join(locale_directory, "#{@name}.po")
        return false unless File.exist?(po_file)

        begin
          require "gettext/tools/poparser"
          require "gettext/runtime/mofile"
        rescue LoadError
          log.warn "Need gettext gem for i18n feature:"
          log.warn "  gem install gettext"
          return false
        end

        parser = GetText::PoParser.new
        parser.report_warning = false
        data = GetText::MoFile.new
        parser.parse_file(po_file, data)
        @messages.merge!(data)
        true
      end
    end
  end

  # @private
  module Registry
    DEFAULT_PO_DIR = "po"
    class << self
      def locale(name)
        thread_local_store.locale(name)
      end

      attr_accessor :po_dir
      undef po_dir, po_dir=
      def po_dir=(dir) Thread.current[:__yard_po_dir__] = dir end
      def po_dir
        Thread.current[:__yard_po_dir__] ||= DEFAULT_PO_DIR
      end
    end
  end

  # @private
  class RegistryStore
    def initialize
      @file = nil
      @checksums = {}
      @store = {}
      @proxy_types = {}
      @object_types = {:root => [:root]}
      @notfound = {}
      @loaded_objects = 0
      @available_objects = 0
      @locales = {}
      @store[:root] = CodeObjects::RootObject.allocate
      @store[:root].send(:initialize, nil, :root)
    end

    def locale(name)
      @locales[name] ||= load_locale(name)
    end

    def load_locale(name)
      locale = I18n::Locale.new(name)
      locale.load(Registry.po_dir)
      locale
    end
  end
end

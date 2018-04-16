require 'nokogiri'
require 'sanitize'
require 'pathname'
require 'mathml2latex'

module Qti
  class ParseError < StandardError; end
  class SpecificationViolation < StandardError; end
  class UnsupportedSchema < StandardError; end

  module Models
    class Base
      attr_reader :doc, :path, :package_root
      attr_accessor :manifest, :is_from_string, :file_content

      ELEMENTS_REMAP = {
        'prompt' => 'div',
        'simpleBlock' => 'div',
        'simpleInline' => 'span',
        'atomicBlock' => 'div',
        'atomicInline' => 'span'
      }.freeze

      def sanitize_content!(html)
        Sanitize.fragment(html, sanitize_config)
      end

      def object_tag_transformer
        lambda do |env|
          return unless env[:node_name] == 'object'
          return if env[:is_whitelisted] || !env[:node].element?
          replace_object_node(env[:node])
        end
      end

      def remap_unknown_tags_transformer
        lambda do |env|
          node_name = env[:node_name]
          node = env[:node]

          return if env[:is_whitelisted] || !node.element?
          return unless ELEMENTS_REMAP.keys.include? node_name

          new_name = ELEMENTS_REMAP[node_name]
          env[:node].name = new_name
          env[:node_name] = new_name
        end
      end

      def sanitize_config(import_objects: true)
        transformers = []
        transformers << object_tag_transformer if import_objects
        transformers << remap_unknown_tags_transformer
        Sanitize::Config::RELAXED.merge transformers: transformers
      end

      def self.from_string!(string, package_root = nil)
        new(path: nil, content: string, html: false)
      end

      def self.from_path!(path, package_root = nil)
        new(path: path, content: nil, package_root: package_root)
      end

      def initialize(path:, content:, package_root: nil, html: false)
        if path
          @path = path
          self.package_root = package_root || File.dirname(path)
          @doc = html ? parse_html(File.read(path)) : parse_xml(File.read(path))
        elsif content
          @file_content = content
          @is_from_string = true
          @doc = html ? parse_html(content[:content]) : parse_xml(content[:content])
        end
        raise ArgumentError unless @doc
        preprocess_xml_doc(@doc) unless html
      end

      def preprocess_xml_doc(xml_doc)
        converter = Mathml2latex::Converter.new
        converter.replace_with_latex(xml_doc)
        nodes = xml_doc.xpath('//mm:latex', 'mm' => Mathml2latex::INSTUCTURE_LATEX_NS)

        nodes.each do |node|
          # convert all #160 space to regular #32 whitespace
          # latex parser won't work for #160 space
          text = node.text.tr("\u00a0", ' ')
          latex_string = "&#160;\\(#{text}\\)&#160;"
          node.replace(latex_string)
        end
      end

      def xpath_with_single_check(xpath)
        node_list = @doc.xpath(xpath)
        raise Qti::ParseError, 'Too many matches' if node_list.count > 1
        node_list.first
      end

      def css_with_single_check(css)
        node_list = @doc.css(css)
        raise Qti::ParseError, 'Too many matches' if node_list.count > 1
        node_list.first
      end

      def parse_xml(xml_string)
        Nokogiri.XML(xml_string, @path.to_s, &:noblanks)
      end

      def parse_html(html_string)
        Nokogiri.HTML(html_string, @path.to_s, &:noblanks)
      end

      def remap_href_path(href)
        return nil unless href
        return nil if @is_from_string
        path = File.join(File.dirname(@path), href)
        if @package_root.nil?
          raise Qti::ParseError, "Potentially unsafe href '#{href}'" if href.split('/').include?('..')
        else
          unless Pathname.new(path).cleanpath.to_s.start_with?(@package_root)
            raise Qti::ParseError, "Unsafe href '#{href}'"
          end
        end
        path
      end

      protected

      def package_root=(package_root)
        @package_root = package_root
        return unless @package_root
        @package_root = Pathname.new(@package_root).cleanpath.to_s + '/'
      end

      def relative_path
        return nil if @path.nil? || @package_root.nil?
        @path.sub(/\A#{Regexp.quote(@package_root)}/, '')
      end

      def copy_paths_from_item(other_item)
        @package_root = other_item.package_root
        @path = other_item.path
      end

      def replace_object_node(node)
        path = remap_href_path(node[:data])
        if path
          case node[:type]
          when %r{^image\/}
            return replace_with_image(node, node[:data])
          when 'text/html'
            return replace_with_html(node, path)
          end
        end
        # remove unrecognized or invalid objects from the sanitized document
        node.unlink
      end

      def replace_with_image(node, src)
        node.name = 'img'
        node[:src] = src
      end

      def replace_with_html(node, path)
        content = File.read(path)
        html_content = Sanitize.fragment(content, sanitize_config(import_objects: false))
        node.name = 'div'
        node.add_child(Nokogiri::HTML.fragment(html_content))
      rescue StandardError => e
        warn "failed to import html object #{path}: #{e.message}"
        node.unlink
      end
    end
  end
end

require 'active_support'
require 'stringio'
require 'minitest/assertions'
require 'rails/dom/testing/assertions'
require 'will_paginate/array'

module ViewExampleGroup
  
  include Rails::Dom::Testing::Assertions::SelectorAssertions
  include Minitest::Assertions

  def assert(value, message)
    raise message unless value
  end
  
  def paginate(collection = {}, options = {}, &block)
    if collection.instance_of? Hash
      page_options = { :page => 1, :total_entries => 11, :per_page => 4 }.merge(collection)
      collection = [1].paginate(page_options)
    end

    locals = { :collection => collection, :options => options }

    @render_output = render(locals)
    @html_document = nil
    
    if block_given?
      classname = options[:class] || WillPaginate::ViewHelpers.pagination_options[:class]
      assert_select("div.#{classname}", 1, 'no main DIV', &block)
    end
    
    @render_output
  end

  def parse_html_document(html)
    Nokogiri::HTML::Document.parse(html)
  end

  def html_document
    @html_document ||= parse_html_document(@render_output)
  end

  def document_root_element
    html_document.root
  end

  def response_from_page_or_rjs
    html_document.root
  end
  
  def validate_page_numbers(expected, links, param_name = :page)
    param_pattern = /\W#{Regexp.escape(param_name.to_s)}=([^&]*)/
    
    expect(links.map { |el|
      unescape_href(el) =~ param_pattern
      $1 ? $1.to_i : $1
    }).to eq(expected)
  end

  def assert_links_match(pattern, links = nil, numbers = nil)
    links ||= assert_select 'div.pagination a[href]' do |elements|
      elements
    end

    pages = [] if numbers
    
    links.each do |el|
      href = unescape_href(el)
      expect(href).to match(pattern)
      if numbers
        href =~ pattern
        pages << ($1.nil?? nil : $1.to_i)
      end
    end

    expect(pages).to eq(numbers) if numbers
  end

  def assert_no_links_match(pattern)
    assert_select 'div.pagination a[href]' do |elements|
      elements.each do |el|
        expect(unescape_href(el)).not_to match(pattern)
      end
    end
  end

  def unescape_href(el)
    CGI.unescape CGI.unescapeHTML(el['href'])
  end
  
  def build_message(message, pattern, *args)
    built_message = pattern.dup
    for value in args
      built_message.sub! '?', value.inspect
    end
    built_message
  end
  
end

RSpec.configure do |config|
  config.include ViewExampleGroup, :type => :view, :file_path => %r{spec/view_helpers/}
end

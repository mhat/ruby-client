require 'rest_client'
require 'uri'
require 'wavefront/client/version'
require 'wavefront/mixins'
require 'wavefront/constants'
require 'wavefront/exception'

module Wavefront
  #
  # Because of the way the 'manage' API is laid out, this class doesn't
  # reflect it as clearly as, say the 'alerts' class.
  #
  # Note that the following methods do not do any exception handling. It
  # is up to your client code to decide how to deal with, for example, a
  # RestClient::ResourceNotFound exception.
  #
  class Sources
    DEFAULT_PATH = '/api/manage/source/'.freeze
    include Wavefront::Constants
    include Wavefront::Mixins

    attr_reader :headers

    def initialize(token, debug = false)
      @headers = { :'X-AUTH-TOKEN' => token }
      debug(debug)
    end

    def delete_tags(source)
      #
      # Delete all tags from a source. Maps to
      # DELETE /api/manage/source/{source}/tags
      #
      call_delete(build_uri(uri_concat(source, 'tags')))
    end

    def delete_tag(source, tag)
      #
      # Delete a given tag from a source. Maps to
      # DELETE /api/manage/source/{source}/tags/{tag}
      #
      call_delete(build_uri(uri_concat(source, 'tags', tag)))
    end

    def show_sources(params = {})
      #
      # return a list of sources. Maps to
      # GET /api/manage/source
      # call it with a hash as described in the Wavefront API docs
      #
      call_get(build_uri(nil, query: hash_to_qs(params)))
    end

    def show_source(source)
      #
      # return information about a single source. Maps to
      # GET /api/manage/source/{source}
      #
      call_get(build_uri(source))
    end

    def set_description(source, desc)
      #
      # set the description field for a source. Maps to
      # POST /api/manage/source/{source}/description
      #
      raise Wavefront::Exception::InvalidString unless valid_string?(desc)
      call_post(build_uri(uri_concat(source, 'description')), desc)
    end

    def set_tag(source, tag)
      #
      # set a tag on a source. Maps to
      # POST /api/manage/source/{source}/tags/{tag}
      #
      raise Wavefront::Exception::InvalidString unless valid_string?(tag)
      call_post(build_uri(uri_concat(source, 'tags', tag)))
    end

    private

    def valid_string?(string)
      #
      # Only allows PCRE "word" characters, spaces, full-stops and
      # commas in tags and descriptions. This might be too restrictive,
      # but if it is, this is the only place we need to change it.
      #
      string.match(/^[\-\w \.,]*$/)
    end

    def build_uri(path_ext = '', options = {})
      options[:host] ||= DEFAULT_HOST
      options[:path] ||= DEFAULT_PATH

      URI::HTTPS.build(
        host:  options[:host],
        path:  uri_concat(options[:path], path_ext),
        query: options[:query]
      )
    end

    def call_get(uri)
      RestClient.get(uri.to_s, headers)
    end

    def call_delete(uri)
      RestClient.delete(uri.to_s, headers)
    end

    def call_post(uri, query = nil)
      h = headers

      RestClient.post(uri.to_s, query, h.merge(
        :'Content-Type' => 'text/plain', :Accept => 'application/json'
      ))
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end

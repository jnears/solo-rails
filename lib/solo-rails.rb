require 'solo-rails/version'
require 'cgi'
require 'open-uri'
require 'chronic'
require 'nokogiri'

module SoloRails

  def show(id)
    Catalogue.new.show(id)
  end

  def search(*args)
    Catalogue.new.search(*args)
  end

  class Catalogue

    def initialize
      @site = "http://library.iser.essex.ac.uk/Library/WebServices/SoutronApi.svc/"
    end

    # returns SoloHash of values for individual catalogue record
    def show(id)
      id = id.to_i
      response = SoloHash.new
      url = "#{@site}getcatalogue?id=#{id}"
      begin
        soutron_data = Nokogiri::XML(open(url, :read_timeout => 180))
        response[:id] = soutron_data.xpath("/soutron/catalogs_view/ct/cat").attribute("id").text
        # response[:request_url] = url - removed for security/speed purposes - PG 2011-02-17
        response[:content_type] = soutron_data.xpath("/soutron/catalogs_view/ct").attribute("name").text
        response[:record_type] = soutron_data.xpath("/soutron/catalogs_view/ct/cat/rt").attribute("name").text
        soutron_data.xpath("/soutron/catalogs_view/ct/cat/fs/f").each do |f|
          if f.xpath("count(./vs/v)") > 0
            response[uscore(f.attribute("name").text).to_sym] = parse_values(f.attribute("ft").text, f.xpath("./vs/v"))
          end
        end
        # related records - PG 2011-03-01
        if soutron_data.xpath("count(/soutron/catalogs_view/ct/cat/related_catalogs)") > 0
          @related_records = []
          soutron_data.xpath("/soutron/catalogs_view/ct/cat/related_catalogs/ct").each do |related_ct|
            related_record = SoloHash.new
            related_record.merge!( { "content_type".to_sym => related_ct.attribute("name").text } )
            related_ct.xpath('ctlgs/cat').each do |r|
              related_record.merge!( {"cid".to_sym => r.attribute("id").text } )
            end
            @related_records << related_record
          end
          response[:related_records] = @related_records
        end
      rescue
        response = nil
      end
      return response
    end

    # returns nested hash record for given search - PG 2011-01-21
    def search(*args)
      build_query_url(args.pop)
      begin
        parse_results(Nokogiri::XML(open(url, :read_timeout => 180)))
      rescue Exception => e  
        Rails.logger.info("SOLO Error in URL: " + url)
      end
    end

    private

      def build_query_url(*options)
        q, ctrt, select, sort, page, material, search_id, per_page, ignore_is_website_feature = iser_solo_parse_options(options)
        url = "#{@site}searchcatalogues?"
        query_string = []
        # If we have a value of search_id, then should only also pass: search_id, select, sort, page, per_page & material
        if search_id.present?
          query_string << "searchid=#{search_id}"
        else
          query_string << "q=#{q}"
          query_string << "ctrt=#{ctrt}" if ctrt.present?
        end
        query_string << "page=#{page}" if page.present?
        query_string << "pageSize=#{per_page}" if per_page.present?
        query_string << "sort=#{sort}" if sort.present?
        query_string << "fields=#{select}" if select.present?
        query_string << "material=#{material}" if material.present?
        url += query_string.join("&")
      end

      def parse_results(soutron_data)
        response = SoloHash.new
        meta = {:id => soutron_data.xpath("/soutron/search_info").attribute("id").text}
        meta["total_items".to_sym] = soutron_data.xpath("/soutron/search_info").attribute("totalItems").text
        meta["page".to_sym] = page
        meta["per_page".to_sym] = per_page
        meta["select".to_sym] = select
        if soutron_data.xpath("count(//ct)") > 0
          unless soutron_data.xpath("/soutron/search_info/catalogs_view/ct[*]").first.nil?
            meta["active_content_type".to_sym] = soutron_data.xpath("/soutron/search_info/catalogs_view/ct[*]").first.attribute("name").text
            meta["active_content_type_count".to_sym] = soutron_data.xpath("/soutron/search_info/catalogs_view/ct[*]").first.attribute("count").text
          end
        end
        response.merge!("search_info".to_sym => meta)
        @content_types = []
        soutron_data.xpath("/soutron/search_info/catalogs_view/ct").each do |ct|
          content_type = SoloHash.new
          content_type.merge!( { "content_type".to_sym => ct.attribute("name").text } )
          content_type.merge!( { "size".to_sym => ct.attribute("count").text } )
          @records = []
          ct.xpath("./ctlgs/cat").each do |cat|
            record = SoloHash.new
            record.merge!( {:id => cat.attribute("id").text, :record_type => cat.xpath("./rt").attribute("name").text} )
            cat.xpath("./fs/f").each do |f|
              if f.xpath("count(./vs/v)") > 0 # only include field if it has a value
                record[uscore(f.attribute("name").text).to_sym] = parse_values(f.attribute("ft").text, f.xpath("./vs/v"))
              end # / if has value
            end # /f
            @records << record
          end # /cat
          content_type.merge!({"records".to_sym => @records })
          @content_types << content_type
        end # /ct
        response.merge!(:content_types => @content_types)
        return response
      end

      # returns array of URL safe variables from options
      def iser_solo_parse_options(options)
        q = options[:q] 
        unless options[:ignore_is_website_feature] == true
          q.nil? ? nil : q << ";Is Website Feature:Y" 
        end
        ctrt = options[:ctrt]
        select = options[:select]
        sort = options[:sort]
        page = options[:page]
        material = options[:material]
        search_id = options[:search_id]
        per_page = options[:per_page].blank? ? 20 : options[:per_page]
        url_safe([q, ctrt, select, sort, page, material, search_id, per_page])
      end

      # CGI escapes 'options' array to make safe URLs
      def url_safe(options)
        options.collect! { |option| CGI.escape(option.to_s) }
      end

      # Returns values for a field based on field type, either individual value or array
      def parse_values(field_type, elements)
        if elements.size > 1
          value = elements.collect{|v| parse_value(field_type, v)}
        else
          value = parse_value(field_type, elements.first)
        end
      end

      # returns value based on field type
      # @field_types = {
      #   1 => "Text",
      #   2 => "Integer",
      #   3 => "Date",
      #   4 => "File",
      #   5 => "Thesaurus",
      #   6 => "Validation List",
      #   7 => "URL",
      #   8 => "Complex Date",
      #   9 => "Decimal",
      #   10 => "Image",
      #   11 => "Rich Text",
      #   12 => "User"
      # }
      def parse_value(field_type, element)
        field_type = field_type.to_i
        case field_type
        when 1, 4, 5, 6, 11, 12 then element.text.to_s
        when 2 then element.text.to_i
        when 3 then Date.parse(element.text.to_s)
        # when 3 then element.text.to_s
        when 7 then 
        if element.attribute("desc").value.size > 0 && !element.attribute("desc").value.eql?(element.text.to_s)
          # "#{element.attribute("desc")} - #{ActionController::Base.helpers.auto_link(element.text.to_s)}"
          "#{element.attribute("desc")} - element.text.to_s)}"
        else
          # ActionController::Base.helpers.auto_link(element.text.to_s)
          element.text.to_s
        end
        when 8 then parse_complex_date(element)
        else field_type
        end
      end

      # attempts to make ruby Date or failsover to string from SOLO complex date field - PG 2011-04-08
      def parse_complex_date(element)
        d = element.text.split("-")
        date = []
        date << "%02d" % d[2] unless d[2].nil?
        date << "%02d" % d[1] unless d[1].nil?
        date << d[0] unless d[0].nil?
        circa = "circa " if element.attribute("circa").to_s == "1"
        nodate = "forthcoming " if element.attribute("nodate").to_s == "1"
        ongoing = "ongoing" if element.attribute("ongoing").to_s == "1"
        begin
          ret = Date.parse("#{date[0]}-#{date[1]}-#{date[2]}")
        rescue
          ret = "#{circa}#{nodate}#{date.join("-")} #{ongoing}".capitalize.strip
        end
        ret
      end

      # removes spaces from 'str' and then 'borrows' rails underscore method
      # converts strings like "Publication Date" into "publication_date"
      def uscore(str)
        word = str.gsub(/\s*/,"")
        word = word.to_s.dup
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end

  end

end

# Allows object.fieldname searches, returning nil rather than exception if key does not exist - PG 2011-01-20
class SoloHash < Hash  
  def method_missing(method, *params)  
    method = method.to_sym  
    return self[method] if self.keys.collect(&:to_sym).include?(method)   
    nil
  end  
end
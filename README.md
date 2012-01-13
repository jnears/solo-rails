SoloRails

This gem provides a Ruby wrapper for the Soutron Solo API.

It provides two methods, one to search the catalogue and one to fetch a specific record.

Search method

@records = Library.search  	:q => '',
                            :select => 'Title;Authors;Created Date',
                            :search_id => @records[:search_info].fetch(:id),
                            :ctrt => ct,
                            :sort => 'Created Date:d',
                            :material => ct[:content_type],
                            :per_page => 30,
                            :page => 0

Show

@record = Librar.search("1234556")
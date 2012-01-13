solo-rails
==========

*solo-rails provides a wrapper around the API for [Soutron Solo](http://www.soutron.com/soutronsolo.html)*

Methods
-------

The gem provides two methods `show` and `search`.

### show method

This takes a Solo CID parameter and returns the corresponding complete record e.g.

````{:id=>"491542", :request_url=>"http://library.iser.essex.ac.uk/Library/WebServices/SoutronApi.svc/getcatalogue?id=491542", :content_type=>"Monograph", :record_type=>"Report", :cid=>491542, :created_by=>"Soutron Administrator", :created_by_office=>"Colchester", :created_date=>Thu, 15 Jan 1998, :last_edited_by=>"Soutron Administrator", :last_edited_date=>Wed, 06 Oct 2010, :locations=>"Hilary Doughty Research Library", :offices=>"Colchester", :title=>"Absolute and overall poverty in Britain in 1997: what the population themselves say: Bristol Poverty Line Survey: report of the second MORI Survey", :authors=>["Townsend, Peter", "Gordon, David", "Bradshaw, Jonathan", "Gosschalk, Brian"], :isbn=>"086292457X", :publication_date=>"01-11-1997 ", :publisher=>"Bristol Statistical Monitoring Unit", :shelf_reference=>"316.344.233", :keywords=>["Social policy", "Poverty"], :subjects=>["HOUSEHOLDS", "INCOME DYNAMICS", "SOCIAL STRATIFICATION", "SOCIAL STRUCTURE", "WELFARE BENEFITS"], :record_type_detail=>"report", :id_textworks=>"155805", :place=>"Bristol"}````

### search method

This accepts parameters from the Solo API and returns the corresponding record set e.g.

````ruby
@records = Libary.search :q => 'Series:"ISER Working Paper Series"',         
                               :select => 'Title;Authors;Series Number;Series;Publication Date',
                               :sort => 'Publication Date:d',
                               :per_page => 30,
                               :search_id => params[:search_id],
                               :page => params[:page]
````

This method accepts the same arguments as the API provides, see the Soutron documentation for further detail.

Use in a Rails app
------------------

The simplest way to use the methods in a Rails app is to add the gem requirement to your Gemfile then create a class which extends from it e.g.

````ruby
# app/models/library.rb

class Library
  extend solo-rails
end
````

This will allow you to call the methods from controllers with

    Library.show("123456")

and the search method as above.
module Gpsoauth4r
  class Track < OpenStruct
    def initialize(skyjam, data)
      super(data)
      @skyjam = skyjam
    end
    
    def delete()
      puts "deleting #{title}"
    end
  end

  class SkyJam
    def initialize(auth)
      @auth = auth
      @base_url = 'https://mclients.googleapis.com/sj/v1.11/'
      @auth.login('sj')
    end
    def list_tracks()
      url = @base_url + 'trackfeed'
      result = @auth.post(url,
        :params => {
          'alt' => 'json',
          'updated-min' => 0,
          'include-tracks' => 'true'
        },
        :headers => {
          'Content-Type' => 'application/json'
        },
        :body => {"max-results"=> "20000"}.to_json)
      return JSON.parse(result.body)['data']['items'].select{|item|item['kind'] == 'sj#track'}.map{|i|Track.new(self, i)}
    end
  end
end


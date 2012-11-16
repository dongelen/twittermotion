module Twitter
  class User
    attr_accessor :ac_account

    def initialize(ac_account)
      self.ac_account = ac_account
    end

    def username
      self.ac_account.username
    end

    # user.compose(tweet: 'initial tweet', images: [ui_image, ui_image],
    #   urls: ["http://", ns_url, ...]) do |composer|
    #
    # end
    def compose(options = {}, &block)
      @composer = Twitter::Composer.new
      @composer.compose(options) do |composer|
        block.call(composer)
      end
    end

    # user.get_timeline(include_entities: 1) do |hash, ns_error|
    # end
    def get_timeline(options = {}, &block)
      url = NSURL.URLWithString("http://api.twitter.com/1/statuses/home_timeline.json")
      request = TWRequest.alloc.initWithURL(url, parameters:options, requestMethod:TWRequestMethodGET)
      request.account = self.ac_account
      request.performRequestWithHandler(lambda {|response_data, url_response, error|
        if !response_data
          block.call(nil, error)
        else
          block.call(BubbleWrap::JSON.parse(response_data), nil)
        end
      })
    end
    
    # user.stream(include_entities: 1) do |hash|
    # end   
    def statuses_filter(options = {}, &block)
      @stream_to_block = block
      url = NSURL.URLWithString("https://stream.twitter.com/1.1/statuses/filter.json")
      request = TWRequest.alloc.initWithURL(url, parameters:options, requestMethod:TWRequestMethodPOST)
      request.account = self.ac_account
      signedReq = request.signedURLRequest
      @twitterConnection = NSURLConnection.alloc.initWithRequest(signedReq, delegate:self, startImmediately: false) 
      @twitterConnection.scheduleInRunLoop(NSRunLoop.mainRunLoop, forMode:NSDefaultRunLoopMode)
      @twitterConnection.start                 
    end
      
    def connection(connection, didReceiveData:data)
      object = NSJSONSerialization.JSONObjectWithData data, options: NSJSONReadingMutableContainers, error: nil
      @stream_to_block.call(object) if object
    end
  end
end
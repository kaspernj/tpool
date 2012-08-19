class Tpool::Block
  attr_accessor :res
  
  #Constructor. Should not be called manually.
  def initialize(args)
    @args = args
    
    @running = false
    @done = false
    @error = nil
  end
  
  #Starts running whatever block it is holding.
  def run
    @running = true
    
    begin
      @res = @args[:blk].call(*@args[:args], &@args[:blk])
    rescue Exception => e
      @error = e
    end
    
    @running = false
    @done = true
    
    if @args[:thread_starts]
      @args[:thread_starts].each do |thread|
        thread.wakeup
      end
    end
    
    return self
  end
  
  #Returns true if the asynced job is done running.
  def done?
    return @done
  end
  
  #Returns true if the asynced job is still running.
  def running?
    return @running
  end
  
  #Returns true if the asynced job is still waiting to run.
  def waiting?
    return true if !@done and !@running and !@error
    return false
  end
  
  #Raises error if one has happened in the asynced job.
  def error!
    raise @error if @error
  end
  
  #Sleeps until the asynced job is done. If an error occurred in the job, that error will be raised when calling the method.
  def join
    if !@done
      @args[:thread_starts] << Thread.current
      
      begin
        Thread.stop
      rescue Exception
        sleep 0.1 while !@done
      end
    end
    
    return self
  end
  
  def result(args = nil)
    self.join if args and args[:wait]
    raise "Not done yet." unless self.done?
    self.error!
    return @res
  end
end
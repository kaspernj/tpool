require "thread"

class Tpool
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/tpool_#{name.to_s.downcase}.rb"
    raise "Still not defined: '#{name}'." if !Tpool.const_defined?(name)
    return Tpool.const_get(name)
  end
  
  #Returns the 'Tpool::Block' that is running in the given thread.
  def self.current_block(thread = Thread.current)
    return thread[:tpool][:block] if thread[:tpool].is_a?(Hash)
    raise "No block was found running in that thread."
  end
  
  def initialize(args)
    @args = args
    @queue = Queue.new
    self.start
  end
  
  def start
    raise "Already started." if @pool and !@pool.empty?
    
    @pool = Array.new(@args[:threads]) do |i|
      Thread.new do
        begin
          Thread.current[:tpool] = {:i => i}
          
          loop do
            block = @queue.pop
            Thread.current[:tpool][:block] = block
            
            block.run
            Thread.current[:tpool].delete(:block)
          end
        rescue Exception => e
          $stderr.puts e.inspect
          $stderr.puts e.backtrace
        end
      end
    end
  end
  
  #Kills all running threads.
  def stop
    @pool.delete_if do |thread|
      thread.kill
      true
    end
  end
  
  #Runs the given block in the thread-pool, joins it and returns the result.
  def run(*args, &blk)
    raise "No block was given." if !blk
    
    block = Tpool::Block.new(
      :args => args,
      :blk => blk,
      :thread_starts => [Thread.current]
    )
    @queue << block
    
    begin
      Thread.stop
    rescue Exception
      #Its not possible to stop main thread (dead-lock-error - sleep it instead).
      sleep 0.1 while !block.done?
    end
    
    return block.res
  end
  
  #Runs the given block in the thread-pool and returns a block-object to keep a look on the status.
  def run_async(*args, &blk)
    raise "No block was given." if !blk
    
    block = Tpool::Block.new(
      :tpool => self,
      :args => args,
      :blk => blk,
      :thread_starts => [Thread.current]
    )
    @queue << block
    
    return block
  end
  
  def on_error_call(*args)
    @on_error.call(*args) if @on_error
  end
  
  def on_error(&blk)
    @on_error = blk
  end
end
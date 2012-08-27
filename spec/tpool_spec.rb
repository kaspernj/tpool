require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Tpool" do
  it "should work" do
    errs = []
    
    tp = Tpool.new(
      :threads => 4,
      :priority => -3,
      :on_error => lambda{|data|
        errs << data[:error]
      }
    )
    
    res = tp.run do
      errs << "Expected thread priority to be -3 but it wasnt: '#{Thread.current.priority}'." if Thread.current.priority != -3
      "kasper"
    end
    
    raise errs.first if !errs.empty?
    raise "Expected result to be 'kasper' but it wasnt: '#{res}'." if res != "kasper"
    
    
    blk = tp.run_async do
      "kasper"
    end
    blk.join
    
    raise "Expected result to be 'kasper' but it wasnt: '#{res}'." if res != "kasper"
    
    
    
    blk = tp.run_async do
      sleep 5
      "kasper"
    end
    
    blk.kill
    
    error = false
    begin
      blk.error!
    rescue Exception
      error = true
    end
    
    raise "Expected error but didnt get one." if !error
    
    raise errs.first if !errs.empty?
  end
end

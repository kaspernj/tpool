require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Tpool" do
  it "should work" do
    tp = Tpool.new(:threads => 4)
    res = tp.run do
      "kasper"
    end
    
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
  end
end

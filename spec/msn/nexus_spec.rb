require 'spec_helper'

describe Nexus do
  it "computes return value" do
    nexus = Nexus.new "MBI_KEY", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    return_value = nexus.compute_return_value "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "#{0.chr * 8}"
    return_value.should eq("HAAAAAEAAAADZgAABIAAAAgAAAAUAAAASAAAAAAAAAAAAAAA7XgT5ohvaZdoXdrWUUcMF2G8OK2JohyYcK5l5MJSitab33scxJeK/RQXcUr0L+R2ZA9CEAzn0izmUzSMp2LZdxSbHtnuxCmptgtoScHp9E26HjQVkA9YJxgK/HM=")
  end

  it "computes return value 2" do
    nexus = Nexus.new "MBI_KEY", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
    return_value = nexus.compute_return_value "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=", "#{0.chr * 8}"
    return_value.should eq("HAAAAAEAAAADZgAABIAAAAgAAAAUAAAASAAAAAAAAAAAAAAAywfWRZVnRRZTqPkW6HBIrOmPuYiFbzcpvYmP2QzhpH+VdKwtqUTt/gdbDqlMZvR1o7ve9ex44otMOxYtnNYIQ+lfoj+PKcsHT+T7GA1hfMsTVbGqoYYe3B5/WW0=")
  end
end
require 'spec_helper'

describe Challenge do
  it "replies to challenge for MSNP11" do
    Challenge.challenge("22210219642164014968", "YMM8C_H7KCQ2S_KL", "PROD0090YUAUV{2B").should eq("85ecb0db8f32113df79ce0892b9a102c")
  end

  it "replies to challenge for MSNP15" do
    Challenge.challenge("11533365622852247127").should eq("f086d1ded067186deca8dba2231602cf")
  end
end

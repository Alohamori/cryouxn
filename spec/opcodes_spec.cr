require "./spec_helper"

describe Cryouxn do
  it "should pass opctest" do
    prog, expected = files_for "opctest"
    sout, serr = capture_output prog

    sout.should eq expected["out"]
    serr.should eq expected["err"]
  end

  it "should pass the other opcode test" do
    prog, expected = files_for "tests"
    sout, serr = capture_output prog

    sout.should eq expected["out"]
    serr.should eq expected["err"]
  end
end

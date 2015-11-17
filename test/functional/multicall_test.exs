defmodule ExRPC.Test.Functional.Multicall do
  use ExUnit.Case
  
  import ExRPC.Test.Helper

  setup_all do
    ExRPC.Test.Helper.start_slave_node()
    on_exit fn() ->
      ExRPC.Test.Helper.stop_slave_node()
    end
    :ok
  end

  test "Multicall on local node" do
    assert {_mega, _sec, _micro} = ExRPC.multicall(master, :os, :timestamp, [])
  end

  test "Multicall on local node mf" do
    assert ExRPC.Test.Helper.master = ExRPC.multicall(master, :erlang, :node)
  end

  test "Multicall on local node mfa" do
    assert [3,2,1] = ExRPC.multicall(master, :erlang, :apply, [Enum, :reverse, [[1, 2, 3]]])
  end

  test "Multicall on invalid node" do
    assert {:badrpc, :nodedown} = ExRPC.multicall(invalid, :os, :timestamp, [])
  end

  test "Multicall with valid eponymous function" do
    assert {_mega, _sec, _micro} = ExRPC.multicall(slave, :os, :timestamp, [], 1000)
  end

  test "Multicall with invalid eponymous function" do
    assert {:badrpc, {:'EXIT', {:undef, [{:os,:timestamp_undef, [], []}|_]}}} =
      ExRPC.multicall(slave, :os, :timestamp_undef, [])
  end

  test "Multicall with valid anonymous function" do
    assert {_,"call_anonymous_function"} =
      ExRPC.multicall(master, :erlang, :apply, [fn(a) -> {self(), a} end, ["call_anonymous_function"]])
  end

  test "Multicall with invalid anonymous function" do
    assert {:badrpc, {:'EXIT', {:undef, [{:erlang,:apply, _, _}|_]}}} =
      ExRPC.multicall(master, :erlang, :apply, [fn() -> :os.timestamp_undef() end])
  end

  test "Multicall with process exit" do
    assert {:badrpc, {:'EXIT', :die}} =
      ExRPC.multicall(master, :erlang, :apply, [fn() -> exit(:die) end, []])
  end

  test "Multicall local with process throw" do
    assert :throwMaster =
      ExRPC.multicall(master, :erlang, :apply, [fn() -> throw(:throwMaster) end, []])
  end

  test "Multicall with call timeout" do
    assert {:badrpc, :timeout} = ExRPC.multicall(slave, :timer, :sleep, [100], 1)
    # Wait for the remote process to die
    :timer.sleep(100)
  end

end

defmodule ExRPC.Test.Helper do

  require Logger

  defmacro master do :'exrpc@127.0.0.1' end
  defmacro slave do :'exrpc_slave@127.0.0.1' end
  defmacro slave1 do :'exrpc_slave1@127.0.0.1' end
  defmacro slave2 do :'exrpc_slave2@127.0.0.1' end
  defmacro slave_ip do :'127.0.0.1' end
  defmacro slave_name do :'exrpc_slave' end
  defmacro invalid do :'exrpc_invalid@127.0.0.1' end

  def start_master_node() do
    case Node.start(master, :longnames) do
      {:ok, _} ->
        {:ok, {master, :started}};
      {:error,{:already_started, _pid}} ->
        {:ok, {master, :already_started}};
      {:error, reason} ->
        Logger.error("function=start_master_node event=fail_start_master_node Reason=",[reason])
        {:error, reason}
    end
    {:ok, _master_apps} = Application.ensure_all_started(:exrpc)
  end

  def start_slave_node() do
    start_slave_node(slave_name, slave)
  end

  def start_slave_node(node_name, node_full_name) do
    cookie = :erlang.get_cookie |> Atom.to_char_list
    erl_flags = ' -kernel dist_auto_connect once +K true -setcookie ' ++ cookie
    {:ok, _slave} = 
    case :slave.start(slave_ip, node_name, erl_flags) do
        {:ok, value} -> {:ok, value}   
        {:error, reason} ->
           Logger.error("function=start_slave_node event=fail_start_slave_node Error=", [reason])
           {:error, reason} 
        unexpected ->
           Logger.error("function=start_slave_node event=unexpected_return_value Value=", [unexpected])
           unexpected 
    end
    :ok = :rpc.call(slave, :code, :add_pathsz, [:code.get_path()])
    {:ok, _slave_apps} = :rpc.call(node_full_name, Application, :ensure_all_started, [:exrpc])
  end

  def stop_slave_node() do
    :ok = :slave.stop(slave)
  end

  def stop_slave_node(node_name) do
    :ok = :slave.stop(node_name)
  end

end

Logger.configure(level: :debug)
Logger.configure_backend(:console, colors: [enabled: false])
Mix.shell(Mix.Shell.Process)
ExUnit.start()
ExUnit.configure(seed: 0, max_cases: 1)
ExRPC.Test.Helper.start_master_node()

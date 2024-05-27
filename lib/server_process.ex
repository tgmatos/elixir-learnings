defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
      end)
  end

  defp loop(callback_module, state) do
    receive do
      {:call, request, caller} ->
        {response, state} = callback_module.handle_call(request, state)
        send(caller, {:response, response})
        loop(callback_module, state)
      

      {:cast, request} ->
        state = callback_module.handle_cast(request, state)
        loop(callback_module, state)
    end
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} -> response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end
  
end
